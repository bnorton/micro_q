module MicroQ
  module Methods
    ##
    # Methods that are added to all Ruby Objects (as class methods).
    #
    # When processing class methods asynchronously, simply store
    # the calling class. The custom 'loader' describes that no
    # additional methods need be called to generate the callee of the
    # message invocation
    #
    module Class
      def async(options = {})
        MicroQ::Proxy::Class.new(
          options.merge(:class => self, :loader => {})
        )
      end
    end
  end
end

Object.send(:extend,  MicroQ::Methods::Class)
