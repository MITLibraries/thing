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
end
