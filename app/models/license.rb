# == Schema Information
#
# Table name: licenses
#
#  id                  :integer          not null, primary key
#  display_description :text             not null
#  license_type        :text             not null
#  url                 :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
class License < ApplicationRecord
  has_many :theses

  validates :display_description, presence: true
  validates :license_type, presence: true

  # DSpace publication helper method. When the author holds copyright and provides a no-CC license, the thesis should
  # have a dc.rights statement of 'In Copyright - Educational Use Permitted'.
  def map_license_type
    if license_type == 'No Creative Commons License'
      'In Copyright - Educational Use Permitted'
    else
      license_type.to_s
    end
  end

  # Another DSpace publication helper method. No-CC license theses with a dc.rights statement of 'In Copyright -
  # Educational Use Permitted' as a result of License#map_license_type should also have the corresponding dc.rights.uri.
  # We do this here rather than modifying the database to minimize the risk of publishing the wrong rights URL. (I.e.,
  # if a record has a no-CC license but doesn't meet the condition that would trigger the map_license_type method.)
  def evaluate_license_url
    if url
      url.to_s
    elsif license_type == 'No Creative Commons License'
      'https://rightsstatements.org/page/InC-EDU/1.0/'
    end
  end
end
