# == Schema Information
#
# Table name: authors
#
#  id                   :integer          not null, primary key
#  user_id              :integer          not null
#  thesis_id            :integer          not null
#  graduation_confirmed :boolean          default(FALSE), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
require 'csv'
require 'test_helper'

class AuthorTest < ActiveSupport::TestCase
  test 'can edit graduation confirmation' do
    a = authors(:one)
    assert(a.graduation_confirmed == false)
    a.graduation_confirmed = true
    a.save
    assert(a.valid?)
  end

  test 'sets graduation status to true if false in db and true in csv' do
    filepath = 'test/fixtures/files/registrar_data_user_existing.csv'
    row = CSV.readlines(File.open(filepath), headers: true).first
    author = authors(:one)
    refute author.graduation_confirmed
    author.set_graduated_from_csv(row)
    author.reload
    assert author.graduation_confirmed
  end

  test 'sets graduation status to false if true in db and false in csv' do
    filepath = 'test/fixtures/files/registrar_data_user_updated.csv'
    row = CSV.readlines(File.open(filepath), headers: true).first
    author = authors(:two)
    assert author.graduation_confirmed
    author.set_graduated_from_csv(row)
    refute author.graduation_confirmed
  end

  test 'leaves graduation status false if false in db and false in csv' do
    filepath = 'test/fixtures/files/registrar_data_user_updated.csv'
    row = CSV.readlines(File.open(filepath), headers: true).first
    author = authors(:one)
    refute author.graduation_confirmed
    author.set_graduated_from_csv(row)
    author.reload
    refute author.graduation_confirmed
  end

  test 'leaves graduation status true if true in db and true in csv' do
    filepath = 'test/fixtures/files/registrar_data_user_existing.csv'
    row = CSV.readlines(File.open(filepath), headers: true).first
    author = authors(:one)
    author.graduation_confirmed = true
    author.save
    author.set_graduated_from_csv(row)
    author.reload
    assert author.graduation_confirmed
  end
end
