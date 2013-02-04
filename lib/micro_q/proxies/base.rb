module MicroQ
  module Proxy
    class Base
      attr_reader :errors, :klass, :method, :args, :at

      def initialize(options={})
        @errors  = []
        @options = options

        parse_and_validate
      end

      def valid?
        errors.empty?
      end

      def method_missing(meth, *args)
        @method = meth.to_s
        @args = args

        defaults = [@options.merge(
          :class => klass,
          :method => method,
          :args => args
        )]

        defaults << { :when => at } if at

        MicroQ.push(*defaults)
      end

      def respond_to?(method)
        super || klass.respond_to?(method)
      end

      private

      def parse_and_validate
        @at    = (at = @options.fetch(:at, nil)) && at.to_i
        after  = @options.fetch(:after, nil)

        @at    = Time.now.to_i + after if after
        @klass = @options[:class] && MicroQ::Util.constantize(@options[:class].to_s)

        (errors << 'Proxies require a valid class')  unless klass
      end
    end
  end
end
