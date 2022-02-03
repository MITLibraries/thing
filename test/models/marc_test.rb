require 'test_helper'

class MarcTest < ActiveSupport::TestCase

  test "creates a marc record" do
    thesis = theses(:published)
    marc = Marc.new(thesis)
    assert_equal(MARC::Record, marc.record.class)
  end

  test 'leader is per spec' do
    thesis = theses(:published)
    marc = Marc.new(thesis)
    assert_equal("00000nam a2200217Kc 4500", marc.record.leader)
  end

  test 'single author uses 100 field' do
    thesis = theses(:published)
    marc = Marc.new(thesis)
    assert_equal("Robot, Basic", marc.record['100']['a'])
    assert_nil(marc.record['700'])
  end

  test 'multiple authors uses 100 field for first and 700 for additional' do
    thesis = theses(:published)
    thesis.authors << authors(:review)
    marc = Marc.new(thesis)
    assert_equal("Robot, Basic", marc.record['100']['a'])
    assert_equal("Yobot, Yo", marc.record['700']['a'])
  end

  test 'control008 follows spec' do
    Timecop.freeze(Time.utc(2021, 12, 25, 12, 20, 0)) do

      thesis = theses(:published)
      marc = Marc.new(thesis)
      assert_equal("211225s2021    mau     om    000 0 eng d", marc.record['008'].value)

    end
  end

  test 'creates multiple 992 fields for advisors' do
    thesis = theses(:published)
    thesis.advisors << advisors(:first)
    thesis.advisors << advisors(:second)

    marc = Marc.new(thesis)

    assert(marc.record.fields('992').map(&:value).include?('Addy McAdvisor'))
    assert(marc.record.fields('992').map(&:value).include?('Viola McAdvisor'))
  end
end
