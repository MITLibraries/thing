module ThesisHelper
  def highlight_class(status)
    if params[:status].nil? && status == 'active'
      'button-primary'
    elsif params[:status] == status
      'button-primary'
    else
      'button-secondary'
    end
  end
end
