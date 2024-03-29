namespace :cache do
  desc 'Reset counter cache associated with the thesis model'
  task reset_thesis_counters: :environment do
    Thesis.all.each do |thesis|
      Thesis.reset_counters(thesis.id, :authors)
    end
    Rails.logger.info('Thesis model counters have been updated.')
  end

  desc 'Reset counter cache associated with the transfer model'
  task reset_transfer_counters: :environment do
    Rails.logger.info('Transfer counters update is starting.')
    # The counter caches are non-standard in this model and are updated via a before_save hook so we update
    # them by calling save.
    Transfer.find_each(&:save)
    Rails.logger.info('Transfer counters have been updated.')
  end
end
