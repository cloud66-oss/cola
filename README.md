<img src="http://cdn2-cloud66-com.s3.amazonaws.com/images/oss-sponsorship.png" width=150/>

# Cola

---

Cola is a simple distributed, transactional queue gem for Ruby backed by Redis. It uses Redis lists to provide its functionality with minimal additions. Cola supports transactions, retries, deadletter queues and timeouts. This gem is based on https://github.com/taganaka/redis-queue

## Install

Run

```bash
gem install rb-cola
```

or add this to your `Gemfile`

```ruby
gem 'rb-cola'
```

## Usage

Create a queue, push and pop messages to and from the queue:

```ruby
q = ::Cola::Queue.new
q.push("message")
message = q.pop
q.commit
```

See the files under `examples` folder for more information.

### Push

You can push messages onto the queue using `push` or `<<`:

```ruby
queue << message
queue.push(message)
queue.push(another_message, ttl: 30) # this message will expire in 30 seconds
```

### Pop

You can pull the messages from the queue with blocking or non-blocking actions. Blocking actions will wait until a message is available to pop. Non-blocking actions will return `nil` is no message is available.

### Envelope

Each message is stored in an envelope when put on the queue. `pop` and `process` return the message itself when called. However, you can use `pop_with_envelope` to get the entire envelope.

Attribute | Description | Default
---|---|---
message | The message | `nil`
timestamp | Message timestamp | Timestamp of the push
retries | Number of times the message has been retried | 0
last_reason | The reason for the last retry failure | `nil`
version | Envelope version | `0`
uuid | Unique ID of the message | Automatically generated
ttl | Time to live | `0`

### Retries

By default, if a pop fails, the message is lost and an exception is raised. This can be changed so Cola retries the message more than once. See `options` for more info. This is most useful when used with the `process` function in case an exception is raised within the process block.

### Deadletter Queue

In case of multiple failures, the message can be pushed to a deadletter queue for further manual inspection. This is disabled by default.

### Message Expiry

When pushing messages onto the queue, you can assign them a Time to Live (ttl). Messages will expire after their ttl is passed and they are not picked up for processing.

## Options

When creating a queue, you can use the following options:

Option | Description | Default
---|---|---
redis | Redis instance to use | Using the current redis instance
deadletter | Support deadletter queue | `false`
queue_name | Set the queue name | Random queue name
timeout | Message timeout | `0` (No timeout)
retries | Number of retries | `0` (No retries)

Example:

```ruby
q = ::Cola::Queue.new(timeout: 10, redis: @some_redis_instance)
```
