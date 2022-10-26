module ThesisHelper
  # Handles UI situations where a thesis may not have a title but we need to
  # provide a link via its (undefined) title.
  def title_helper(thesis)
    return 'Untitled thesis' unless thesis.title.present?

    thesis.title
  end

  def filter_theses_by_term(theses)
    return theses.where('grad_date = ?', params[:graduation]) if params[:graduation] && params[:graduation] != 'all'

    theses
  end

  def filter_theses_by_publication_status(theses)
    return theses.where('publication_status = ?', params[:status]) if params[:status] && params[:status] != 'all'

    theses
  end

  def filter_theses_by_department(theses)
    if params[:department] && params[:department] != 'all'
      return theses.where('departments.name_dw = ?', params[:department]).references(:thesis)
    end

    theses
  end

  def filter_theses_by_degree_type(theses)
    if params[:degree_type] && params[:degree_type] != 'all'
      return theses.where(degree_type: { name: params[:degree_type] })
    end

    theses
  end

  def filter_theses_by_multiple_authors(theses)
    return theses.multiple_authors if params[:multi_author] && params[:multi_author] == 'true'

    theses
  end

  def filter_theses_by_published(theses)
    return theses.where(publication_status: 'Published') if params[:published_only] && params[:published_only] == 'true'

    theses
  end

  # Since the ProQuest status report has many filters, we apply them all here.
  def filter_proquest_status(theses)
    term_filtered = filter_theses_by_term theses
    dept_filtered = filter_theses_by_department term_filtered
    degree_filtered = filter_theses_by_degree_type dept_filtered
    multi_author_filtered = filter_theses_by_multiple_authors degree_filtered
    filter_theses_by_published multi_author_filtered
  end

  def satisfies_advanced_degree?(thesis)
    advanced_degree_types = %w[Doctoral Engineer Master]
    thesis.degrees.any? { |d| advanced_degree_types.include? d.degree_type.name }
  end

  # Determines if there is a conflict between authors' ProQuest opt-in.
  def evaluate_proquest_status(thesis)
    proquest_status = thesis.authors.map(&:proquest_allowed).uniq
    return 'conflict' if proquest_status.length > 1

    proquest_status.first
  end

  # Renders a friendly version of the thesis' ProQuest opt-in status for reports.
  def render_proquest_status(thesis)
    status = evaluate_proquest_status(thesis)
    return 'Opt-in status not reconciled' if status == 'conflict'
    return 'No opt-in status selected' if status.nil?
    return 'Yes' if status == true
    return 'No' if status == false
  end

  def proquest_status_counts(theses)
    result = { opted_in: 0, opted_out: 0, no_decision: 0, conflict: 0 }
    theses.map do |thesis|
      if evaluate_proquest_status(thesis) == true
        result[:opted_in] += 1
      elsif evaluate_proquest_status(thesis) == false
        result[:opted_out] += 1
      elsif evaluate_proquest_status(thesis).nil?
        result[:no_decision] += 1
      elsif evaluate_proquest_status(thesis) == 'conflict'
        result[:conflict] += 1
      end
    end
    result
  end
end
