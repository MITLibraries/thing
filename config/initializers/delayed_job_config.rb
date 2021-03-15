Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.max_attempts = 3
Delayed::Worker.read_ahead = 10
Delayed::Worker.default_queue_name = 'default'
Delayed::Worker.delay_jobs = !Rails.env.test?
Delayed::Worker.raise_signal_exceptions = :terms