# == Schema Information
#
# Table name: licenses
#
#  id                  :integer          not null, primary key
#  display_description :text             not null
#  license_type        :text             not null
#  url                 :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
require 'test_helper'

class LicenseTest < ActiveSupport::TestCase
  test 'valid license' do
    license = licenses(:nocc)
    assert(license.valid?)
  end

  test 'invalid without display_description' do
    license = licenses(:nocc)
    license.display_description = nil
    assert(license.invalid?)
  end

  test 'invalid without license_type' do
    license = licenses(:nocc)
    license.license_type = nil
    assert(license.invalid?)
  end

  test 'valid without url' do
    license = licenses(:nocc)
    license.url = nil
    assert(license.valid?)
  end

  test 'need not have any theses' do
    license = licenses(:ccbysa)
    license.theses = []
    assert(license.valid?)
  end

  test 'deleting a license will not delete its associated theses' do
    license = licenses(:sacrificial)
    thesis = theses(:two)
    thesis_count = Thesis.count
    license_count = License.count
    assert_equal thesis.license, license

    license.delete
    assert_equal license_count - 1, License.count
    assert_equal thesis_count, Thesis.count
  end
end
