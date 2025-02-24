# Be sure to restart your server when you modify this file.
#
# This file eases your Rails 7.1 framework defaults upgrade.
#
# Uncomment each configuration one by one to switch to the new default.
# Once your application is ready to run with all new defaults, you can remove
# this file and set the `config.load_defaults` to `7.1`.
#
# Read the Guide for Upgrading Ruby on Rails for more info on each option.
# https://guides.rubyonrails.org/upgrading_ruby_on_rails.html

###
# Run `after_commit` and `after_*_commit` callbacks in the order they are defined in a model.
# This matches the behaviour of all other callbacks.
# In previous versions of Rails, they ran in the inverse order.
#++
Rails.application.config.active_record.run_after_transaction_callbacks_in_order_defined = false
