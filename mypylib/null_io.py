#python
#import sys
#import os

saved_fds = []
'''Used internally to save fds by null_io'''

def null_io(close = False, keep_stderr = False):
  '''Redirects I/O to `/dev/null`

  :param bool close: Defaults to False, if True, the current I/O channels are closed
  :param bool keep_stderr: Default to False, if True, do not close stderr

  It will manipulate the operating sytems file descriptors and redirect them
  to `/dev/null`.  By default, it will save the existing file descriptors so
  that they can be restored later with `denull_io`.

  If `True` was passed as the `close` parameter, then previous file descriptors
  will be closed and `denull_io` will not work anymore.

  '''
  if close:
    if len(saved_fds) == 0:
      null_fd = os.open(os.devnull,os.O_RDWR)
      os.dup2(null_fd, 0)
      os.dup2(null_fd, 1)
      if not keep_stderr: os.dup2(null_fd, 2)
      os.close(null_fd)
    else:
      saved_fds[0].close()
      saved_fds[1].close()
      if not saved_fds[2] is None: saved_fds[2].close()
      saved_fds[3].close()
    return

  if len(saved_fds) == 0:
    null_fd = os.open(os.devnull,os.O_RDWR)
    saved_fds.append(os.dup(0))
    saved_fds.append(os.dup(1))
    saved_fds.append(None if keep_stderr else os.dup(2))
    saved_fds.append(null_fd)
    saved_fds.append(0)
  else:
    null_fd = saved_fds[3]

  if saved_fds[4]:
    # Already Nulled
    saved_fds[4] += 1
    return

  saved_fds[4] += 1
  os.dup2(null_fd, 0)
  os.dup2(null_fd, 1)
  if not keep_stderr: os.dup2(null_fd, 2)

def denull_io():
  '''Restores `null_io` redirections.
  '''
  saved_fds[4] -= 1
  if saved_fds[4]: return

  os.dup2(saved_fds[0], 0)
  os.dup2(saved_fds[1], 1)
  if not saved_fds[2] is None: os.dup2(saved_fds[2], 2)

###$_end-include
