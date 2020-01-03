# frozen_string_literal: true
module Cola 
	class Queue
		attr_reader :queue_name
		attr_reader :process_queue_name
		attr_reader :deadletter_queue_name

		def initialize(options = {})
			@redis = options[:redis] || Redis.current
			prefix = options[:prefix] || "rq_"
			@deadletter = options[:deadletter] # default is false
			if options[:queue_name] 
				@queue_name = prefix + options[:queue_name]
				@process_queue_name = prefix + "process_" + options[:queue_name]
				@deadletter_queue_name = prefix + "deadletter_" + options[:queue_name]
			else
				now = Time.new.to_i
				@queue_name = prefix + now.to_s
				@process_queue_name = prefix + "process_" + now.to_s
				@deadletter_queue_name = prefix + "deadletter_" + now.to_s
			end

			@timeout = options[:timeout] ||= 0
			@retries = options[:retries] ||= 0
		end

		# returns the count of the items on the queue. 
		# note that this returns the total number which might include expired messages
		def len
			@redis.llen @queue_name
		end

		def flush_processing
			@redis.del @process_queue_name
		end

		def flush
			@redis.del @queue_name
		end

		def flush_deadletter
			@redis.del @deadletter_queue_name
		end

		# not thread safe
		def destroy
			flush_processing
			flush
			flush_deadletter
		end

		def empty?
			len <= 0
		end

		def processing_count 
			@redis.llen @process_queue_name
		end

		def deadletter_count 
			@redis.llen @deadletter_queue_name
		end

		def push(obj, ttl: 0)
			if obj.is_a? Cola::Envelope
				wrapped = obj
			else 				
				wrapped = Cola::Envelope.new(obj)
				wrapped.ttl = ttl
			end
		
			@redis.lpush(@queue_name, wrapped.to_json)
			return wrapped
		end

		def pop(non_block = false, timeout: @timeout)
			obj = pop_with_envelope(non_block, timeout: timeout)	
			return nil if obj.nil?

			return obj.message 
		end

		def commit
			@redis.lpop(@process_queue_name)
			return true 
		end

		def process(non_block = false, timeout: @timeout)
			loop do
				obj = pop_with_envelope(non_block, timeout: timeout)
				ret = yield obj.message if !obj.nil? && block_given?
				commit if ret
				break if obj.nil? || (non_block && empty?)
			rescue => exc 
				raise if obj.nil? 
				# requeue if we should retry and it's not done 
				if @retries != 0
					if obj.retries < @retries
						obj.inc_retries(reason: exc.message)
						push(obj)
					else 
						mark_as_deadletter(obj)
						raise Cola::RetryError.new(obj, exc)
					end
				else 
					mark_as_deadletter(obj)
					raise 
				end
			end
		end

		# not thread safe
		def refill
			while (obj = @redis.lpop(@process_queue_name))
				@redis.rpush(@queue_name, obj)
			end
			true
		end

		alias << push

		def pop_with_envelope(non_block = false, timeout: @timeout)
			obj = non_block ? @redis.rpoplpush(@queue_name, @process_queue_name) : @redis.brpoplpush(@queue_name, @process_queue_name, timeout)

			env = Cola::Envelope.from_payload(obj)
			return env if env.nil? 

			if env.expired? 
				commit
				return nil
			else
				return env
			end
		end

		private 

		def mark_as_deadletter(obj) 
			@redis.lpush(@deadletter_queue_name, obj.to_json)
		end

	end
end