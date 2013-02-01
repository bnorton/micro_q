module MicroQ
  module Worker
    class Default
      include Celluloid

      def perform(worker)
        klass = MicroQ::Util.constantize(worker['class']).new
        method = worker['method'] || 'perform'
        args = worker['args']

        value = nil

        MicroQ.config.middleware.server.call(klass, worker) do
          value = klass.send(method, *args)
        end

        value
      end
    end
  end
end
