Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 5
Delayed::Worker.max_attempts = 1
Delayed::Worker.max_run_time = 10.seconds
Delayed::Worker.read_ahead = 10