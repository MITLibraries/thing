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

  test 'license types are mapped correctly' do
    # Maps license text for no Creative Commons licenses
    nocc = licenses(:nocc)
    assert_equal 'In Copyright - Educational Use Permitted', nocc.map_license_type

    # Does not map license text otherwise
    ccby = licenses(:ccby)
    assert_equal 'Attribution 4.0 International (CC BY 4.0)', ccby.map_license_type

    ccbysa = licenses(:ccbysa)
    assert_equal 'Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)', ccbysa.map_license_type
  end

  test 'license urls are mapped correctly' do
    # Maps license url for no Creative Commons licenses
    nocc = licenses(:nocc)
    assert_equal 'https://rightsstatements.org/page/InC-EDU/1.0/', nocc.evaluate_license_url

    # Returns regular license url otherwise
    ccby = licenses(:ccby)
    assert_equal 'https://creativecommons.org/licenses/by/4.0/', ccby.evaluate_license_url

    ccbysa = licenses(:ccbysa)
    assert_equal 'https://creativecommons.org/licenses/by-sa/4.0/', ccbysa.evaluate_license_url

    nourl = licenses(:sacrificial)
    assert_nil nourl.evaluate_license_url
  end
end
