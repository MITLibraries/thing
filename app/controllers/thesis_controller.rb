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
      # Now that we've saved something, the rest is handled via update.
      params[:id] = @thesis.id
      update
    else
      render 'new'
    end
  end

  def deduplicate
    # Get array of defined terms where theses have coauthors
    @terms = defined_terms Thesis.where.not('coauthors = ?', '')
    # Filter relevant theses by selected term from querystring
    @thesis = filter_theses_by_term Thesis.where.not('coauthors = ?', '')
  end

  def publication_statuses
    @terms = defined_terms Thesis.all
    @publication_statuses = Thesis.all.pluck(:publication_status).uniq.sort
    # Filter relevant theses by selected term from querystring
    term_filtered = filter_theses_by_term Thesis.all.includes(:degrees, :departments, :users)
    @thesis = filter_theses_by_publication_status term_filtered
  end

  def edit
    @thesis = Thesis.find(params[:id])
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
      theses = publication_candidates
      DspacePublicationPrepJob.perform_later(theses)

      flash[:success] = 'The theses you selected have been added to the publication queue. ' \
                        'Status updates are not immediate.'
    end
    redirect_to thesis_select_path(params: { graduation: params[:graduation] })
  end

  def select
    # Get array of defined terms where unpublished theses have files attached
    @terms = defined_terms Thesis.joins(:files_attachments).group(:id).where('publication_status != ?', 'Published')
    # Filter relevant theses by selected term from querystring
    @thesis = filter_theses_by_term Thesis.joins(:files_attachments).group(:id).where('publication_status != ?',
                                                                                      'Published')
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
    @thesis = Thesis.find(params[:id])
    if @thesis.update(thesis_params)
      flash[:success] = "#{@thesis.title} has been updated."
      ReceiptMailer.receipt_email(@thesis, current_user).deliver_later
    else
      flash[:error] = "#{@thesis.title} was unable to be edited."
    end
    redirect_to thesis_confirm_path
  end

  def process_theses
    @thesis = Thesis.find(params[:id])
  end

  def process_theses_update
    thesis = Thesis.find(params[:id])
    removed = deleted_file_list
    params[:thesis][:files_complete] = false if removed.count.positive?
    if thesis.update(thesis_params)
      flash[:success] = "<p>Your changes to '#{thesis.title}' have been saved.</p>".html_safe
      if removed.count.positive?
        flash[:success] += '<p>The following files were removed from this thesis. They can still be found attached to their original transfer, via the following links:</p><ul>'.html_safe
        removed.each do |r|
          flash[:success] += "<li><a href='/transfer/#{r['transfer_id']}'>#{r['filename']}</a></li>".html_safe
        end
        flash[:success] += '</ul>'.html_safe
      end
    else
      flash[:error] = "An error has occurred while saving your changes to '#{thesis.title}'."
    end
    redirect_to thesis_process_path
  end

  private

  # Various methods need to build an array of academic terms which meet varying conditions, in order to support a UI
  # with a filtering mechanism. How they assemble the relevant terms is up to them, but this method will extract term
  # values and return a sorted array from those records.
  def defined_terms(records)
    records.pluck(:grad_date).uniq.sort
  end

  def deleted_file_list
    list = []
    return list unless thesis_params['files_attachments_attributes']

    thesis_params['files_attachments_attributes'].values.select { |item| item['_destroy'] == '1' }.each do |file|
      needle = ActiveStorage::Attachment.find_by(id: file['id']).blob
      list.append({
                    'filename' => needle.filename,
                    'transfer_id' => needle.attachments.select { |att| att.record_type == 'Transfer' }.first.record_id
                  })
    end
    list
  end

  def publication_candidates
    filter_theses_by_term(Thesis.in_review).to_a
  end

  def require_user
    return if current_user

    # Do NOT use ENV['FAKE_AUTH_ENABLED'] directly! Use the config. It performs
    # an additional check to make sure we are not on the production server.
    if Rails.configuration.fake_auth_enabled
      redirect_to user_developer_omniauth_authorize_path
    else
      redirect_to user_saml_omniauth_authorize_path
    end
  end

  def thesis_params
    params.require(:thesis).permit(:title, :abstract, :coauthors, :graduation_month,
                                   :graduation_year, :copyright_id, :author_note,
                                   :license_id, :department_ids, :degree_ids,
                                   :processor_note, :files_complete, :metadata_complete,
                                   :issues_found,
                                   advisors_attributes: %i[id name _destroy],
                                   department_theses_attributes: %i[id thesis_id department_id _destroy],
                                   files_attachments_attributes: %i[id purpose description _destroy],
                                   users_attributes: %i[id orcid preferred_name])
  end

  def sorted_theses(queryset, sort)
    if sort == 'name'
      queryset.name_asc
    else
      queryset.date_asc
    end
  end
end
