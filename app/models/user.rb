# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  uid        :string           not null
#  email      :string           not null
#  admin      :boolean          default(FALSE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  role       :string           default("basic")
#  given_name :string
#  surname    :string
#

class User < ApplicationRecord
  # We need to initialize  some fields before validation, or 
  # the record won't save.
  before_validation(on: :create) do
    self.kerberos_id = kerb unless self.kerberos_id
    self.display_name = name unless self.display_name
    self.uid = self.kerberos_id + '@mit.edu' unless self.uid
  end

  # Display name should be aligned with preferred name
  before_update do
    self.display_name = name
  end

  # ORCID has a unique constraint, so if it's empty, we need to save it 
  # as nil instead of an empty string
  before_save do
    self.orcid = nil if self.orcid == ""
  end

  default_scope { order('surname ASC') }

  if Rails.configuration.fake_auth_enabled  # Use config, not ENV. See README.
    devise :omniauthable, omniauth_providers: [:developer]
  else
    devise :omniauthable, omniauth_providers: [:saml]
  end

  validates :uid, presence: true #, uniqueness: true
  validates :email, presence: true
  validates :display_name, presence: true
  validates :kerberos_id, presence: true
  has_many :authors
  has_many :theses, through: :authors, dependent: :restrict_with_error
  has_many :transfers
  has_many :submitters
  has_many :departments, through: :submitters

  ROLES = %w[basic processor thesis_admin]
  validates_inclusion_of :role, :in => ROLES

  # `uid` is a unique ID that comes back from OmniAuth (which gets it from
  # the remote authentication provider). It is used to lookup or create a new
  # local user via this method.
  # Touchstone and fake_auth put this UID in different places.
  def self.from_omniauth(auth)
    if auth.info.key? 'uid'
      uid = auth.info.uid
    else
      uid = auth.uid
    end

    User.where(uid: uid).first_or_create do |user|
      user.email = auth.info.email
      user.given_name = auth.info.given_name
      user.surname = auth.info.surname
      user.display_name = auth.info.display_name
    end
  end

  # Definitely for sure wrong for some people. But staff want to be able to
  # sort on surname for processing purposes, so we're getting given name +
  # surname. This could pose a problem for those who prefer not to use 
  # their legal surname. In an effort to make as few assumptions about 
  # identity as possible, we are privileging preferred names for sorting.
  def name
    if self.preferred_name.present?
      "#{self.preferred_name}"
    elsif self.surname.present? && self.given_name.present? && self.middle_name.present?
      "#{self.surname}, #{self.given_name} #{self.middle_name.first}."
    elsif self.surname.present? && self.given_name.present?
      "#{self.surname}, #{self.given_name}"
    else
      "#{self.email}"
    end
  end

  # We want to ensure that the email always appears in the processing 
  # queue names, but not elsewhere in the application.
  def processing_queue_name
    self.name.include?(self.email) ? "#{self.name}" : "#{self.name} (#{self.email})"
  end

  # Users with the "thesis_admin" role can submit transfers for any department.
  # Users without that role are more limited.
  def submittable_departments
    if role == "thesis_admin"
      Department.all.order(:name)
    else
      departments.order(:name)
    end
  end

  private

    # For our purposes, kerberos_id is EPPN (uid) without '@mit.edu'
    def kerb
      self.uid.delete_suffix('@mit.edu') if uid
    end
end
