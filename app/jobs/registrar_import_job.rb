require 'csv'

class RegistrarImportJob < ActiveJob::Base
  queue_as :default

  def perform(registrar)
    results = { read: 0, processed: 0, new_users: 0, new_theses: 0, updated_theses: 0, new_degrees: [], new_depts: [],
                new_degree_periods: [], errors: [] }
    new_theses = [] # Track newly created theses to detect duplicate theses with holds

    CSV.new(registrar.graduation_list.download, headers: true).each.with_index(1) do |row, i|
      Rails.logger.info("Parsing row #{i}")
      results[:read] += 1

      # Check CSV for Kerberos ID, required to process data
      kerb = row['Krb Name']
      if kerb.blank?
        e = "Row ##{i} missing a Kerberos ID: #{row.inspect}"
        Rails.logger.warn(e)
        results[:errors] << e
        next
      end

      # Set whodunnit for user transaction
      PaperTrail.request.whodunnit = 'registrar'
      user = User.create_or_update_from_csv(row)
      results[:new_users] += 1 if user.id_previously_changed?
      logger.info("User is #{user.inspect}")
      degree = Degree.from_csv(row)
      logger.info("Degree is #{degree.inspect}")
      results[:new_degrees] << degree if degree.id_previously_changed?
      department = Department.from_csv(row)
      logger.info("Department is #{department.inspect}")
      results[:new_depts] << department if department.id_previously_changed?
      grad_date = reformat_grad_date(row['Degree Award Date'])
      logger.info("Grad date is #{grad_date.inspect}")
      degree_period = DegreePeriod.from_grad_date(grad_date)
      results[:new_degree_periods] << degree_period if degree_period.id_previously_changed?
      begin
        # Set whodunnit for thesis transaction
        PaperTrail.request.whodunnit = 'registrar'
        thesis = Thesis.create_or_update_from_csv(user, degree, department, grad_date, row)
        if thesis.new_thesis?
          results[:new_theses] += 1
          new_theses << thesis
        else
          results[:updated_theses] += 1
        end
        logger.info("Thesis is #{thesis.inspect}")
      rescue RuntimeError
        e = "Multiple theses found for author #{user.name} for term #{grad_date}, requires Processor attention. CSV row ##{i}: #{row.inspect}"
        logger.warn(e)
        results[:errors] << e
        next
      end

      primary = row['Is Primary Course Of Major'] == 'Y'
      thesis_department = thesis.department_theses.find_by!(department_id: department.id)
      thesis_department.set_primary(primary)
      author = thesis.authors.find_by!(user_id: user.id)
      author.set_graduated_from_csv(row)
      results[:processed] += 1
    end

    multiple_hold_users = collect_users_with_multiple_hold_theses(new_theses)

    Rails.logger.info(results.to_s)
    ReportMailer.registrar_import_email(registrar, results, multiple_hold_users).deliver_later
    results
  end

  def collect_users_with_multiple_hold_theses(new_theses)
    multiple_hold_users = []

    new_theses.each do |thesis|
      other_theses_with_holds = thesis.other_theses_with_holds.includes(:users).to_a
      thesis.users.each do |user|
        user_with_other_theses_with_holds = other_theses_with_holds.select do |other_thesis|
          other_thesis.users.any? { |u| u.id == user.id }
        end
        next if user_with_other_theses_with_holds.empty?

        multiple_hold_users << {
          user: user,
          new_thesis: thesis,
          other_theses_with_holds: user_with_other_theses_with_holds
        }
      end
    end

    multiple_hold_users
  end

  # The thesis model sets the day of the month to 1 if only supplied a month
  # and a year during thesis creation, which means in practice we have to
  # assume that the day is always 1 (because this will be true for any theses
  # created from the UI)
  def reformat_grad_date(csv_grad_date)
    csv_date = Date.strptime(csv_grad_date.split[0], '%m/%d/%Y')
    csv_date.change(day: 1)
  end
end
