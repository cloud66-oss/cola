module Cola 
	class Envelope 
		attr_reader :message 
		attr_reader :timestamp 
		attr_reader :retries
		attr_reader :last_reason 
		attr_reader :version
		attr_reader :uuid
		attr_accessor :ttl # in seconds

		def initialize(message, 
						version: 1, 
						timestamp: Time.now, 
						retries: 0, 
						last_reason: nil, 
						uuid: SecureRandom.uuid,
						ttl: 0)
			@message = message
			@timestamp = timestamp
			@retries = retries
			@last_reason = last_reason
			@version = version
			@uuid = uuid
			@ttl = ttl 
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
				ttl: obj['ttl'],
				last_reason: obj['last_reason'])
		rescue TypeError => exc 
			raise ::Cola::MessageError, 'malformed message'
		end

		def inc_retries(reason: nil)
			@retries = @retries + 1
			@last_reason = reason if reason
		end

		def expired?
			return false if self.ttl == 0

			return Time.now > self.timestamp + self.ttl 
		end

		def to_json 
			{
				version: @version,
				message: @message,
				timestamp: @timestamp.iso8601,
				retries: @retries,
				uuid: @uuid,
				ttl: @ttl, 
				last_reason: @last_reason
			}.to_json 
		end

	end
end