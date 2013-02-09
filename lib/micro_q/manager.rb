require 'micro_q/manager/default'

##
# The Manager interface
#
# The concrete manager implementation encapsulates a queue and
# a pool of workers. The worker pool need only be a collection of
# workers that can accept and perform messages.
#
# :method: start
#   - Begin the run loop for message processing.
#
# Note that the default manager is a celluloid actor that reschedules
# itself (via the after(seconds) { start }) call which is a recursive
# call that executes asynchronously. This behavior is critical and
# therefore the class must `include Celluloid`.
#
