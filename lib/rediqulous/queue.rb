# frozen_string_literal: true

require 'byebug'

module Rediqulous 
	class Queue
		attr_reader :queue_name
		attr_reader :process_queue_name

		def initialize(options = {})
			@redis = options[:redis] || Redis.current
			prefix = options[:prefix] || "rq_"
			now = Time.new
			@queue_name = prefix + now.to_i.to_s
			@process_queue_name = prefix + "process_" + now.to_i.to_s
			@timeout = options[:timeout] ||= 0
			@retried = options[:retries] ||= 0
			@queue_ttl = options[:queue_ttl] ||= 0
		end

		def length
			@redis.llen @queue_name
		end

		# not thread safe
		def clear(clear_process_queue = false)
			@redis.del @queue_name
			@redis.del @process_queue_name if clear_process_queue
		end

		def empty?
			length <= 0
		end

		def processing_count 
			@redis.llen @process_queue_name
		end

		def push(obj)
			wrapped = Rediqulous::Envelope.new(obj)
			@redis.lpush(@queue_name, wrapped.to_json)
			@redis.expire @queue_name, @queue_ttl if @queue_ttl != 0
		end

		def pop(non_block = false)
			obj = pop_with_envelope(non_block)	
			return nil if obj.nil?

			return obj.message 
		end

		def commit
			@redis.lpop(@process_queue_name)
			return true 
		end

		def process(non_block= false, timeout = nil)
			@timeout = timeout unless timeout.nil?
			loop do
				obj = pop(non_block)
				ret = yield obj if block_given?
				commit if ret
				break if obj.nil? || (non_block && empty?)
			end
		end

		# not thread safe
		def refill
			while (obj = @redis.lpop(@process_queue_name))
				@redis.rpush(@queue_name, obj)
			end
			true
		end

		alias size  length
		alias shift pop
		alias <<    push

		private 

		def pop_with_envelope(non_block = false)
			obj = non_block ? @redis.rpoplpush(@queue_name, @process_queue_name) : @redis.brpoplpush(@queue_name, @process_queue_name, @timeout)
			@redis.expire @process_queue_name, @queue_ttl if @queue_ttl != 0
			return Rediqulous::Envelope.from_payload(obj)
		end

	end
end