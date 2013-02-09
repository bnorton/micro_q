require 'micro_q/queue/default'

##
# The Queueing interface
#
# The concrete queue implementations will all have something simple in
# common. The queue stores and returns data. The logic used for
# selecting the next items to return is critical but not relevant to the
# rest of the system nor to the interface.
#
# :method: push
#   - Add items to the backing data store
#   - :args: (message, options)
#     message is the hash the represents an pushed item
#     options are for items that dont require storing in the message itself
#       but are important in queueing.
# :method: dequeue
#   - Remove and return items from the data store
#
# You are otherwise able to implement this class in any suitable manner.
# If adhering to the other conventions around data structures, keys, etc,
#  then it will be easier to use the other types of classes required for
#  micro_q to work properly.
#
