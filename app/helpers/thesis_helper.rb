module ThesisHelper
  def highlight_status(status)
    if params[:status].nil? && status == 'active'
      'button-primary'
    elsif params[:status] == status
      'button-primary'
    else
      'button-secondary'
    end
  end

  def highlight_sort(sort)
    if params[:sort].nil? && sort == 'date'
      'button-primary'
    elsif params[:sort] == sort
      'button-primary'
    else
      'button-secondary'
    end
  end

  # The view and sort filters need to update the query parameters
  # independently. We could do this in the view but it would be ugly.
  def magic_status_url(status)
    process_path(params.permit(:status, :sort).merge({status: status}))
  end

  def magic_sort_url(sort)
    process_path(params.permit(:status, :sort).merge({sort: sort}))
  end
end
