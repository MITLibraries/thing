# Exports a single thesis as a hash for JSON serialization.
#
# Transforms a thesis record into a flat-ish structure with nested arrays for repeating fields
# (authors, advisors, degrees, departments).
#
# Example:
#   exporter = CatalogExporter.new(thesis)
#   hash = exporter.to_hash
#   # => { title: "...", abstract: "...", authors: [{name: "..."}, ...], ... }
class CatalogExporter
  def initialize(thesis)
    @thesis = thesis
  end

  # Returns a hash representation of the thesis with all fields required by the metadata team.
  # Includes: title, abstract, graduation_year, dspace_url, advisors, authors, degrees, and
  # departments. Array fields are normalized to hashes with relevant metadata.
  def to_hash
    {
      abstract:,
      advisors:,
      authors:,
      degrees:,
      departments:,
      dspace_url:,
      graduation_year:,
      title:
    }
  end

  private

  def abstract
    @thesis.abstract
  end

  def advisors
    @thesis.advisors.map do |advisor|
      { name: advisor.name }
    end
  end

  def authors
    @thesis.authors.map do |author|
      { name: author.user.preferred_name }
    end
  end

  def degrees
    @thesis.degrees.map do |degree|
      { abbreviation: degree.abbreviation }
    end
  end

  def departments
    @thesis.departments.map do |department|
      { name: department.name_dspace }
    end
  end

  def dspace_url
    "https://dspace.mit.edu/handle/#{@thesis.dspace_handle}"
  end

  def graduation_year
    @thesis.graduation_year
  end

  def title
    @thesis.title.squish
  end
end
