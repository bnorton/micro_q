module MicroQ
  class SqsClient
    attr_reader :url

    def initialize(name)
      @name = "#{MicroQ.config.env}_#{name}"
      @url  = client.create_queue(:queue_name => @name)[:queue_url]
    end

    def messages
      response = client.receive_message(
        :queue_url => url,
        :wait_time_seconds => 10,
        :max_number_of_messages => 10,
        :visibility_timeout => 5 * 60
      )

      ((response && response[:messages]) || []).collect do |message|
        JSON.parse(message[:body]).merge(
          'sqs_id' => message[:message_id],
          'sqs_handle' => message[:receipt_handle],
          'sqs_queue' => url
        )
      end
    end

    def messages_create(message)
      attrs = {
        :queue_url => url,
        :message_body => message.to_json
      }

      attrs[:delay_seconds] = (message['run_at'].to_i - Time.now.to_i) if message.key?('run_at')

      client.send_message(attrs)[:message_id]
    end

    private

    def client
      @client ||= AWS::SQS::Client.new(
        :access_key_id => MicroQ.config.aws[:key],
        :secret_access_key => MicroQ.config.aws[:secret]
      )
    end
  end
end
