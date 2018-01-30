# == Schema Information
#
# Table name: theses
#
#  id         :integer          not null, primary key
#  title      :string           not null
#  abstract   :text             not null
#  grad_date  :date             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer
#  right_id   :integer
#  status     :string           default("active")
#

class Thesis < ApplicationRecord
  belongs_to :user
  belongs_to :right
  has_many :degree_theses
  has_many :degrees, through: :degree_theses

  has_many :department_theses
  has_many :departments, through: :department_theses

  attr_accessor :graduation_year, :graduation_month

  validates :title, presence: true
  validates :abstract, presence: true

  validates :graduation_year, presence: true
  validate :valid_year?
  validates :graduation_month, presence: true
  validate :valid_month?

  validates :departments, presence: true
  validates :degrees, presence: true

  STATUS_OPTIONS = ['active', 'withdrawn', 'downloaded']
  validates_inclusion_of :status, :in => STATUS_OPTIONS

  before_create :combine_graduation_date
  after_find :split_graduation_date

  # Ensures submitted year string is reasonably sane
  def valid_year?
    oldest_year = Time.zone.now.year - 5
    latest_year = Time.zone.now.year + 5
    return if (oldest_year..latest_year).cover?(graduation_year.to_i)
    errors.add(:graduation_year, 'Invalid graduation year')
  end

  def valid_month?
    return if Date::MONTHNAMES.compact.include?(graduation_month)
    errors.add(:graduation_month, 'Invalid graduation month')
  end

  # Combine the UI supplied month and year into a datetime object
  def combine_graduation_date
    self.grad_date = Time.zone.local(graduation_year.to_i,
                                     Date::MONTHNAMES.index(graduation_month))
  end

  def split_graduation_date
    self.graduation_year = grad_date.strftime('%Y')
    self.graduation_month = grad_date.strftime('%B')
  end

  def css_alert_type
    if self.status == 'active'
      'info'
    elsif self.status == 'withdrawn'
      'danger'
    elsif self.status == 'downloaded'
      'success'
    end
  end
end
