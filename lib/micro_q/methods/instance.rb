module MicroQ
  module Methods
    module Instance
      include MicroQ::Methods::SharedMethods

      def async
        MicroQ::Proxy::Instance.new(:class => self.class)
      end
    end
  end
end

Object.send(:include, MicroQ::Methods::Instance)
