# frozen_string_literal: true

require_relative "../config/environment"

loop do
  SendCapacityService.new.call
end
