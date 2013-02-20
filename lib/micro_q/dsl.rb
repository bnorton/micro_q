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
    ##
    # For each of the methods given to the Object.worker method
    # define the async_ prefixed version for convenience
    #
    def self.attach_async_methods(target, opts)
      target.class_eval do
        (target.microq_options[:methods] |= opts.flatten).each do |method|
          target.define_singleton_method(:"async_#{method}") do |*args|
            MicroQ::Proxy::Instance.new(
              target.microq_options.dup.merge(:class => self)
            ).send(method, *args)
          end unless respond_to?(:"async_#{method}")
        end
      end
    end

    module ClassMethods
      def worker(*opts)
        self.class_eval do
          def self.microq_options
            @microq_options ||= { :methods => [:perform] }
          end
        end

        if Hash === opts.last
          self.microq_options.merge!(opts.pop)
        end

        DSL.attach_async_methods(self, opts)
      end
    end
  end
end

Object.send(:extend, MicroQ::DSL::ClassMethods)
