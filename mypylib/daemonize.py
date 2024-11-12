#python
#import sys
#import os

def daemonize():
  '''Makes the current process run in the background.

  Internally, it forks a couple of times to make sure that the process
  is properly placed in the background and independant of the calling
  process.
  '''
  newpid = os.fork()
  if newpid != 0: sys.exit(0)
  os.setsid()
  newpid = os.fork()
  if newpid != 0: sys.exit(0)

###$_end-include
