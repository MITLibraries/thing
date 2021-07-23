require 'csv'
require 'open-uri'

namespace :db do
  desc 'Seed the database with degrees from a Degree Seeds CSV file'
  task :seed_degrees, [:file_url] => :environment do |_t, args|
    csv_data = URI.parse(args[:file_url]).open
    CSV.new(csv_data, encoding: 'bom|utf-8', headers: true).each.with_index(2) do |row, i|
      Rails.logger.info("Processing row #{i}")
      degree = Degree.from_csv(row)
      if degree.name_dspace.blank?
        degree.update(name_dspace: row['Degree Name DSpace'])
        Rails.logger.info("Degree DSpace name added: #{degree.name_dspace}")
      end
      unless degree.degree_type
        degree.update(degree_type: DegreeType.find_by(name: row['THING Degree Type']))
        Rails.logger.info("Degree type added: #{degree.degree_type.name}")
      end
      Rails.logger.info("Degree complete: #{degree.inspect}")
    end
  end

  desc 'Seed the database with departments from a Department Seeds CSV file'
  task :seed_departments, [:file_url] => :environment do |_t, args|
    csv_data = URI.parse(args[:file_url]).open
    CSV.new(csv_data, encoding: 'bom|utf-8', headers: true).each.with_index(2) do |row, i|
      Rails.logger.info("Processing row #{i}")
      department = Department.from_csv(row)
      if department.name_dspace.blank?
        department.update(name_dspace: row['Department Name DSpace'])
        Rails.logger.info("Department DSpace name added: #{department.name_dspace}")
      end
      Rails.logger.info("Department complete: #{department.inspect}")
    end
  end
end
