#
# Time stamping
#
import sys
import time

TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S %z"

#
# Format timestamp
#
def timestamp(ts = None):
  if ts is None: ts = time.time()
  return time.strftime(TIMESTAMP_FORMAT, time.localtime(ts))

#
# Prepends output with a timestamp
#
def ts_print(msg, io=None):
  if mode is None:
    io = sys.stderr

  # If not using syslog, we output a time-stamp
  prefix = "[" + time.strftime(TIMESTAMP_FORMAT) + "]:"
  io.write(prefix + msg + "\n")
