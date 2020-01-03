# frozen_string_literal: true

require 'spec_helper'
require 'timeout'

describe Cola do
  before(:all) do
    @redis = Redis.new
    @queue = Cola::Queue.new
    @queue.destroy
  end

  after(:all) do
    @queue.destroy
  end

  it 'should create a new redis-queue object' do
    queue = Cola::Queue.new
    queue.class.should == Cola::Queue
  end

  it 'should add an element to the queue' do
    @queue << 'a'
    @queue.len.should be == 1
  end

  it 'should return an element from the queue' do
    message = @queue.pop(true)
    message.should be == 'a'
  end

  it 'should remove the element from bp_queue if commit is called' do
    @redis.llen(@queue.process_queue_name).should be == 1
    @queue.commit
    @redis.llen(@queue.process_queue_name).should be == 0
  end

  it 'should implement fifo pattern' do
    @queue.destroy
	payload = %w[a b c d e]
    payload.each { |e| @queue << e }
    test = []
    while (e = @queue.pop(true))
      test << e
    end
    payload.should be == test
  end

  it 'should remove all of the elements from the main queue' do
    %w[a b c d e].each { |e| @queue << e }
    @queue.len.should be > 0
    @queue.pop(true)
    @queue.destroy
    @redis.llen(@queue.process_queue_name).should be == 0
  end

  it 'should reset queues content' do
    @queue.destroy
    @redis.llen(@queue.process_queue_name).should be == 0
  end

  it 'should keep uuid' do 
	@queue.destroy
	@queue << 'a'

	msg = @queue.pop_with_envelope(true)
	expect(msg.uuid).not_to be_nil
	uuid = msg.uuid

	@queue.refill

	msg = @queue.pop_with_envelope(true)
	expect(uuid).to eq(msg.uuid)
  end

  it 'should prcess a message' do
    @queue << 'a'
    @queue.process(true) { |m| m.should be == 'a'; true }
  end

  it 'should work with the timeout parameters' do
    @queue.destroy
    2.times { @queue << rand(100) }
    is_ok = true
    begin
      Timeout.timeout(3) do
        @queue.process(false, timeout: 2) { |_m| true }
      end
    rescue Timeout::Error => _e
      is_ok = false
    end

    is_ok.should be_truthy
  end

  it 'should handle JSON exceptions' do 
	@queue.destroy
	@redis.lpush(@queue.queue_name, 's')

	expect { @queue.pop(true) }.to raise_error(JSON::ParserError)

	@queue.destroy
	@redis.lpush(@queue.queue_name, '{ "foo": 1 }')
	expect { @queue.pop(true) }.to raise_error(Cola::MessageError)
  end

  it 'should push to deadletter queue' do 
	queue = Cola::Queue.new(retries: 3)
	queue << 'a'

	expect do 
		queue.process(true) do |item|
			raise 'some error'
		end
	end.to raise_error(::Cola::RetryError, /Retried 3 times/)

	expect(queue.deadletter_count).to eq 1
  end

  it 'should honor the timeout param in the initializer' do
    redis = Redis.new
    queue = Cola::Queue.new(redis: redis, timeout: 2)
    queue.destroy

    is_ok = true
    begin
      Timeout.timeout(4) do
        queue.pop
      end
    rescue Timeout::Error => _e
      is_ok = false
    end
    queue.destroy
    is_ok.should be_truthy
  end

  it 'should retry on valid errors' do 
	queue = Cola::Queue.new(retries: 3)
	queue << 'a'

	expect do 
		queue.process(true) do |item|
			raise 'some error'
		end
	end.to raise_error(::Cola::RetryError, /Retried 3 times/)
  end
end
