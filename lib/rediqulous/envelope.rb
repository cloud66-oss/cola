module Rediqulous 
	class Envelope 
		attr_reader :message 
		attr_reader :timestamp 
		attr_reader :retries
		attr_reader :last_reason 
		attr_reader :version

		def initialize(message, version: 1, timestamp: Time.now, retries: 0, last_reason: nil)
			@message = message
			@timestamp = timestamp
			@retries = retries
			@last_reason = last_reason
			@version = version
		end

		def self.from_payload(payload)
			return nil if payload.nil? 
			
			obj = JSON.parse(payload)

			return Rediqulous::Envelope.new(
				obj['message'], 
				version: obj['version'],
				timestamp: Time.parse(obj['timestamp']),
				retries: obj['retries'],
				last_reason: obj['last_reason'])
		end

		def inc_retries(reason: nil)
			@retries = @retries + 1
			@last_reason = reason if reason
		end

		def to_json 
			{
				version: @version,
				message: @message,
				timestamp: @timestamp.iso8601,
				retries: @retries,
				last_reason: @last_reason
			}.to_json 
		end

	end
end