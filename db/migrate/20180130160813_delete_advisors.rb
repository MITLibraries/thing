require_relative '20170713123735_create_advisors'
require_relative '20170713123901_add_advisors_to_theses'

class DeleteAdvisors < ActiveRecord::Migration[5.1]
  def change
    revert AddAdvisorsToTheses
    revert CreateAdvisors
  end
end
