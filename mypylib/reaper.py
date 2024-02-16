#python
import os

# child reaper
def reap_child_proc(signum, frame):
  '''Reaps child processes

  :param int signum: signal being processed
  :param frame frame: execution frame

  It simply reaps child process as they finish.

  Usage:

  ```python
  import signal

  signal(signal.SIGCHLD, reap_child_proc)

  ```
  '''
  while True:
    try:
      pid, status = os.waitpid(-1, os.WNOHANG)
    except OSError:
      return

    if pid == 0:  # no more zombies
      return

###$_end-include

