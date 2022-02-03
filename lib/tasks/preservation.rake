namespace :preservation do
  desc 'Sends a single thesis to preservation'
  task :preserve_thesis_by_id, [:thesis_id] => :environment do |_t, args|
    if args.thesis_id
      Rails.logger.info("Attempting to send #{args.thesis_id} to preservation...")
      thesis = Thesis.find(args.thesis_id)

      # Only published theses may be sent to preservation. We already check for this in SubmissionInformationPackage
      # validations, but double-checking here to save potential confusion.
      if thesis.publication_status == 'Published'
        PreservationSubmissionJob.perform_now(thesis)
      else
        Rails.logger.info("Thesis status of #{thesis.publication_status} cannot be preserved.")
      end
    else
      Rails.logger.info('No thesis ID provided.')
    end
  end
end
