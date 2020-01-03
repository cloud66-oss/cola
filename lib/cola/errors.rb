# frozen_string_literal: true

module Cola
	class Error < StandardError; end
	class MessageError < Error; end 
	class RetryError < Error
		attr_reader :envelope
		attr_reader :inner_exception

		def initialize(envelope, inner_exception)
			@envelope = envelope
			@inner_exception = inner_exception
			super()
		end

		def to_s 
			"Retried #{@envelope.retries} times. Last known error was #{@envelope.last_reason}. UUID #{@envelope.uuid}"
		end
	end
  end
  