module MicroQ
  module Proxy
    class Instance < Base
      def respond_to?(method)
        super || klass.new.respond_to?(method)
      end
    end
  end
end
