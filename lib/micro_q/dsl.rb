module MicroQ
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
        async_methods.each do |method|
          async_method = :"async_#{method}"
          define_singleton_method(async_method) do |*args|
            MicroQ::Proxy::Instance.new(:class => self).send(method, *args)
          end unless respond_to?(async_method)
        end
      end
    end
  end
end

Object.send(:extend, MicroQ::DSL)
