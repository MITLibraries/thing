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
#  note       :text
#

class Thesis < ApplicationRecord
  belongs_to :user
  belongs_to :right
  has_many :degree_theses
  has_many :degrees, through: :degree_theses

  has_many :department_theses
  has_many :departments, through: :department_theses

  has_many :holds
  has_many :hold_sources, through: :holds

  has_many_attached :files

  attr_accessor :graduation_year, :graduation_month

  VALIDATION_MSGS = {
    title: 'Required - Please provide the title for your thesis.',
    abstract: 'Required - Please provide the abstract for your thesis.',
    graduation_year: 'Required - Please input your year of graduation.',
    graduation_month: 'Required - Please select your month of graduation.',
    departments: 'Required - Please select your primary department.',
    degrees: 'Required - Please select your primary degree.',
    right: 'Required - Please select the appropriate copyright.',
    files: 'Required - Attaching your thesis is required.',
  }

  validates :title, presence:
    { message: VALIDATION_MSGS[:title] }
  validates :abstract, presence:
    { message: VALIDATION_MSGS[:abstract] }

  validates :graduation_year, presence:
    { message: VALIDATION_MSGS[:graduation_year] }
  validate :valid_year?
  validates :graduation_month, presence:
    { message: VALIDATION_MSGS[:graduation_month] }
  validate :valid_month?

  validates :departments, presence:
    { message: VALIDATION_MSGS[:departments] }
  validates :degrees, presence:
    { message: VALIDATION_MSGS[:degrees] }

  # validates :files, presence: true

  STATUS_OPTIONS = ['active', 'withdrawn', 'downloaded']
  validates_inclusion_of :status, :in => STATUS_OPTIONS

  VALID_MONTHS = ['February', 'May', 'June', 'September']

  before_create :combine_graduation_date
  after_find :split_graduation_date

  scope :name_asc, lambda {
    includes(:user).order('users.surname, users.given_name')
  }
  scope :date_asc, -> { order('grad_date') }
  scope :by_status, lambda { |status|
    if status == 'any'
      @theses = self.all
    elsif status.present?
      # We could also test that Thesis::STATUS_OPTIONS.include? status,
      # but we aren't, because:
      # 1) if some URL hacker enters status=purple, they'll get 200 OK, not
      #    500;
      # 2) also they deserve the blank page they get.
      @theses = self.where(status: status)
    else
      @theses = self.where(status: 'active')
    end
  }
  scope :valid_months_only, lambda {
    select { |t| VALID_MONTHS.include? t.grad_date.strftime('%B') }
  }

  # Ensures submitted graduation year is a four-digit integer, not less than
  # the year of the Institute's founding.
  # We expect that graduation_year will be a String (in which case to_s is a
  # no-op), but if it's an Integer this will also work.
  def valid_year?
    return if (/^\d{4}$/.match(graduation_year.to_s) &&
               graduation_year.to_i >= 1861)
    errors.add(:graduation_year, 'Invalid graduation year')
  end

  def valid_month?
    return if VALID_MONTHS.include?(graduation_month)
    errors.add(:graduation_month,
      'Invalid graduation month; must be May, June, September, or February')
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
