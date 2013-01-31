require 'micro_q/middleware/server/retry'

module MicroQ
  module Middleware
    class Chain
      def server
        @server ||= Server.new
      end

      def client
        @client ||= Client.new
      end

      class Base
        attr_reader :entries

        def initialize
          @entries = []
        end

        def add(*items)
          items.flatten.each {|item| @entries.push(item) }
        end

        def remove(*items)
          items.flatten.each {|item| @entries.delete(item) }
        end
      end

      class Server < Base
        def initialize
          @entries = [
            MicroQ::Middleware::Server::Retry
          ]
        end
      end

      class Client < Base

      end
    end
  end
end
