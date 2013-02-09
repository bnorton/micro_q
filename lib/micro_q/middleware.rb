require 'micro_q/middleware/chain'

##
# The Middleware interface
#
# Middleware is invoked around the processing of a message, either
# on the 'client' (when the message is pushed to a queue) or on the
# 'server' (when the message is being executed).
#
# :method: call
#   - :args: (worker, message)
#     worker is the target object in the method invocation specified by the message
#     message the raw payload as de-queued by the queue
#
