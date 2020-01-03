# frozen_string_literal: true

require 'cola'

redis = Redis.new

queue = Cola.new(redis: redis)
queue.clear true

100.times { queue << rand(100) }

queue.process(true) { |m| puts m }
