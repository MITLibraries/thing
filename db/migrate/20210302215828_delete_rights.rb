require_relative '20170713123212_create_rights'
require_relative '20170713123352_add_rights_to_theses'

class DeleteRights < ActiveRecord::Migration[6.0]
  def change
  	revert AddRightsToTheses
  	revert CreateRights
  end
end
