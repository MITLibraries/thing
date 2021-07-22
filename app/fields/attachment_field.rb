require 'administrate/field/base'

class AttachmentField < Administrate::Field::Base
  def attachments
    data
  end
end
