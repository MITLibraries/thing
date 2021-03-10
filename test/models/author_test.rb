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
    a = Author.first
    assert(a.graduation_confirmed == false)
    a.graduation_confirmed = true
    a.save
    assert(a.valid?)
  end

  test 'updates graduation status from csv' do
    filepath = 'test/fixtures/files/registrar_data_user_existing.csv'
    row = CSV.readlines(open(filepath), headers: true).first
    author = authors(:one)
    assert_not author.graduation_confirmed
    author.set_graduated_from_csv(row)
    assert author.graduation_confirmed
  end

  test 'only updates graduation status if true' do
    filepath = 'test/fixtures/files/registrar_data_user_updated.csv'
    row = CSV.readlines(open(filepath), headers: true).first
    author = authors(:one)
    assert_not author.graduation_confirmed
    author.set_graduated_from_csv(row)
    assert_not author.graduation_confirmed
  end

  test 'reverts graduation confirmed to false if needed' do
    filepath = 'test/fixtures/files/registrar_data_user_updated.csv'
    row = CSV.readlines(open(filepath), headers: true).first
    author = authors(:two)
    assert author.graduation_confirmed
    author.set_graduated_from_csv(row)
    assert_not author.graduation_confirmed
  end
end
