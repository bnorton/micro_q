module MicroQ
  module Util
    ##
    # Stolen from active_support/inflector/inflections with a rescue to nil.
    #
    def self.constantize(word)
      names = word.split('::')
      names.shift if names.empty? || names.first.empty?

      constant = Object
      names.each do |name| # Compatible with Ruby 1.9 and above. Before 1.9 the arity of #const_defined? was 1.
        constant = constant.const_defined?(name, false) ? constant.const_get(name) : constant.const_missing(name)
      end
      constant
    rescue
      nil
    end

    def self.stringify_keys(hash)
      {}.tap do |result|
        hash.keys.each do |key|
          value = hash[key]

          result[key.to_s] = value.is_a?(Hash) ? stringify_keys(value) : value
        end
      end
    end
  end
end
