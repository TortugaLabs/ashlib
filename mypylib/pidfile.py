#
# Save current PID to a file
#
def pidfile(filename):
  with open(filename,"w") as fh:
    fh.write("%d\n" % os.getpid())
