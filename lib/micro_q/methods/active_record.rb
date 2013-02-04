module MicroQ
  module Methods
    module ActiveRecord
      def async
        options = {
          :class => self.class,
          :loader => {
            :method => 'find',
            :args => [id]
          }
        }

        MicroQ::Proxy::Instance.new(options)
      end
    end
  end
end

MicroQ::Util.safe_require 'active_record'
if defined?(ActiveRecord::Base)
  ActiveRecord::Base.send(:include, MicroQ::Methods::ActiveRecord)
end
