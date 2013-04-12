module MicroQ
  module Fetcher
    class Sqs
      include Celluloid
      attr_reader :name

      def initialize(name, manager)
        @name = name.to_s
        @manager = manager
      end

      ##
      # Long poll the SQS messages API and if there are messages
      # then fetch more right away. Send messages to the manager
      # when they return from the API
      def start
        defer do
          client.messages.tap do |messages|
            @manager.receive_messages!(messages) if messages.any?
          end
        end

        after(SHORT_DELAY) { start }
      end

      ##
      # Add the message to the sqs queue
      # Respect the maximum amount of time that a message can
      # be delayed (900 seconds).
      #
      def add_message(message, time=nil)
        message['run_at'] = [time.to_f, (Time.now + 900).to_i].min if time

        defer do
          client.messages_create(message)
        end
      end

      def remove_message(message)
        defer do
          client.messages_delete(message)
        end
      end

      private

      def client
        @client ||= MicroQ::SqsClient.new(name)
      end

      SHORT_DELAY = 2
    end
  end
end
