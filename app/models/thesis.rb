# == Schema Information
#
# Table name: theses
#
#  id                 :integer          not null, primary key
#  title              :string
#  abstract           :text
#  grad_date          :date             not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  status             :string           default("active")
#  processor_note     :text
#  author_note        :text
#  files_complete     :boolean          default(FALSE), not null
#  metadata_complete  :boolean          default(FALSE), not null
#  publication_status :string           default("Not ready for publication"), not null
#  coauthors          :string
#  copyright_id       :integer
#  license_id         :integer
#  dspace_handle      :string
#  issues_found       :boolean          default(FALSE), not null
#

class Thesis < ApplicationRecord
  has_paper_trail

  belongs_to :copyright, optional: true
  belongs_to :license, optional: true

  has_many :degree_theses
  has_many :degrees, through: :degree_theses

  has_many :department_theses
  has_many :departments, through: :department_theses

  has_many :holds, dependent: :restrict_with_error
  has_many :hold_sources, through: :holds

  has_many :advisor_theses
  has_many :advisors, through: :advisor_theses

  has_many :authors, dependent: :destroy
  has_many :users, through: :authors

  has_many_attached :files
  has_one_attached :dspace_metadata

  accepts_nested_attributes_for :users
  accepts_nested_attributes_for :advisors, allow_destroy: true
  accepts_nested_attributes_for :department_theses, allow_destroy: true
  accepts_nested_attributes_for :files_attachments, allow_destroy: true

  attr_accessor :graduation_year, :graduation_month

  VALIDATION_MSGS = {
    copyright: 'Required - Please identify the copyright holder.',
    graduation_year: 'Required - Please input your year of graduation.',
    graduation_month: 'Required - Please select your month of graduation.',
    departments: 'Required - Please select your primary department.',
    degrees: 'Required - Please select your primary degree.',
    preferred_name: 'Required - Please confirm your name.',
    title: 'Required - Please provide your thesis title.'
  }.freeze

  validates :graduation_year, presence:
    { message: VALIDATION_MSGS[:graduation_year] }
  validate :valid_year?
  validates :graduation_month, presence:
    { message: VALIDATION_MSGS[:graduation_month] }
  validate :valid_month?

  validates :departments, presence:
    { message: VALIDATION_MSGS[:departments] }

  validates :files_complete, exclusion: [nil]
  validates :metadata_complete, exclusion: [nil]
  validates :issues_found, exclusion: [nil]

  validates :users, presence: true

  STATUS_OPTIONS = %w[active withdrawn downloaded].freeze
  validates_inclusion_of :status, in: STATUS_OPTIONS

  PUBLICATION_STATUS_OPTIONS = ['Not ready for publication',
                                'Publication review',
                                'Pending publication',
                                'Published',
                                'Publication error'].freeze
  validates_inclusion_of :publication_status, in: PUBLICATION_STATUS_OPTIONS

  VALID_MONTHS = %w[February May June September].freeze

  before_save :combine_graduation_date, :update_status
  after_find :split_graduation_date

  # scope :name_asc, lambda {
  #  includes(:user).order('users.surname, users.given_name')
  # }
  scope :date_asc, -> { order('grad_date') }
  scope :without_files, -> { where.missing(:files_attachments) }
  scope :valid_months_only, lambda {
    select { |t| VALID_MONTHS.include? t.grad_date.strftime('%B') }
  }
  scope :publication_statuses, -> { PUBLICATION_STATUS_OPTIONS }

  # This inverts the issues_found field, so that the checks inside the
  # update_status method below are all written the same way.
  # The UI will still rely on the issues_found field directly, as its
  # framing is more logical for the user.
  def no_issues_found?
    !issues_found
  end

  # Returns a true/false value (rendered as "yes" or "no") if there are any
  # holds with a status of either 'active' or 'expired'. A false/"No" is
  # only returned if all holds are 'released'.
  def active_holds?
    holds.map { |h| h.status.in? %w[active expired] }.any?
  end

  # This just inverts the active_holds? method above, so that the checks
  # inside the update_status method below are all written the same way.
  # The UI will rely on active_holds? because its framing is more logical
  # for the user.
  def no_active_holds?
    !active_holds?
  end

  # Returns a true/false value (rendered as "yes" or "no") if all authors
  # have graduated. Any author having not graduated results in a false/"No".
  def authors_graduated?
    authors.map(&:graduation_confirmed?).reduce(:&)
  end

  # This checks whether a thesis record is new, based on the most recent transaction. Once the record is updated or
  # saved, this will evaluate to false. Normally we would use ActiveModel::Dirty for this, but that module doesn't work
  # well for models with nested attributes.
  def new_thesis?
    transaction_include_any_action?([:create])
  end

  # This contains the logic for a thesis to have its status set to either
  # 'Not ready for publication' or 'Publication review'. Setting the status
  # to 'Pending publication' and 'Published' is handled via separate methods.
  def update_status
    # If a thesis has been set to 'Pending publication' or 'Published', this
    # method cannot change it; other methods will set/revert that status.
    return if ['Pending publication', 'Published', 'Publication error'].include? publication_status

    # Still here? Then we proceed...
    # By default, a thesis is set to 'Not ready for production'
    self.publication_status = 'Not ready for publication'
    # If the five qualifying conditions are met, then we set status to
    # 'publication review'. This will leave unchanged a thesis that was
    # already set to 'Pending publication' via another method.
    if [
      files_complete,
      metadata_complete,
      no_issues_found?,
      no_active_holds?,
      authors_graduated?
    ].all?
      self.publication_status = 'Publication review'
    end
    # Please note that the 'pending publiation' and 'published' statuses can
    # not be set via this method - they get assigned elsewhere.
  end

  # Ensures submitted graduation year is a four-digit integer, not less than
  # the year of the Institute's founding.
  # We expect that graduation_year will be a String (in which case to_s is a
  # no-op), but if it's an Integer this will also work.
  def valid_year?
    return if /^\d{4}$/.match(graduation_year.to_s) &&
              graduation_year.to_i >= 1861

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

  # Given a row of CSV data from Registrar import plus existing
  # instances of user, degree, and department, and a THing formatted
  # graduation date, find a thesis by Kerberos ID of author from CSV data and
  # update all thesis attributes for which the Registrar has authoritative
  # data, or create a new thesis from the provided attributes and CSV data.
  # or create one from the provided attributes and CSV data. Raises an error if
  # multiple theses are found for an author in a given degree period, as that
  # scenario needs to be handled manually by a Processor.
  def self.create_or_update_from_csv(author, degree, department, grad_date, row)
    theses = Thesis.joins(:authors).where(authors: { user_id: author.id }).where(grad_date: grad_date)
    if theses.empty?
      new_thesis = Thesis.create(
        coauthors: row['Thesis Coauthor'],
        degrees: [degree],
        departments: [department],
        graduation_month: grad_date.strftime('%B'),
        graduation_year: grad_date.year,
        title: row['Thesis Title'],
        users: [author]
      )
      Rails.logger.info("New thesis created: #{author.name}, #{grad_date}")
      new_thesis
    elsif theses.size == 1
      thesis = theses.first
      if thesis.coauthors.blank?
        thesis.coauthors = row['Thesis Coauthor']
      elsif thesis.coauthors.exclude? row['Thesis Coauthor'].to_s
        thesis.coauthors += "; #{row['Thesis Coauthor']}"
      end
      thesis.degrees << degree unless thesis.degrees.include?(degree)
      thesis.departments << department unless thesis.departments.include?(department)
      thesis.title = row['Thesis Title'] if thesis.title.blank?
      thesis.save
      Rails.logger.info("Thesis updated: #{author.name}, #{grad_date}")
      thesis
    else
      raise 'Multiple theses found'
    end
  end
end
