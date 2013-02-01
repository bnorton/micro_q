module MicroQ
  module Util
    def self.constantize(name)
      names = name.split('::')
      names.shift if names.empty? || names.first.empty?

      constant = Object
      names.each do |n|
        constant = constant.const_defined?(n) ? constant.const_get(n) : constant.const_missing(n)
      end
      constant
    end
  end
end
