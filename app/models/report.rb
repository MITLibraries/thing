class Report
  delegate :url_helpers, to: 'Rails.application.routes'

  def card_departments(collection)
    {
      'value' => collection.joins(:department).pluck(:name_dw).uniq.count,
      'label' => 'department(s) have transferred files'
    }
  end

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

  def data_category_copyright_holder
    category = []
    rows = populate_category(Copyright.pluck(:holder))
    Thesis.all.joins(:copyright).group(:holder).group(:grad_date).count.each do |item|
      rows[item[0][0]][item[0][1]] = item[1]
    end
    rows.each do |row|
      category.push({
                      label: row[0],
                      data: pad_terms(row[1])
                    })
    end
    category
  end

  def data_category_department
    category = []
    rows = populate_category(Department.pluck(:name_dw))
    Thesis.all.joins(:departments).group(:name_dw).group(:grad_date).count.each do |item|
      rows[item[0][0]][item[0][1]] = item[1]
    end
    rows.each do |row|
      category.push({
                      label: row[0],
                      data: pad_terms(row[1])
                    })
    end
    category
  end

  def data_category_license
    category = []
    rows = populate_category(License.pluck(:display_description))
    Thesis.all.joins(:license).group(:display_description).group(:grad_date).count.each do |item|
      rows[item[0][0]][item[0][1]] = item[1]
    end
    rows.each do |row|
      category.push({
                      label: row[0],
                      data: pad_terms(row[1])
                    })
    end
    category
  end

  def data_category_publication_status
    category = []
    rows = populate_category(Thesis.publication_statuses)
    Thesis.all.group(:publication_status).group(:grad_date).count.each do |item|
      rows[item[0][0]][item[0][1]] = item[1]
    end
    rows.each do |row|
      category.push({
                      label: row[0],
                      data: pad_terms(row[1])
                    })
    end
    category
  end

  def data_files_attached_to_theses
    {
      label: 'Files attached to theses',
      data: pad_terms(Thesis.all.joins(:files_attachments).group(:grad_date).count)
    }
  end

  def data_issues
    {
      label: 'Flagged with issues',
      data: pad_terms(Thesis.all.group(:grad_date).where('issues_found = ?', true).count)
    }
  end

  def data_multiple_authors
    row_data = {}
    query = <<~SQL
      SELECT t.grad_date, count(t.id) as pop
      FROM (
        SELECT theses.id, theses.grad_date, count(theses.id) as authors
        FROM theses
        INNER JOIN authors a on theses.id = a.thesis_id
        GROUP BY theses.id
        HAVING count(a.id) > 1
      ) AS t
      GROUP BY t.grad_date;
    SQL
    ActiveRecord::Base.connection.exec_query(query).each do |item|
      row_data[Date.parse(item['grad_date'])] = item['pop']
    end
    {
      label: 'Multiple authors',
      data: pad_terms(row_data)
    }
  end

  def data_multiple_degrees
    row_data = {}
    query = <<~SQL
      SELECT t.grad_date, count(t.id) as pop
      FROM (
        SELECT theses.id, theses.grad_date, count(theses.id) as authors
        FROM theses
        INNER JOIN degree_theses link ON theses.id = link.thesis_id
        INNER JOIN degrees d on link.degree_id = d.id
        GROUP BY theses.id
        HAVING count(d.id) > 1
      ) AS t
      GROUP BY t.grad_date;
    SQL
    ActiveRecord::Base.connection.exec_query(query).each do |item|
      row_data[Date.parse(item['grad_date'])] = item['pop']
    end
    {
      label: 'Multiple degrees',
      data: pad_terms(row_data)
    }
  end

  def data_multiple_departments
    row_data = {}
    query = <<~SQL
      SELECT t.grad_date, count(t.id) as pop
      FROM (
        SELECT theses.id, theses.grad_date, count(theses.id) as authors
        FROM theses
        INNER JOIN department_theses link ON theses.id = link.thesis_id
        INNER JOIN departments d on link.department_id = d.id
        GROUP BY theses.id
        HAVING count(d.id) > 1
      ) AS t
      GROUP BY t.grad_date;
    SQL
    ActiveRecord::Base.connection.exec_query(query).each do |item|
      row_data[Date.parse(item['grad_date'])] = item['pop']
    end
    {
      label: 'Multiple departments',
      data: pad_terms(row_data)
    }
  end

  def data_thesis_records
    {
      label: 'Thesis records',
      data: pad_terms(Thesis.all.group(:grad_date).count)
    }
  end

  def data_theses_with_files
    row_data = {}
    query = <<~SQL
      SELECT t.grad_date, count(distinct t.id) AS pop
      FROM theses t
      INNER JOIN active_storage_attachments a ON t.id = a.record_id
      WHERE a.record_type = 'Thesis'
      GROUP BY t.grad_date;
    SQL
    ActiveRecord::Base.connection.exec_query(query).each do |item|
      row_data[Date.parse(item['grad_date'])] = item['pop']
    end
    {
      label: 'Theses with files',
      data: pad_terms(row_data)
    }
  end

  def departments_data(collection)
    result = {}
    result['departments'] = card_departments collection
    result
  end

  def departments_lists(collection)
    result = {}
    result['no-transfers'] = list_no_transfers collection
    result
  end

  def extract_terms(collection)
    collection.pluck(:grad_date).uniq.sort
  end

  def index_data
    output = {}
    output['Summary'] = []
    output['Summary'].push data_thesis_records
    output['Summary'].push data_theses_with_files
    output['Summary'].push data_files_attached_to_theses
    output['Summary'].push data_issues
    output['Summary'].push data_multiple_authors
    output['Summary'].push data_multiple_degrees
    output['Summary'].push data_multiple_departments
    output['Publication status'] = []
    output['Publication status'].push(*data_category_publication_status)
    output['Copyright'] = []
    output['Copyright'].push(*data_category_copyright_holder)
    output['License'] = []
    output['License'].push(*data_category_license)
    output['Departments'] = []
    output['Departments'].push(*data_category_department)
    output
  end

  def list_no_transfers(collection)
    {
      'title' => 'Departments with no transferred files',
      'list' => Department.where.not(\
        id: collection.joins(:department).pluck('departments.id').uniq\
      ).pluck(:name_dw).uniq
    }
  end

  def list_unattached_files(collection)
    result = []
    collection.joins(:files_attachments).order(:grad_date).uniq.each do |record|
      record.files.where(purpose: nil).each do |file|
        result.push(file)
      end
    end
    result
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

  def table_department(collection)
    result = collection.joins(:departments).group(:name_dw).count
    table_populate_defaults result, Department.pluck(:name_dw)
    {
      'title' => 'Thesis counts by department',
      'summary' => 'This table presents a summary of which departments have how many theses for the selected term. '\
                   'The second column shows the programs at MIT which grant degrees, while the first column shows how '\
                   'many theses have come from that program during this period.',
      'note' => 'Please note: total theses indicated by this table may be greater than the overall number of theses '\
                'because some theses have multiple departments.',
      'column' => 'Department',
      'data' => result
    }
  end

  def table_license(collection)
    result = {}
    collection.group(:license).count.each do |record|
      if record[0].instance_of? NilClass
        result['Undefined'] = record[1]
      else
        result[record[0].display_description] = record[1]
      end
    end
    table_populate_defaults result, License.pluck(:display_description)
    {
      'title' => 'Thesis counts by Creative Commons license',
      'summary' => 'This table presents a summary of which Creative Commons license has been selected by the author, '\
                   'for those theses for which the author retains copyright. The second column gives the specific CC '\
                   'license selected, while the first column shows how many theses have selected it.',
      'note' => 'Please note: theses for which the author does not claim copyright will have "Undefined" in this '\
                'field.',
      'column' => 'License',
      'data' => result
    }
  end

  def table_hold(collection)
    result = collection.joins(:hold_sources).group(:source).count
    table_populate_defaults result, HoldSource.pluck(:source)
    {
      'title' => 'Hold counts by hold source',
      'column' => 'Source',
      'data' => result
    }
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

  def term_data(collection, term)
    result = {}
    result['overall'] = card_overall collection, term
    result['files'] = card_files collection, term
    result['issues'] = card_issues collection
    result['multiple-authors'] = card_multiple_authors collection
    result['multiple-degrees'] = card_multiple_degrees collection
    result['multiple-departments'] = card_multiple_departments collection
    result
  end

  def term_tables(collection)
    result = {}
    result['status'] = table_status collection
    result['copyright'] = table_copyright collection
    result['license'] = table_license collection
    result['department'] = table_department collection
    result['hold'] = table_hold collection
    result
  end

  private

  def pad_terms(data)
    # Given a hash of data for a single row of the reporting table, this will compare the data to the set of all
    # terms, adding zero values where needed to the simple iterator in the view will place them accurately.
    # Sample input (missing some terms)
    # {Mon, 01 Feb 2021=>1,
    #  Sat, 01 May 2021=>4,
    #  Tue, 01 Jun 2021=>2,
    #  Thu, 01 Sep 2022=>2}
    # Sample output (now with a value for every term)
    # {Fri, 01 Feb 1861=>0,
    #  Mon, 01 Feb 2021=>1,
    #  Sat, 01 May 2021=>4,
    #  Tue, 01 Jun 2021=>2,
    #  Sun, 01 May 2022=>0,
    #  Thu, 01 Sep 2022=>2}
    output = {}
    Thesis.pluck(:grad_date).uniq.sort.each do |term|
      output[term] = 0
      output[term] = data[term] if data.include? term
    end
    output
  end

  def populate_category(array)
    # This builds out the initial set of a category of rows, based on a provided array (like
    # Thesis.publication_statuses).
    # Sample input (array of publication statuses)
    # ["Not ready for publication", "Publication review", "Pending publication", "Published"]
    # Sample output (hash ready for population)
    # {"Not ready for publication"=>{}, "Publication review"=>{}, "Pending publication"=>{}, "Published"=>{}}
    output = {}
    array.each do |item|
      output[item] = {}
    end
    output
  end
end
