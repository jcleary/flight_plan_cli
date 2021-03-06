require 'webmock/rspec'
require 'fakefs/spec_helpers'
require 'flight_plan_cli'

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
