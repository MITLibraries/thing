module HoldHelper
  def modified_by(version)
    if user = User.find_by(id: version.whodunnit)
      link_to user.kerberos_id, admin_user_path(user.id)
    else
      "User ID #{version.whodunnit} no longer active."
    end
  end

  def render_hold_history_field(field_name, field_value)
    # Set nil values to something that will display onscreen
    field_value = "n/a" if field_value.nil? 

    # For foreign key fields, return a link to the record
    if field_name == 'thesis_id' && thesis = Thesis.find_by(id: field_value)
      field_value = link_to thesis.title, admin_thesis_path(field_value)
    elsif field_name == 'hold_source_id' && hold_source = HoldSource.find_by(id: field_value)
      field_value = link_to hold_source.source, admin_hold_source_path(field_value)
    end
    
    field_value
  end
end
