# == Schema Information
#
# Table name: copyrights
#
#  id                  :integer          not null, primary key
#  holder              :text             not null
#  display_to_author   :boolean          not null
#  display_description :text             not null
#  statement_dspace    :text             not null
#  url                 :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
require 'test_helper'

class CopyrightTest < ActiveSupport::TestCase
  test 'valid copyright' do
    copyright = copyrights(:mit)
    assert(copyright.valid?)
  end

  test 'invalid without holder' do
    copyright = copyrights(:mit)
    copyright.holder = nil
    assert(copyright.invalid?)
  end

  test 'invalid without display_to_author' do
    copyright = copyrights(:mit)
    copyright.display_to_author = nil
    assert(copyright.invalid?)
  end

  test 'invalid without display_description' do
    copyright = copyrights(:mit)
    copyright.display_description = nil
    assert(copyright.invalid?)
  end

  test 'invalid without statement_dspace' do
    copyright = copyrights(:mit)
    copyright.statement_dspace = nil
    assert(copyright.invalid?)
  end

  test 'valid without url' do
    copyright = copyrights(:mit)
    copyright.url = nil
    assert(copyright.valid?)
  end

  test 'need not have any theses' do
    copyright = copyrights(:govt)
    copyright.theses = []
    assert(copyright.valid?)
  end

  test 'deleting a copyright will not delete its associated theses' do
    copyright = copyrights(:sacrificial)
    thesis = theses(:two)
    thesis_count = Thesis.count
    copyright_count = Copyright.count
    assert_equal thesis.copyright, copyright

    copyright.delete
    assert_equal copyright_count - 1, Copyright.count
    assert_equal thesis_count, Thesis.count
  end
end
