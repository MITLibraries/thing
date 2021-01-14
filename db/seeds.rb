# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).

Rails.logger.info('Seeding DB Starting')

# Create Departments
Department.find_or_create_by(name: 'Aeronautics and Astronautics')
Department.find_or_create_by(name: 'Archaeology and Materials')

# Create Rights
Right.find_or_create_by(statement: 'MIT')
Right.find_or_create_by(statement: 'Author Retains')
Right.find_or_create_by(statement: 'Other')

# Create Degrees
Degree.find_or_create_by(name: 'Bachelor of Science')
Degree.find_or_create_by(name: 'Master of Business Analytics')

# Create Hold Sources
HoldSource.find_or_create_by(source: 'TLO')
HoldSource.find_or_create_by(source: 'Vice Chancellor')
HoldSource.find_or_create_by(source: 'VPR')

Rails.logger.info('Seeding DB Complete')
