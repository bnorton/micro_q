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
    end

    def self.json_parse
      @@json_parse ||= proc {|entry| JSON.parse(entry) }
    end

    def self.stringify(*args)
      args.collect do |a|
        stringify_keys(a)
      end
    end

    ##
    # Copy a hash and convert all keys to strings.
    # Stringifies to infinite hash depth
    #
    def self.stringify_keys(hash)
      {}.tap do |result|
        hash.keys.each do |key|
          value = hash[key]

          result[key.to_s] = value.is_a?(Hash) ? stringify_keys(value) : value
        end
      end
    end

    ##
    # Attempt to load a library but return nil if it cannot be loaded
    #
    def self.safe_require(lib)
      require lib
    rescue LoadError
    end
  end
end
