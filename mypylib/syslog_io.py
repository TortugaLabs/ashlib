#
# Makes the output of process to be logged on syslog
#
#import os
#import sys
#import syslog

def _io_syslog(fh,tag):
  r,w = os.pipe()
  cpid = os.fork()
  if cpid == 0:
    # Child...
    os.close(w)
    sys.stdin.close()
    sys.stdout.close()
    sys.stderr.close()
    fin = os.fdopen(r)

    # ~ x = open('log-%s.txt' % tag,'w')
    import syslog

    for line in fin:
      line = line.rstrip()
      if not line: continue
      syslog.syslog("%s: %s" % (tag,line))
      # ~ x.write("%s: %s\n" % (tag,line))
      # ~ x.flush()
    sys.exit(0)

  os.close(r)
  os.dup2(w, fh.fileno())
  os.close(w)

def syslog_io(tag):
  _io_syslog(sys.stdout,'%s(out)' % tag)
  _io_syslog(sys.stderr,'%s(err)' % tag)

