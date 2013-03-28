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
        client.messages.tap do |messages|
          @manager.receive_messages!(messages) if messages.any?
        end

        after(2) { start }
      end

      private

      def client
        @client ||= MicroQ::SqsClient.new(name)
      end
    end
  end
end
