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

  def options_for_year_range
    options = [['', '']]
    (earliest_year..latest_year).each do |year|
      options.push([year, year])
    end
    options
  end

  def earliest_year
    queryset = Thesis.by_status(params[:status])
    if queryset.present?
      queryset.order('grad_date').first.grad_date.year
    else
      Thesis.all.order('grad_date').first.grad_date.year
    end
  end

  def latest_year
    queryset = Thesis.by_status(params[:status])
    if queryset.present?
      queryset.order('grad_date').last.grad_date.year
    else
      Thesis.all.order('grad_date').last.grad_date.year
    end
  end

  def show_form
    if @theses.present?
      true
    elsif [params[:start_year].present?,
           params[:start_month].present?,
           params[:end_year].present?,
           params[:end_month].present?].any?
      true
    else
      false
    end
  end

  # Returns a data series with all applicable dates for the X axis, but 0
  # values for everything on the Y axis. See comment in _inner_stats.html.erb.
  def graph_base
    @theses.
      group_by_month(:grad_date, format: "%b %Y", series: false).
      count.
      transform_values { |v| 0 }
  end

  def group_for_graph(status)
    @theses.
      by_status(status).
      group_by_month(:grad_date, format: "%b %Y", series: false).
      count
  end
end
