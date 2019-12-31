# frozen_string_literal: true

require 'rediqulous'

redis = Redis.new

queue = Rediqulous.new(redis: redis)
queue.clear true

100.times { queue << rand(100) }

queue.process(true) { |m| puts m }
