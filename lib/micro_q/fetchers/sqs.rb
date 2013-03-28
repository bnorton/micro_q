module MicroQ
  module Fetcher
    class Sqs
      include Celluloid
      attr_reader :name

      def initialize(name, manager)
        @name = name.to_s
        @manager = manager
      end

      def start
        defer do
          client.messages.tap do |messages|
            @manager.receive_messages!(messages) if messages.any?
          end
        end

        after(2) { start }
      end

      def add_message(message, time=nil)
        message['run_at'] = time.to_f if time

        defer do
          client.messages_create(message)
        end
      end

      private

      def client
        @client ||= MicroQ::SqsClient.new(name)
      end
    end
  end
end
