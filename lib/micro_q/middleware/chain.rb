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
          @entries.concat(items.flatten).uniq!
        end

        def remove(*items)
          @entries.tap do
            items.flatten.each {|item| @entries.delete(item) }
          end
        end

        def call(*args, &block)
          chain = (index = -1) && -> {
            (index += 1) == entries.length ?
              block.call : entries.at(index).new.call(*args, &chain)
          }

          chain.call
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
