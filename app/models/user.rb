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
#  name       :string
#

class User < ApplicationRecord
  if Rails.configuration.fake_auth_enabled  # Use config, not ENV. See README.
    devise :omniauthable, omniauth_providers: [:developer]
  else
    devise :omniauthable, omniauth_providers: [:saml]
  end

  validates :uid, presence: true
  validates :email, presence: true
  validates :name, presence: true
  has_many :theses

  ROLES = %w[basic processor thesis_admin sysadmin]
  validates_inclusion_of :role, :in => ROLES

  # `uid` is a unique ID that comes back from OmniAuth (which gets it from
  # the remote authentication provider). It is used to lookup or create a new
  # local user via this method.
  def self.from_omniauth(auth)
    User.where(uid: auth.info.uid).first_or_create do |user|
      user.email = auth.info.email
      user.name = auth.info.name
    end
  end
end
