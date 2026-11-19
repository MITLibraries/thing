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
# This model records a processor's decision that a related thesis represents a distinct work, and
# its holds should not block publication of the thesis being processed.
#
# The pair is directional:
#   - thesis is the record being published
#   - related_thesis is the record whose holds are waived for that publication
#
# The reverse exception is not implied, and direct holds or holds on other, unreviewed related
# theses still block publication.
#
# Exceptions persist until explicitly revoked, even if the related thesis's holds are
# released and later added again. PaperTrail tracks model activity.
class RelatedHoldException < ApplicationRecord
  has_paper_trail

  belongs_to :thesis
  belongs_to :related_thesis, class_name: 'Thesis'

  validates :related_thesis_id, uniqueness: { scope: :thesis_id }
  validate :distinct_theses

  # Applies processing-form decisions keyed by string  IDs: '1' grants or retains
  # an exception, and '0' revokes it. Omitted IDs leave existing exceptions unchanged.
  # Validates the whole submission before changing records and uses create!/destroy!
  # to retain audit callbacks. The caller wraps this and the thesis save in a transaction
  # so failed metadata updates also roll back exception changes and their audit records.
  def self.apply_reviews!(thesis, reviews)
    existing = thesis.related_hold_exceptions.index_by { |exception| exception.related_thesis_id.to_s }
    validate_reviews!(thesis, reviews, existing.keys)
    reviews.each do |related_id, reviewed|
      if reviewed == '1'
        thesis.related_hold_exceptions.create!(related_thesis_id: related_id) unless existing.key?(related_id)
      else
        existing[related_id]&.destroy!
      end
    end
  end

  # Grants require a currently held related thesis or an existing exception. Revoking an
  # already-absent exception is a no-op, including when a hold was released after the form loaded.
  # IDs must be positive integer strings and decisions must be '0' or '1'. Invalid submissions
  # raise ActiveRecord::RecordInvalid before any exception changes are applied.
  def self.validate_reviews!(thesis, reviews, reviewed_ids)
    allowed_ids = thesis.other_theses_with_holds.ids.map(&:to_s) | reviewed_ids
    return if reviews.all? do |related_id, reviewed|
      valid_decisions = allowed_ids.include?(related_id) ? %w[0 1] : ['0']
      related_id.is_a?(String) && /\A[1-9]\d*\z/.match?(related_id) && valid_decisions.include?(reviewed)
    end

    thesis.errors.add(:base, 'Related hold reviews must identify related theses and a checked or unchecked decision.')
    raise ActiveRecord::RecordInvalid, thesis
  end

  private

  # Prevents an exception from targeting the publishing thesis itself.
  def distinct_theses
    errors.add(:related_thesis, 'must be a different thesis') if thesis == related_thesis
  end
end
