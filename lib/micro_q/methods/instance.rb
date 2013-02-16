module MicroQ
  module Methods
    ##
    # Methods that are added to all Ruby Objects (as instance methods).
    #
    # When processing instance methods asynchronously, simply store
    # the calling instances' class name. No custom 'loader' is needed but
    # since the worker defines a default 'loader'. An example loader for
    # a messages invoked as MyWorker.new.perform(123), is
    # :loader => { :method => 'new', :args => []} which happens to be
    # what the default worker does.
    #
    module Instance
      def async(options = {})
        MicroQ::Proxy::Instance.new(
          options.merge(:class => self.class)
        )
      end
    end
  end
end

Object.send(:include, MicroQ::Methods::Instance)
