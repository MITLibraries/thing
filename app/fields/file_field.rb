require 'administrate/field/base'

class FileField < Administrate::Field::Base
  def files
    data.record.files
  end
end
