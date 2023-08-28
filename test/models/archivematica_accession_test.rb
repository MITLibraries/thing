# == Schema Information
#
# Table name: archivematica_accessions
#
#  id               :integer          not null, primary key
#  accession_number :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  degree_period_id :integer          not null
#
require "test_helper"

class ArchivematicaAccessionTest < ActiveSupport::TestCase
  test 'invalid without a degree period' do
    a = ArchivematicaAccession.new
    a.accession_number = '2030_001'
    assert_not a.valid?

    a.degree_period = degree_periods(:no_archivematica_accessions)
    assert a.valid?
  end

  test 'invalid without an accession number' do
    a = archivematica_accessions(:valid_number_and_degree_period)
    assert a.valid?

    a.accession_number = nil
    assert_nil a.accession_number
    assert_not a.valid?
  end

  test 'accession numbers in the expected format are valid' do
    a = archivematica_accessions(:valid_number_and_degree_period)
    assert a.valid?

    # basic format
    a.accession_number = '2016_001'
    assert a.valid?

    # year can be as early as 1900
    a.accession_number = '1900_002'
    assert a.valid?

    # year can be as late as 2099
    a.accession_number = '2099_003'
    assert a.valid?

    # years in between are okay, too
    a.accession_number = '2023_004'
    assert a.valid?

    a.accession_number = '1997_005'
    assert a.valid?

    # sequence number can go up to 999
    a.accession_number = '2016_999'
    assert a.valid?
  end

  test 'accession numbers from especially weird years are invalid' do
    a = archivematica_accessions(:valid_number_and_degree_period)
    assert a.valid?
    
    # years before 2000 are invalid
    a.accession_number = '1897_001'
    assert_not a.valid?

    a.accession_number = '800_001'
    assert_not a.valid?

    # years after 2099 are invalid
    a.accession_number = '2100_001'
    assert_not a.valid?

    a.accession_number = '3000_001'
    assert_not a.valid?

    a.accession_number = '10000_001'
    assert_not a.valid?
  end

  test 'accession numbers must end in a three-digit sequence number' do
    a = archivematica_accessions(:valid_number_and_degree_period)
    assert a.accession_number.end_with? '001'
    assert a.valid?

    a.accession_number = '2019_0001'
    assert_not a.valid?

    a.accession_number = '2019_01'
    assert_not a.valid?

    a.accession_number = '2019_1'
    assert_not a.valid?

    a.accession_number = '2019_00000000000001'
    assert_not a.valid?
  end

  test 'the year of an accession number must be followed by an underscore' do
    a = archivematica_accessions(:valid_number_and_degree_period)
    assert_equal '2023_001', a.accession_number
    assert a.valid?

    a.accession_number = '2023-001'
    assert_not a.valid?
  end

  test 'preceding or trailing characters in an accession number are invalid' do
    a = archivematica_accessions(:valid_number_and_degree_period)
    assert_equal '2023_001', a.accession_number
    assert a.valid?

    a.accession_number = '2023_001a'
    assert_not a.valid?

    a.accession_number = 'a2023_001'
    assert_not a.valid?
  end

  test 'accession numbers must be unique' do
    original = archivematica_accessions(:valid_number_and_degree_period)
    degree_period = degree_periods(:no_archivematica_accessions)
    duplicate = ArchivematicaAccession.new(accession_number: original.accession_number,
                              degree_period_id: degree_period.id)
    assert_raises ActiveRecord::RecordInvalid do
      duplicate.save!
    end

    duplicate.accession_number = '2099_001'
    assert_not_equal duplicate.accession_number, original.accession_number
    assert_nothing_raised do
      duplicate.save!
    end
  end

  test 'multiple archivematica accessions cannot belong to the same degree period' do
    d = degree_periods(:june_2023)
    assert d.archivematica_accession.present?
    assert_raises ActiveRecord::RecordInvalid do
      d.create_archivematica_accession!(accession_number: '2024_001')
    end
  end

  test 'an archivematica accession cannot belong to multiple degree periods' do
    a = archivematica_accessions(:valid_number_and_degree_period)
    degree_period_one = a.degree_period
    degree_period_two = degree_periods(:no_archivematica_accessions)

    a.degree_period = degree_period_two
    a.save
    assert a.degree_period == degree_period_two
    assert_not a.degree_period == degree_period_one
  end

  test 'editing an archivematica accession generates a version' do
    a = archivematica_accessions(:valid_number_and_degree_period)
    versions_count = a.versions.count
    
    a.accession_number = '2030_001'
    a.save
    assert_equal versions_count + 1, a.versions.count
  end
end
