module MicroQ
  module Methods
    module Class
      extend MicroQ::Methods::SharedMethods

      def async
        MicroQ::Proxy::Class.new(:class => self)
      end

    end
  end
end

Object.send(:extend,  MicroQ::Methods::Class)
