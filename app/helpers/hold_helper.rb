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

    field_value = render_status(field_value) if field_name == 'status'

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

  # This patches a PaperTrail bug that saves enums to the version table as integers instead of their mapped values.
  # We never noticed this bug because it occurs only with YAML data, but PT is able to correctly parse enums when it
  # unserializes YAML data. This is not the case with JSON data, so historical statuses are stored as integers and
  # render as integers. Because PT no longer maps the enums, we do so here.
  def render_status(value)
    case value
    when 0
      'active'
    when 1
      'expired'
    when 2
      'released'
    else
      value
    end
  end
end
