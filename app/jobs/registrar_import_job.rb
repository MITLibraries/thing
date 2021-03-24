require 'csv'

class RegistrarImportJob < ActiveJob::Base
  queue_as :default

  def perform(registrar)
    results = {read: 0, processed: 0, errors: []}

    CSV.new(registrar.graduation_list.download, headers: true).each.with_index(1) do |row, i|
      Rails.logger.info("Parsing row " + i.to_s)
      results[:read] += 1

      # Check CSV for Kerberos ID, required to process data
      kerb = row['Krb Name']
      if kerb.blank?
        e = "Row ##{i.to_s} missing a Kerberos ID: #{row.inspect}"
        Rails.logger.warn(e)
        results[:errors] << e
        next
      end

      user = User.create_or_update_from_csv(row)
      degree = Degree.from_csv(row)
      department = Department.from_csv(row)
      grad_date = reformat_grad_date(row['Degree Award Date'])
      begin
        thesis = Thesis.create_or_update_from_csv(user, degree, department, grad_date, row)
      rescue RuntimeError
        e = "Multiple theses found for author #{user.name} for term #{grad_date.to_s}, requires Processor attention. CSV row ##{i.to_s}: #{row.inspect}"
        Logger.warn(e)
        results[:errors] << e
        next
      end

      primary = row['Is Primary Course Of Major'] == "Y"
      thesis_department = thesis.department_theses.find_by!(department_id: department.id)
      thesis_department.set_primary(primary)
      author = thesis.authors.find_by!(user_id: user.id)
      author.set_graduated_from_csv(row)
      results[:processed] += 1
    end
    Rails.logger.info(results.to_s)
    return results
  end

    # The thesis model sets the day of the month to 1 if only supplied a month
    # and a year during thesis creation, which means in practice we have to
    # assume that the day is always 1 (because this will be true for any theses
    # created from the UI)
    def reformat_grad_date(csv_grad_date)
      csv_date = Date.strptime(csv_grad_date.split[0], '%m/%d/%y')
      thing_date = csv_date.change(day: 1)
      return thing_date
    end

end
