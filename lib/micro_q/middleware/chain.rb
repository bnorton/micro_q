require 'micro_q/middleware/server/retry'
require 'micro_q/middleware/server/connection'
require 'micro_q/middleware/server/timeout'

module MicroQ
  module Middleware
    ##
    # An Array wrapper that holds the class name of middlewares to call
    # around the execution of messages. The most basic middleware must
    # yield to the given block to allow the message to be invoked. Not
    # yielding causes the message to be dropped and not invoked.
    #
    # A minimal middleware:
    # class MyFunMiddleware
    #   def call(worker, message)
    #     # Do something fun here ...
    #     yield
    #     # More fun goes here ...
    #   end
    # end
    #
    class Chain
      ##
      # Middleware chain that is run around execution of messages.
      #   -- If halted, the message will not be invoked.
      def server
        @server ||= Server.new
      end

      ##
      # Middleware chain that is run around message push.
      #   -- If halted, the message will not enter the queue.
      #
      def client
        @client ||= Client.new
      end

      class Base
        attr_reader :entries

        def initialize
          clear
        end

        ##
        # Add any number of entries to the middleware chain
        #
        def add(*items)
          @entries.concat(items.flatten).uniq!
        end

        def add_before(before, *items)
          remove(*items)
          @entries.insert(@entries.index(before), *items).uniq! if items.any?
        end

        def add_after(after, *items)
          remove(*items)
          @entries.insert(@entries.index(after)+1, *items).uniq! if items.any?
        end

        ##
        # Remove any number of entries from the middleware chain
        #
        def remove(*items)
          @entries.tap do
            items.flatten.each {|item| @entries.delete(item) }
          end
        end

        def clear
          @entries = []
        end

        ##
        # Traverse the middleware chain by recursing until we reach the
        # end of the chain and are able to invoke the given block. The block
        # represents a message push (client) or a message invocation (server).
        #
        # It is, however very generic and can be used as middleware around anything.
        #
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
            MicroQ::Middleware::Server::Timeout,
            MicroQ::Middleware::Server::Retry,
            MicroQ::Middleware::Server::Connection
          ]
        end
      end

      class Client < Base
      end
    end
  end
end
