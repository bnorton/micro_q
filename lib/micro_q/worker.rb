require 'micro_q/worker/standard'

##
# The Worker interface
#
# The concrete worker implementation is the member of the chain that
# actually invokes the middleware chain and executes/performs the given
# message.
#
# :method: perform
#   - Re-hydrates and invokes the methods that the message specifies.
#   - :args: (message)
#     message is the hash the represents an pushed item
#
# Based on what keys are pushed to and de-queued from the queue,
# do the actions that the message specifies.
#
