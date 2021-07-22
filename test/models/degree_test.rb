# == Schema Information
#
# Table name: degrees
#
#  id             :integer          not null, primary key
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  code_dw        :string           not null
#  name_dw        :string
#  abbreviation   :string
#  name_dspace    :string
#  degree_type_id :integer
#

require 'test_helper'

class DegreeTest < ActiveSupport::TestCase
  test 'valid degree' do
    degree = degrees(:one)
    assert(degree.valid?)
  end

  test 'minimum valid degree' do
    degree = degrees(:one)
    degree.name_dspace = nil
    degree.name_dw = nil
    degree.abbreviation = nil
    degree.save
    assert degree.valid?
  end

  test 'invalid without Data Warehouse code' do
    degree = degrees(:one)
    degree.code_dw = nil
    assert(degree.invalid?)
  end

  test 'Data Warehouse code must be unique' do
    d1 = degrees(:one)
    d2 = degrees(:two)
    d2.code_dw = d1.code_dw
    assert_raises ActiveRecord::RecordNotUnique do
      d2.save
    end
  end

  test 'can have multiple theses' do
    degree = degrees(:one)
    degree.theses = [theses(:one), theses(:two)]
    assert(degree.valid?)
  end

  test 'need not have any theses' do
    degree = degrees(:one)
    degree.theses = []
    assert(degree.valid?)
  end

  test 'can have degree type' do
    degree = degrees(:one)
    degree.degree_type_id = degree_types(:bachelor).id
    assert degree.degree_type.name == 'Bachelor'
    assert degree.valid?
  end

  test 'valid without degree type' do
    degree = degrees(:one)
    degree.degree_type_id = nil
    assert degree.valid?
  end

  test 'finds existing degree from csv' do
    filepath = 'test/fixtures/files/registrar_data_thesis_existing.csv'
    row = CSV.readlines(open(filepath), headers: true).first
    degree = Degree.from_csv(row)
    assert_equal degrees(:one), degree
  end

  test 'creates degree from csv with all expected attributes' do
    filepath = 'test/fixtures/files/registrar_data_thesis_new.csv'
    row = CSV.readlines(open(filepath), headers: true).first
    assert_not(Degree.find_by(code_dw: 'UBWXYZ'))
    degree = Degree.from_csv(row)
    assert_equal 'UBWXYZ', degree.code_dw
    assert_equal 'Master of Weaving', degree.name_dw
    assert_equal 'UBW', degree.abbreviation
    assert_nil(degree.name_dspace)
    assert_nil(degree.degree_type)
  end
end
