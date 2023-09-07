# == Schema Information
#
# Table name: transfers
#
#  id                     :integer          not null, primary key
#  user_id                :integer          not null
#  department_id          :integer          not null
#  grad_date              :date             not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  note                   :text
#  files_count            :integer          default(0), not null
#  unassigned_files_count :integer          default(0), not null
#
class Transfer < ApplicationRecord
  belongs_to :user
  belongs_to :department
  before_save :update_files_count
  after_create_commit :initial_files_count

  has_many_attached :files

  attr_accessor :transfer_certified, :graduation_year, :graduation_month

  VALIDATION_MSGS = {
    department: 'Required - Please specify the department submitting the transfer.',
    graduation_year: 'Required - Please select degree year.',
    graduation_month: 'Required - Please select degree month.',
    files: 'Required - Attaching at least one file is required.'
  }.freeze

  validates :department, presence: { message: VALIDATION_MSGS[:department] }
  validates :graduation_year, presence:
    { message: VALIDATION_MSGS[:graduation_year] }
  validate :valid_year?
  validates :graduation_month, presence:
    { message: VALIDATION_MSGS[:graduation_month] }
  validate :valid_month?
  validates :files, presence: true

  VALID_MONTHS = %w[February May June September].freeze

  before_create :combine_graduation_date
  after_find :split_graduation_date

  scope :valid_months_only, lambda {
    select { |t| VALID_MONTHS.include? t.grad_date.strftime('%B') }
  }

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

  def unassigned_files
    count = 0
    if files.blobs.is_a?(Array)
      files.blobs.each do |blob|
        count += 1 if blob.attachment_ids.count == 1
      end
    else
      files.blobs.all.each do |blob|
        count += 1 if blob.attachment_ids.count == 1
      end
    end
    count
  end

  # This ensures that the activestorage objects are actually available before we update the initial files counts.
  # The files are not available until the after_create_commit callback so our before_save callback does not work
  # for initial Transfer creation. This does mean we calculate the counts twice on creation (once with the count as
  # always zero, then the initial commit, then during the after_create_commit we re-save which counts them properly).
  def initial_files_count
    save
  end

  # This is triggered on before_save, but we must also remember to call Transfer#save to trigger this
  # any time we are changing the files attached in a manner that wouldn't update Transfer directly.
  # This can happen during the Transfer processing workflow (attaching files to Theses) and Thesis
  # processing workflows (removing files from Theses)
  def update_files_count
    Rails.logger.debug("TRANSFER_COUNTS: Initial files_count for thesis #{id} is #{files_count}")
    self.files_count = files.count
    Rails.logger.debug("TRANSFER_COUNTS: Updated files_count for thesis #{id} is #{files_count}")

    Rails.logger.debug("TRANSFER_COUNTS: Initial unassigned_files_count for thesis #{id} is #{unassigned_files_count}")
    self.unassigned_files_count = unassigned_files
    Rails.logger.debug("TRANSFER_COUNTS: Updated unassigned_files_count for thesis #{id} is #{unassigned_files_count}")
  end
end
