# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).

Rails.logger.info('Seeding DB Starting')

# Create Copyrights
Copyright.create_with(
  display_to_author: true,
  display_description: 'MIT holds copyright',
  statement_dspace: 'In Copyright - Educational Use Permitted',
  url: 'http://rightsstatements.org/page/InC-EDU/1.0/'
).find_or_create_by(
  holder: 'MIT'
)
Copyright.create_with(
  display_to_author: true,
  display_description: 'I hold copyright',
  statement_dspace: 'In Copyright',
  url: 'https://rightsstatements.org/page/InC/1.0/'
).find_or_create_by(
  holder: 'Author'
)
Copyright.create_with(
  display_to_author: true,
  display_description: 'I hold copyright and give it up to the public domain with no copyright',
  statement_dspace: 'CC0 - Public Domain',
  url: 'https://creativecommons.org/publicdomain/zero/1.0/'
).find_or_create_by(
  holder: 'Public Domain'
)
Copyright.create_with(
  display_to_author: true,
  display_description: 'This is a work of the U.S. Government',
  statement_dspace: 'This material is declared a work of the U.S. Government and is not subject to copyright protection in the United States.',
  url: 'https://rightsstatements.org/page/NoC-US/1.0/'
).find_or_create_by(
  holder: 'US Government'
)
Copyright.create_with(
  display_to_author: true,
  display_description: 'Another person or organization holds copyright',
  statement_dspace: 'In Copyright',
  url: 'http://rightsstatements.org/vocab/InC/1.0/'
).find_or_create_by(
  holder: 'Other Organization'
)

# Create Departments
Department.create_with(
  code_dw: '16',
  name_dspace: 'Massachusetts Institute of Technology. Department of Aeronautics and Astronautics'
).find_or_create_by(
  name_dw: 'Department of Aeronautics and Astronautics'
)
Department.create_with(
  code_dw: '21A',
  name_dspace: 'MIT Anthropology Program'
).find_or_create_by(
  name_dw: 'Program in Anthropology'
)

# Create Degrees
Degree.create_with(
  name_dw: 'Music and Theater Arts',
  abbreviation: 'S.B.'
).find_or_create_by(code_dw: 'SB21M2')
Degree.create_with(
  name_dw: 'Environmental Engineer',
  abbreviation: 'Env.E.'
).find_or_create_by(code_dw: 'ENENV')

# Create Rights
# Right.find_or_create_by(statement: 'MIT')
# Right.find_or_create_by(statement: 'Author Retains')
# Right.find_or_create_by(statement: 'Other')

# Create Hold Sources
HoldSource.find_or_create_by(source: 'TLO')
HoldSource.find_or_create_by(source: 'Vice Chancellor')
HoldSource.find_or_create_by(source: 'VPR')

# Create Licenses
License.create_with(
  license_type: 'No Creative Commons License'
).find_or_create_by(
  display_description: 'No Creative Commons License'
)
License.create_with(
  license_type: 'Attribution 4.0 International (CC BY 4.0)',
  url: 'https://creativecommons.org/licenses/by/4.0/'
).find_or_create_by(
  display_description: 'Creative Commons (CC BY)'
)
License.create_with(
  license_type: 'Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)',
  url: 'https://creativecommons.org/licenses/by-sa/4.0/'
).find_or_create_by(
  display_description: 'Creative Commons (CC BY-SA)'
)
License.create_with(
  license_type: 'Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)',
  url: 'https://creativecommons.org/licenses/by-nc/4.0/'
).find_or_create_by(
  display_description: 'Creative Commons (CC BY-NC)'
)
License.create_with(
  license_type: 'Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)',
  url: 'https://creativecommons.org/licenses/by-nc-sa/4.0/'
).find_or_create_by(
  display_description: 'Creative Commons (CC BY-NC-SA)'
)
License.create_with(
  license_type: 'Attribution-NoDerivatives 4.0 International (CC BY-ND 4.0)',
  url: 'https://creativecommons.org/licenses/by-nd/4.0/'
).find_or_create_by(
  display_description: 'Creative Commons (CC BY-ND)'
)
License.create_with(
  license_type: 'Attribution-NonCommercial-NoDerivatives 4.0 International (CC BY-NC-ND 4.0)',
  url: 'https://creativecommons.org/licenses/by-nc-nd/4.0/'
).find_or_create_by(
  display_description: 'Creative Commons (CC BY-NC-ND)'
)

# Create Degree Types
DegreeType.find_or_create_by(name: 'Bachelor')
DegreeType.find_or_create_by(name: 'Doctoral')
DegreeType.find_or_create_by(name: 'Engineer')
DegreeType.find_or_create_by(name: 'Master')

Rails.logger.info('Seeding DB Complete')
