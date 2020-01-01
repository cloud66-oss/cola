# frozen_string_literal: true

require 'spec_helper'
require 'timeout'

describe Rediqulous do
  before(:all) do
    @redis = Redis.new
    @queue = Rediqulous::Queue.new
    @queue.destroy
  end

  after(:all) do
    @queue.destroy
  end

  it 'should create a new redis-queue object' do
    queue = Rediqulous::Queue.new
    queue.class.should == Rediqulous::Queue
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

  it 'should honor the timeout param in the initializer' do
    redis = Redis.new
    queue = Rediqulous::Queue.new(redis: redis, timeout: 2)
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
end
