module MicroQ
  module Methods
    module SharedMethods
      def method_missing(method, *other)
        super unless /((.+)\_async$)/ === method

        name = $2

        # Define the method and call through.
        if name && respond_to?(name)
          define_singleton_method method do |*args|
            async.send(name, *args)
          end

          async.send(name, *other)
        else
          super
        end
      end
    end
  end
end

require 'micro_q/methods/class'
require 'micro_q/methods/instance'
require 'micro_q/methods/active_record'
