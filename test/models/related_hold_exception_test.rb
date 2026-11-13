require 'test_helper'

# == Schema Information
#
# Table name: related_hold_exceptions
#
#  id                :integer          not null, primary key
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  related_thesis_id :integer          not null
#  thesis_id         :integer          not null
#
# Indexes
#
#  index_related_hold_exceptions_on_pair               (thesis_id,related_thesis_id) UNIQUE
#  index_related_hold_exceptions_on_related_thesis_id  (related_thesis_id)
#
# Foreign Keys
#
#  related_thesis_id  (related_thesis_id => theses.id)
#  thesis_id          (thesis_id => theses.id)
#
class RelatedHoldExceptionTest < ActiveSupport::TestCase
  test 'a reviewed related thesis no longer blocks readiness but remains in the factual query' do
    thesis = theses(:one)
    related_thesis = theses(:with_hold)

    assert_not thesis.no_other_theses_with_holds?
    thesis.related_hold_exceptions.create!(related_thesis: related_thesis)

    assert thesis.no_other_theses_with_holds?
    assert_includes thesis.other_theses_with_holds, related_thesis
  end

  test 'an exception cannot refer to its own thesis' do
    exception = RelatedHoldException.new(thesis: theses(:one), related_thesis: theses(:one))

    assert_not exception.valid?
    assert_includes exception.errors[:related_thesis], 'must be a different thesis'
  end

  test 'a directional pair cannot be duplicated' do
    RelatedHoldException.create!(thesis: theses(:one), related_thesis: theses(:with_hold))
    duplicate = RelatedHoldException.new(thesis: theses(:one), related_thesis: theses(:with_hold))

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:related_thesis_id], 'has already been taken'
  end

  test 'an exception does not create the reverse exception or waive direct holds' do
    thesis = theses(:with_hold)
    thesis.related_hold_exceptions.create!(related_thesis: theses(:one))

    assert_empty theses(:one).related_hold_exceptions
    assert_not thesis.no_active_holds?
    assert_not thesis.evaluate_status
  end

  test 'a newly discovered held thesis still blocks after another thesis was reviewed' do
    thesis = theses(:one)
    thesis.related_hold_exceptions.create!(related_thesis: theses(:with_hold))
    assert thesis.no_other_theses_with_holds?

    Author.create!(user: users(:yo), thesis: theses(:downloaded), graduation_confirmed: true)

    assert_not thesis.no_other_theses_with_holds?
    assert_equal [theses(:downloaded).id], thesis.blocking_other_theses_with_holds.ids
  end

  test 'processing reviews persist and can be revoked without requiring a note' do
    thesis = theses(:one)
    related_id = theses(:with_hold).id.to_s

    assert thesis.update_with_related_hold_reviews({ processor_note: '' }, related_id => '1')
    assert thesis.reload.no_other_theses_with_holds?
    assert thesis.update_with_related_hold_reviews({}, related_id => '0')
    assert_not thesis.reload.no_other_theses_with_holds?
  end

  test 'omitted review rows remain unchanged' do
    thesis = theses(:one)
    exception = thesis.related_hold_exceptions.create!(related_thesis: theses(:with_hold))

    assert thesis.update_with_related_hold_reviews({}, {})
    assert RelatedHoldException.exists?(exception.id)
  end

  test 'a stale unchecked review saves metadata after the related holds are released' do
    thesis = theses(:one)
    related_thesis = theses(:with_hold)
    assert_includes thesis.other_theses_with_holds, related_thesis
    related_thesis.holds.each { |hold| hold.update!(status: :released) }

    assert_no_difference 'RelatedHoldException.count' do
      assert thesis.update_with_related_hold_reviews(
        { title: 'Updated after release' }, related_thesis.id.to_s => '0'
      )
    end

    assert_equal 'Updated after release', thesis.reload.title
  end

  test 'a stale unchecked review saves metadata after the related holds are deleted' do
    thesis = theses(:one)
    related_thesis = theses(:with_hold)
    assert_includes thesis.other_theses_with_holds, related_thesis
    related_thesis.holds.destroy_all

    assert_no_difference 'RelatedHoldException.count' do
      assert thesis.update_with_related_hold_reviews(
        { title: 'Updated after deletion' }, related_thesis.id.to_s => '0'
      )
    end

    assert_equal 'Updated after deletion', thesis.reload.title
  end

  test 'revoking an exception already removed by another processor is a no-op' do
    thesis = theses(:one)
    related_thesis = theses(:with_hold)
    exception = thesis.related_hold_exceptions.create!(related_thesis: related_thesis)
    related_thesis.holds.each { |hold| hold.update!(status: :released) }
    RelatedHoldException.find(exception.id).destroy!

    assert_no_difference 'RelatedHoldException.count' do
      assert thesis.update_with_related_hold_reviews(
        { title: 'Updated after revocation' }, related_thesis.id.to_s => '0'
      )
    end

    assert_equal 'Updated after revocation', thesis.reload.title
  end

  test 'an unchecked unrelated id cannot revoke another thesis exception' do
    exception = theses(:released_hold).related_hold_exceptions.create!(related_thesis: theses(:downloaded))

    assert_no_difference 'RelatedHoldException.count' do
      assert theses(:one).update_with_related_hold_reviews({}, theses(:downloaded).id.to_s => '0')
    end

    assert RelatedHoldException.exists?(exception.id)
  end

  test 'a new exception is still rejected after the related holds are released' do
    thesis = theses(:one)
    related_thesis = theses(:with_hold)
    related_thesis.holds.each { |hold| hold.update!(status: :released) }
    original_title = thesis.reload.title

    assert_no_difference 'RelatedHoldException.count' do
      assert_not thesis.update_with_related_hold_reviews(
        { title: 'Unsaved title' }, related_thesis.id.to_s => '1'
      )
    end

    assert_equal original_title, thesis.reload.title
  end

  test 'malformed ids are rejected even for unchecked decisions' do
    assert_not theses(:one).update_with_related_hold_reviews({}, 'not-an-id' => '0')
  end

  test 'non-string ids are rejected even for unchecked decisions' do
    assert_not theses(:one).update_with_related_hold_reviews({}, theses(:with_hold).id => '0')
  end

  test 'non-string decision values are rejected' do
    assert_not theses(:one).update_with_related_hold_reviews({}, theses(:with_hold).id.to_s => 0)
  end

  test 'invalid thesis updates roll back reviews and their audit records' do
    thesis = theses(:one)
    related_id = theses(:with_hold).id.to_s

    assert_no_difference ['RelatedHoldException.count', 'PaperTrail::Version.count'] do
      assert_not thesis.update_with_related_hold_reviews({ graduation_month: 'invalid' }, related_id => '1')
    end
    assert_not thesis.reload.no_other_theses_with_holds?
  end

  test 'forged review ids roll back metadata and all reviews' do
    thesis = theses(:one)
    original_title = thesis.title

    assert_no_difference 'RelatedHoldException.count' do
      assert_not thesis.update_with_related_hold_reviews(
        { title: 'Unsaved title' },
        theses(:with_hold).id.to_s => '1', theses(:released_hold).id.to_s => '1'
      )
    end
    assert_equal original_title, thesis.reload.title
  end

  test 'invalid review values are rejected' do
    thesis = theses(:one)

    assert_no_difference 'RelatedHoldException.count' do
      assert_not thesis.update_with_related_hold_reviews({}, theses(:with_hold).id.to_s => 'yes')
    end
  end

  test 'reviewed distinction survives release and subsequent holds and remains revocable' do
    thesis = theses(:one)
    related_thesis = theses(:with_hold)
    thesis.related_hold_exceptions.create!(related_thesis: related_thesis)
    related_thesis.holds.each { |hold| hold.update!(status: :released) }

    assert thesis.update_with_related_hold_reviews({}, related_thesis.id.to_s => '1')
    related_thesis.holds.first.update!(status: :active)
    assert thesis.reload.no_other_theses_with_holds?
    assert thesis.update_with_related_hold_reviews({}, related_thesis.id.to_s => '0')
    assert_not thesis.reload.no_other_theses_with_holds?
  end

  test 'an otherwise ready thesis enters review only while its related hold exception exists' do
    thesis = theses(:publication_review)
    Author.create!(user: users(:yo), thesis: thesis, graduation_confirmed: true)
    thesis.save!
    assert_equal 'Not ready for publication', thesis.reload.publication_status

    assert thesis.update_with_related_hold_reviews({}, theses(:with_hold).id.to_s => '1')
    assert_equal 'Publication review', thesis.reload.publication_status

    assert thesis.update_with_related_hold_reviews({}, theses(:with_hold).id.to_s => '0')
    assert_equal 'Not ready for publication', thesis.reload.publication_status
  end

  test 'an exception cannot waive other readiness failures' do
    thesis = theses(:publication_review)
    Author.create!(user: users(:yo), thesis: thesis, graduation_confirmed: true)

    assert thesis.update_with_related_hold_reviews({ issues_found: true }, theses(:with_hold).id.to_s => '1')
    assert thesis.reload.no_other_theses_with_holds?
    assert_equal 'Not ready for publication', thesis.publication_status
  end

  test 'invalid thesis updates roll back revocations and their audit records' do
    thesis = theses(:one)
    exception = thesis.related_hold_exceptions.create!(related_thesis: theses(:with_hold))

    assert_no_difference ['RelatedHoldException.count', 'PaperTrail::Version.count'] do
      assert_not thesis.update_with_related_hold_reviews(
        { graduation_month: 'invalid' }, theses(:with_hold).id.to_s => '0'
      )
    end
    assert RelatedHoldException.exists?(exception.id)
  end

  test 'destroying the publishing thesis audits removal of its exceptions' do
    thesis = theses(:one)
    exception = thesis.related_hold_exceptions.create!(related_thesis: theses(:with_hold))

    thesis.destroy!

    assert_not RelatedHoldException.exists?(exception.id)
    assert_equal 'destroy', exception.versions.last.event
  end

  test 'destroying a related thesis removes incoming exceptions' do
    related_thesis = theses(:released_hold)
    exception = RelatedHoldException.create!(thesis: theses(:one), related_thesis: related_thesis)
    related_thesis.holds.destroy_all

    related_thesis.destroy!

    assert_not RelatedHoldException.exists?(exception.id)
    assert_equal 'destroy', exception.versions.last.event
  end
end
