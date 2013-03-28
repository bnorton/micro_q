module MicroQ
  module Inspect
    def self.included(base)
      base.send(:include, InstanceMethods)
    end

    module InstanceMethods
      def inspect
        "#<#{self.class.name}: #{self.object_id}>"
      end
    end
  end
end

['Worker::Standard', 'Queue::Default', 'Queue::Redis', 'Queue::Sqs', 'Manager::Default', 'Fetcher::Sqs'].each do |postfix|
  MicroQ::Util.constantize("MicroQ::#{postfix}").send(:include, MicroQ::Inspect)
end
