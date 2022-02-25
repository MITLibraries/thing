module HoldHelper
  def render_hold_history_field(field_name, field_value)
    # Set nil values to something that will display onscreen
    field_value = 'n/a' if field_value.nil?

    # For foreign key fields, return a link to the record
    if field_name == 'thesis_id' && (thesis = Thesis.find_by(id: field_value))
      field_value = link_to thesis.title, admin_thesis_path(field_value)
    elsif field_name == 'hold_source_id' && (hold_source = HoldSource.find_by(id: field_value))
      field_value = link_to hold_source.source, admin_hold_source_path(field_value)
    end

    field_value
  end

  def filter_holds_by_term(holds)
    if params[:graduation] && params[:graduation] != 'all'
      return holds.where('theses.grad_date = ?', params[:graduation]).references(:thesis)
    end

    holds
  end

  def filter_holds_by_source(holds)
    if params[:hold_source] && params[:hold_source] != 'all'
      return holds.where('hold_sources.source = ?', params[:hold_source]).references(:thesis)
    end

    holds
  end
end
