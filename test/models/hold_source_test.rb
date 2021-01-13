# == Schema Information
#
# Table name: hold_sources
#
#  id         :integer          not null, primary key
#  source     :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'test_helper'

class HoldSourceTest < ActiveSupport::TestCase
  test 'valid hold source' do
    holdsource = hold_sources(:tlo)
    assert(holdsource.valid?)
  end

  test 'source is required' do
    holdsource = hold_sources(:tlo)
    holdsource.source = nil
    assert(holdsource.invalid?)
  end
end
