namespace :metadata do
  desc 'Generate a catalog export of a single published thesis for debugging'
  task :catalog_export_thesis, [:thesis_id] => :environment do |_t, args|
    if args.thesis_id.blank?
      puts 'No thesis ID provided.'
      next
    end

    thesis = Thesis.find(args.thesis_id)

    if thesis.publication_status == 'Published'
      catalog_exporter = CatalogExporter.new(thesis)
      json_data = catalog_exporter.to_hash

      puts "Catalog Export for Thesis #{args.thesis_id}:"
      puts JSON.pretty_generate(json_data)
    else
      puts "Thesis status of #{thesis.publication_status} cannot be exported. Only published theses can be exported."
    end
  end

  # This task is recommended for local development only. On Heroku (or other ephemeral filesystems),
  # files saved to disk will be deleted when the dyno restarts, making them inaccessible.
  desc 'Generate a catalog export batch for a specific term (e.g., "2024-June") and save to temp file'
  task :catalog_export_batch, %i[term output_file] => :environment do |_t, args|
    if args.term.blank?
      puts 'Usage: rake metadata:catalog_export_batch["2024-June","output.json"]'
      puts 'Term format: YYYY-Month (e.g., 2024-June, 2024-September)'
      next
    end

    year, month_name = args.term.split('-')
    query_date = Date.parse("1 #{month_name} #{year}")

    output_file = args.output_file || Rails.root.join("tmp/catalog_export_#{args.term}_#{DateTime.now.utc.strftime('%H_%M')}.json").to_s

    theses = Thesis.published.where(grad_date: query_date.all_month)

    if theses.any?
      catalog_batch = CatalogBatch.new(theses, File.basename(output_file))
      catalog_file = catalog_batch.build
      FileUtils.cp(catalog_file.path, output_file)
      catalog_file.close!
      puts "Exported #{theses.count} theses to: #{output_file}"
    else
      puts "No published theses found for #{args.term}"
    end
  end
end
