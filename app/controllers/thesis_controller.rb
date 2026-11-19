# Coordinates thesis submission by authors and processing/publication by library staff.
#
# Main workflow components:
# - Author submission: start routes to new/edit. Create builds a minimum record and delegates
#   to update, which saves submission details and queues a receipt email.
# - Staff processing: select lists unpublished theses with files. Process_thesis loads the
#   editing form. Process_thesis_update saves metadata and related-hold exceptions together.
#   Attachment removal resets file approval and refreshes originating transfer counts.
#   Related theses sharing any author with active or expired holds block publication unless staff
#   explicitly confirm they represent distinct works.
# - Staff review: publication_statuses filters records by term/status. Deduplicate lists
#   records with coauthor metadata for manual review, rather than merging records itself.
# - DSpace publication: publish_preview and publish_to_dspace share publication_candidates,
#   rechecking holds on review-status records for the selected term before queuing preparation.
# - ProQuest export: proquest_export_preview shows model-selected candidates. Proquest_export
#   queues separate partial/full harvest batches. Publication errors can also be reset here. We
#   no longer export to ProQuest, but we may again in the future.
#
# Responsibility boundaries:
# - Authentication and CanCan abilities determine which actions and records a user may access.
# - Thesis owns readiness/status calculations; RelatedHoldException owns exception validation.
#   This controller coordinates saves and keeps exception parameters out of author updates.
# - Private helpers prepare filters, parameters, attachment cleanup and queue feedback.
#   Publication/export jobs perform background work; queuing is not confirmation of completion.
class ThesisController < ApplicationController
  before_action :require_user
  before_action :authenticate_user!
  load_and_authorize_resource except: :create
  protect_from_forgery with: :exception

  include ThesisHelper

  def new
    @thesis = Thesis.new
    @thesis.association(:advisors).add_to_target(Advisor.new)
    @thesis.users = [current_user]
  end

  def create
    # First, build a minimum viable thesis from the provided parameters.
    @thesis = Thesis.new
    @thesis.users = [current_user]
    @thesis.department_ids = thesis_params[:department_ids]
    @thesis.degree_ids = thesis_params[:degree_ids]
    @thesis.graduation_year = thesis_params[:graduation_year]
    @thesis.graduation_month = thesis_params[:graduation_month]
    @thesis.combine_graduation_date

    # Save this minimum viable thesis
    if @thesis.save
      params[:id] = @thesis.id

      # Add author ID to params if proquest_allowed was updated.
      link_author_id

      # Send the rest to update.
      update
    else
      render 'new'
    end
  end

  def deduplicate
    # Get array of defined terms where theses have coauthors
    @terms = defined_terms Thesis.where.not('coauthors = ?', '')

    # Filter relevant theses by selected term from querystring
    @thesis = filter_theses_by_term Thesis.where.not('coauthors = ?', '').includes(%i[departments users])
  end

  def publication_statuses
    @terms = defined_terms Thesis.all
    @publication_statuses = Thesis.all.pluck(:publication_status).uniq.sort

    # Filter relevant theses by selected term from querystring
    term_filtered = filter_theses_by_term Thesis.all.includes(:degrees, :departments,
                                                              :users).includes(degrees: :degree_type)
    @thesis = filter_theses_by_publication_status term_filtered
  end

  def edit
    @thesis = Thesis.includes([{ degrees: :degree_type }]).find(params[:id])
    @thesis.association(:advisors).add_to_target(Advisor.new) if @thesis.advisors.count.zero?
  end

  def publish_preview
    # Get array of defined terms where theses have coauthors
    @terms = defined_terms Thesis.in_review
    @thesis = publication_candidates
  end

  def publish_to_dspace
    if params[:graduation] == 'all' || params[:graduation].nil?
      flash[:warning] = 'Please select a term before attempting to publish theses to DSpace@MIT.'
    else
      # Queue publication preparation asynchronously
      queue_publication(publication_candidates)
    end
    redirect_to thesis_select_path(params: { graduation: params[:graduation] })
  end

  def select
    # Get array of defined terms where unpublished theses have files attached
    @terms = defined_terms Thesis.joins(:files_attachments).group(:id).where('publication_status != ?', 'Published')

    # Filter relevant theses by selected term from querystring
    @thesis = filter_theses_by_term Thesis.joins(:files_attachments).includes(%i[departments users]).group(:id).where(
      'publication_status != ?', 'Published'
    )
  end

  def show
    @thesis = Thesis.find(params[:id])
  end

  def start
    editable_theses = current_user.editable_theses
    case editable_theses.count
    when 0
      redirect_to new_thesis_path
    when 1
      redirect_to edit_thesis_path(editable_theses.first.id)
    end
  end

  def update
    @thesis = Thesis.includes([{ authors: :user }]).find(params[:id])
    if @thesis.update(thesis_params)
      flash[:success] = "#{@thesis.title} has been updated."
      ReceiptMailer.receipt_email(@thesis, current_user).deliver_later
    else
      flash[:error] = "#{@thesis.title} was unable to be edited."
    end
    redirect_to thesis_confirm_path
  end

  # Loads the processing form with currently held related theses and saved exceptions.
  # Previously waived records remain visible after their holds are released so processors can revoke
  # the exceptions.
  # The combined list is deduplicated because a reviewed related thesis may still have holds.
  def process_thesis
    @thesis = Thesis.with_attached_files.includes([:departments, {
                                                    authors: [:user], degrees: [:degree_type]
                                                  }]).find(params[:id])
    @other_theses_with_holds = @thesis.other_theses_with_holds.to_a
    @reviewed_related_thesis_ids = @thesis.related_hold_exceptions.pluck(:related_thesis_id)
    @related_theses_for_review = (@other_theses_with_holds + Thesis.where(id: @reviewed_related_thesis_ids)).uniq
  end

  # Saves metadata and explicit related-hold decisions together through the model's transaction,
  # which recalculates readiness using the updated exceptions.
  # Retries once if an attachment marked for removal disappears during the update.
  def process_thesis_update
    thesis = Thesis.find(params[:id])

    # A file may be deleted after the form loads. Drop stale delete rows before update.
    drop_stale_deleted_attachment_rows!

    removed = deleted_file_list
    params[:thesis][:files_complete] = false if removed.count.positive?
    updated = false
    retried_for_missing_attachment = false

    begin
      updated = thesis.update_with_related_hold_reviews(thesis_params, related_hold_review_params)
    rescue ActiveRecord::RecordNotFound => e
      raise unless missing_deleted_attachment_race?(e) && !retried_for_missing_attachment

      retried_for_missing_attachment = true
      drop_stale_deleted_attachment_rows!
      retry
    end

    if updated
      flash[:success] = "<p>Your changes to '#{thesis.title}' have been saved.</p>".html_safe
      if removed.count.positive?
        flash[:success] += '<p>The following files were removed from this thesis. They can still be found attached to their original transfer, via the following links:</p><ul>'.html_safe
        removed.each do |r|
          flash[:success] += "<li><a href='/transfer/#{r['transfer_id']}'>#{r['filename']}</a></li>".html_safe

          # update the original transfer so unassigned_files_count will be accurate
          Transfer.find(r['transfer_id']).save
        end
        flash[:success] += '</ul>'.html_safe
      end
    else
      flash[:error] = "An error has occurred while saving your changes to '#{thesis.title}'."
    end
    redirect_to thesis_process_path
  end

  def proquest_export_preview
    @theses = Thesis.includes([{ authors: :user }]).ready_for_proquest_export
  end

  # TODO: we need to generate and send a budget report CSV for partially harvested theses (spec TBD).
  def proquest_export
    if Thesis.ready_for_proquest_export.any?
      ProquestExportJob.perform_later(Thesis.partial_proquest_export.to_a, Thesis.full_proquest_export.to_a)
      flash[:success] = 'The theses you selected will be exported. ' \
                        'Status updates are not immediate.'
    else
      flash[:warning] = 'No theses are available to export.'
    end
    redirect_to thesis_proquest_export_preview_path
  end

  def reset_all_publication_errors
    Thesis.where(publication_status: 'Publication error').update(publication_status: 'Not ready for publication')

    flash[:success] = 'Publication error statuses have been reset'

    redirect_to thesis_select_path
  end

  private

  # Various methods need to build an array of academic terms which meet varying conditions, in order to support a UI
  # with a filtering mechanism. How they assemble the relevant terms is up to them, but this method will extract term
  # values and return a sorted array from those records.
  def defined_terms(records)
    records.pluck(:grad_date).uniq.sort
  end

  # Collects filenames and originating transfer IDs before attachments are removed, for success links and count refreshes.
  # Skips attachments already deleted since the form was loaded.
  def deleted_file_list
    list = []
    return list unless thesis_params['files_attachments_attributes']

    Rails.logger.debug('TRANSFER_COUNTS: Files count changed on thesis, expect updated Transfer count logs')
    thesis_params['files_attachments_attributes'].values.select { |item| item['_destroy'] == '1' }.each do |file|
      attachment = ActiveStorage::Attachment.find_by(id: file['id'])
      next unless attachment

      needle = attachment.blob
      list.append({
                    'filename' => needle.filename,
                    'transfer_id' => needle.attachments.select { |att| att.record_type == 'Transfer' }.first.record_id
                  })
    end
    list
  end

  # Removes submitted deletion rows for attachments that no longer exist, mutating the request
  # parameters.
  # Runs before the update and again on retry to avoid failing nested attachment assignment on stale
  # IDs.
  def drop_stale_deleted_attachment_rows!
    return unless params[:thesis]&.[](:files_attachments_attributes)

    params[:thesis][:files_attachments_attributes].delete_if do |_k, attrs|
      marked_for_delete = attrs['_destroy'] == '1'
      attachment_id = attrs['id']
      missing_attachment = attachment_id.present? && !ActiveStorage::Attachment.exists?(attachment_id)

      marked_for_delete && missing_attachment
    end
  end

  # Limits the retry to missing attachment errors when attachment rows were submitted.
  # Other missing records must still raise rather than being hidden by the retry.
  def missing_deleted_attachment_race?(error)
    params[:thesis]&.[](:files_attachments_attributes).present? &&
      error.message.include?('ActiveStorage::Attachment')
  end

  # Returns selected-term review records after rechecking direct and unwaived related holds.
  # Stored review status can be stale after related records change; both preview and submission use
  # this check.
  def publication_candidates
    filter_theses_by_term(Thesis.in_review.without_publication_holds).to_a
  end

  # Extracts processing-only decisions keyed by related thesis ID: '1' grants an exception and '0'
  # revokes it.
  # The model validates IDs and values. Missing rows leave existing exceptions unchanged.
  # Kept separate from shared thesis_params so ordinary author updates cannot grant or revoke
  # exceptions.
  def related_hold_review_params
    params.require(:thesis).permit(related_hold_reviews: {})[:related_hold_reviews].to_h
  end

  # Enqueues the eligible batch for preparation and reports its actual size, not the earlier preview count.
  # An empty batch produces a warning without enqueuing a job.
  def queue_publication(theses)
    if theses.empty?
      flash[:warning] = 'No theses are eligible for publication in the selected term.'
      return
    end

    DspacePublicationPrepJob.perform_later(theses)
    count = view_context.pluralize(theses.count, 'thesis', 'theses')
    flash[:success] = "#{count} added to the publication queue. Status updates are not immediate."
  end

  # Shared by author submissions and processor updates. Related-hold decisions must stay in the
  # processing-only filter.
  def thesis_params
    params.require(:thesis).permit(:title, :abstract, :coauthors, :graduation_month,
                                   :graduation_year, :copyright_id, :author_note,
                                   :license_id, :department_ids, :degree_ids,
                                   :processor_note, :files_complete, :metadata_complete,
                                   :issues_found,
                                   advisors_attributes: %i[id name _destroy],
                                   department_theses_attributes: %i[id thesis_id department_id _destroy],
                                   files_attachments_attributes: %i[id purpose description _destroy],
                                   users_attributes: %i[id orcid preferred_name],
                                   authors_attributes: %i[id proquest_allowed])
  end

  def sorted_theses(queryset, sort)
    if sort == 'name'
      queryset.name_asc
    else
      queryset.date_asc
    end
  end

  # This method is needed to update the proquest_allowed field for new theses.
  # The proquest_allowed field is validated in the form but not required in the data model, so the conditional
  # is needed for theses that are created outside the form and don't touch proquest_allowed.
  def link_author_id
    return unless params[:thesis][:authors_attributes]

    author = Author.find_by(thesis_id: @thesis.id, user_id: current_user.id)
    params[:thesis][:authors_attributes]['0'][:id] = author.id
  end
end
