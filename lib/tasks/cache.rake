namespace :cache do
  desc 'Reset counter cache associated with the thesis model'
  task reset_thesis_counters: :environment do
    Thesis.all.each do |thesis|
      Thesis.reset_counters(thesis.id, :authors)
    end
    Rails.logger.info('Thesis model counters have been updated.')
  end
end
