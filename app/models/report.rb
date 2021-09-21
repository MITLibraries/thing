class Report
  delegate :url_helpers, to: 'Rails.application.routes'

  def card_files(collection, term)
    subset = collection.joins(:files_attachments)
    {
      'value' => subset.pluck(:id).uniq.count,
      'verb' => 'has',
      'label' => 'files attached',
      'note' => 'Only theses with a status of "Not ready for publication" and "Publication review" will be visible '\
                'in the processing queue.',
      'link' => {
        'url' => url_helpers.thesis_select_path(graduation: term),
        'text' => "See #{subset.where('publication_status != ?', 'Published').pluck(:id).uniq.count} unpublished "\
                  'theses in processing queue'
      }
    }
  end

  def card_issues(collection)
    {
      'value' => collection.where('issues_found = ?', true).count,
      'label' => 'flagged with issues'
    }
  end

  def card_multiple_authors(collection)
    {
      'value' => collection.joins(:authors).group('theses.id').having('COUNT(authors.id) > 1').length,
      'verb' => 'has',
      'label' => 'multiple authors'
    }
  end

  def card_multiple_degrees(collection)
    {
      'value' => collection.joins(:degrees).group('theses.id').having('COUNT(degrees.id) > 1').length,
      'verb' => 'has',
      'label' => 'multiple degrees'
    }
  end

  def card_multiple_departments(collection)
    {
      'value' => collection.joins(:departments).group('theses.id').having('COUNT(departments.id) > 1').length,
      'verb' => 'has',
      'label' => 'multiple departments'
    }
  end

  def card_overall(collection, term)
    searchterm = term if term != 'all'
    {
      'value' => collection.count,
      'verb' => 'thesis record',
      'link' => {
        'url' => url_helpers.admin_theses_path(search: searchterm),
        'text' => 'See all in admin dashboard'
      }
    }
  end

  def dashboard_data(collection, term)
    result = {}
    result['overall'] = card_overall collection, term
    result['files'] = card_files collection, term
    result['issues'] = card_issues collection
    result['multiple-authors'] = card_multiple_authors collection
    result['multiple-degrees'] = card_multiple_degrees collection
    result['multiple-departments'] = card_multiple_departments collection
    result
  end

  def dashboard_tables(collection)
    result = {}
    result['status'] = table_status collection
    result['copyright'] = table_copyright collection
    result
  end

  def extract_terms(collection)
    collection.pluck(:grad_date).uniq.sort
  end

  def table_populate_defaults(data, values)
    values.each do |value|
      data[value] = '0' unless data[value]
    end
  end

  def table_status(collection)
    result = collection.group(:publication_status).count
    table_populate_defaults result, Thesis.publication_statuses
    {
      'title' => 'Thesis counts by publication status',
      'summary' => 'This table presents a summary of thesis records by their publication status. The second column '\
                   'gives the status, while the first column gives how many records have that status.',
      'column' => 'Publication status',
      'data' => result
    }
  end

  def table_copyright(collection)
    result = {}
    collection.group(:copyright).count.each do |record|
      if record[0].instance_of?(NilClass)
        result['Undefined'] = record[1]
      else
        result[record[0].holder] = record[1]
      end
    end
    table_populate_defaults result, Copyright.pluck(:holder)
    {
      'title' => 'Thesis counts by copyright',
      'summary' => 'This table presents a summary of thesis records by their copyright status. The second column '\
                   'names the copyright holder, while the first column shows how many records have that copyright.',
      'column' => 'Copyright holder',
      'data' => result
    }
  end
end
