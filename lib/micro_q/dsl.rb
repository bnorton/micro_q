module MicroQ
  ##
  # Convenience methods for calling methods asynchronously
  # Adds async_perform by default
  #
  # Usage
  # class MyWorker
  #   worker :update, :queue => 'non-default'
  #
  #   def update
  #   end
  # end
  #
  # MyWorker.async_update
  # is the same as
  # MyWorker.new.async(:queue => 'non-default').update
  #
  module DSL
    def worker(*opts)
      self.class_eval do
        def self.microq_options
          @microq_options ||= { :methods => [:perform] }
        end
      end

      if Hash === opts.last
        self.microq_options.merge!(opts.pop)
      end

      async_methods = self.microq_options[:methods] |= opts.flatten

      self.class_eval do
        ##
        # For each of the methods given to the Object.worker method
        # define the async_ prefixed version for convenience
        #
        async_methods.each do |method|
          async_method = :"async_#{method}"
          define_singleton_method(async_method) do |*args|
            MicroQ::Proxy::Instance.new(
              microq_options.dup.merge(:class => self)
            ).send(method, *args)
          end unless respond_to?(async_method)
        end
      end
    end
  end
end

Object.send(:extend, MicroQ::DSL)
