# == Schema Information
#
# Table name: degree_periods
#
#  id         :integer          not null, primary key
#  grad_month :string
#  grad_year  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class DegreePeriod < ApplicationRecord
  has_paper_trail
  has_one :archivematica_accession, dependent: :destroy

  validates :grad_year, format: { with: /\A(19|20)\d{2}\z/i,
                                  message: 'must be between 1900 and 2099' },
                        uniqueness: { scope: :grad_month, message: 'and month combination already exists' }

  VALID_GRAD_MONTHS = %w[May June September February].freeze
  validates_inclusion_of :grad_month, in: VALID_GRAD_MONTHS

  # Given a grad date from a registrar data import CSV (or elsewhere, look up a Degree Period and create one if it does
  # not exist.
  def self.from_grad_date(grad_date)
    new_grad_month = grad_date.strftime('%B')
    new_grad_year = grad_date.strftime('%Y')
    degree_period = DegreePeriod.find_by(grad_month: new_grad_month, grad_year: new_grad_year)
    if degree_period.blank?
      new_degree_period = DegreePeriod.create!(grad_month: new_grad_month, grad_year: new_grad_year)
      Rails.logger.warn("New department created, requires Processor attention: \
                         #{new_degree_period.grad_month} #{new_degree_period.grad_year}")
      new_degree_period
    else
      degree_period
    end
  end
end
