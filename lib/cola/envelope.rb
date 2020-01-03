module Cola 
	class Envelope 
		attr_reader :message 
		attr_reader :timestamp 
		attr_reader :retries
		attr_reader :last_reason 
		attr_reader :version
		attr_reader :uuid

		def initialize(message, version: 1, timestamp: Time.now, retries: 0, last_reason: nil, uuid: SecureRandom.uuid)
			@message = message
			@timestamp = timestamp
			@retries = retries
			@last_reason = last_reason
			@version = version
			@uuid = uuid
		end

		def self.from_payload(payload)
			return nil if payload.nil? 
			
			obj = JSON.parse(payload)

			return Cola::Envelope.new(
				obj['message'], 
				version: obj['version'],
				timestamp: Time.parse(obj['timestamp']),
				retries: obj['retries'],
				uuid: obj['uuid'],
				last_reason: obj['last_reason'])
		rescue TypeError => exc 
			raise ::Cola::MessageError, 'malformed message'
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
				uuid: @uuid,
				last_reason: @last_reason
			}.to_json 
		end

	end
end