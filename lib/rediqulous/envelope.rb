module Rediqulous 
	class Envelope 
		attr_reader :message 
		attr_reader :timestamp 
		attr_reader :retries
		attr_reader :last_result 

		def initialize(message, timestamp: Time.now, retries: 0, last_result: nil)
			@message = message
			@timestamp = timestamp
			@retries = retries
			@last_result = last_result
		end

		def self.from_payload(payload)
			return nil if payload.nil? 
			
			obj = JSON.parse(payload)

			return Rediqulous::Envelope.new(
				obj['message'], 
				timestamp: obj['timestamp'],
				retries: obj['retries'],
				last_result: obj['last_result'])
		end

		def to_json 
			{
				message: @message,
				timestamp: @timestamp.iso8601,
				retries: @retries,
				last_result: @last_result
			}.to_json 
		end

	end
end