class DegreePeriod < ApplicationRecord
  has_paper_trail
  has_one :archivematica_accession, dependent: :destroy

  validates :grad_year, format: { with: /\A(19|20)\d{2}\z/i,
                                  message: 'must be between 1900 and 2099' },
                        uniqueness: { scope: :grad_month, message: 'and month combination already exists' }

  VALID_GRAD_MONTHS = %w[May June September February].freeze
  validates_inclusion_of :grad_month, in: VALID_GRAD_MONTHS
end
