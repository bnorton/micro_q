module MicroQ
  ##
  # Convenience methods for calling methods asynchronously
  # Adds perform_async by default
  #
  # Usage
  # class MyWorker
  #   worker :update, :queue => 'non-default'
  #
  #   def update
  #   end
  # end
  #
  # MyWorker.update_async
  # is the same as
  # MyWorker.new.async(:queue => 'non-default').update
  #
  module DSL
    ##
    # For each of the methods given to the Object.worker method
    # define the _async post-fixed version for convenience
    #
    def self.attach_async_methods(target, opts)
      target.class_eval do
        (target.microq_options[:methods] |= opts.flatten).each do |method|
          DSL.define_proxy_method target, method
        end
      end
    end

    def self.define_proxy_method(target, method)
      target.define_singleton_method(:"#{method}_async") do |*args|
        MicroQ::Proxy::Instance.new(
          target.microq_options.dup.merge(:class => self)
        ).send(method, *args)
      end unless respond_to?(:"#{method}_async")
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
