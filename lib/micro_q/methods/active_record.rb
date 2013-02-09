module MicroQ
  module Methods
    ##
    # Methods that are added to AR instances
    #
    # When processing instance methods asynchronously, AR objects
    # should not be stored. Instances that are backed by a database
    # are herby serialized and re-queried from the DB at runtime.
    # For AR that means simply storing the class and adding a custom 'loader'
    #
    # A Loader is an additional step before a method is invoked that
    # generates a target object from a method invocation and arguments.
    # In the case of AR, what better then 'find'. Here we simply
    # store the id as the argument for find.
    #
    module ActiveRecord
      def async
        options = {
          :class => self.class,
          :loader => {
            :method => 'find',
            :args => [id]
          }
        }

        MicroQ::Proxy::Instance.new(options)
      end
    end
  end
end

MicroQ::Util.safe_require 'active_record'
if defined?(ActiveRecord::Base)
  ActiveRecord::Base.send(:include, MicroQ::Methods::ActiveRecord)
end
