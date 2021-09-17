module ThesisHelper
  # Handles UI situations where a thesis may not have a title but we need to
  # provide a link via its (undefined) title.
  def title_helper(thesis)
    return 'Untitled thesis' unless thesis.title.present?

    thesis.title
  end

  def filter_theses_by_term(theses, term)
    return theses.where('grad_date = ?', term) if term != 'all'

    theses
  end
end
