# == Schema Information
#
# Table name: degree_types
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'test_helper'

class DegreeTypeTest < ActiveSupport::TestCase
  test 'invalid without name' do
    dt = degree_types(:bachelor)
    dt.name = nil
    assert_not dt.valid?
  end

  test 'name must be unique' do
    bachelor = degree_types(:bachelor)
    doctoral = degree_types(:doctoral)
    doctoral.name = bachelor.name
    assert_raises ActiveRecord::RecordNotUnique do
      doctoral.save
    end
  end
end
