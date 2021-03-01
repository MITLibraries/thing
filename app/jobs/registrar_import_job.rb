class RegistrarImportJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Do something later
    puts "\n=======================================\nHello, world!\n\n"
    puts args
  end
end
