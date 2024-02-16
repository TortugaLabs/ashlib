#python
# import sys

class Unbuffered(object):
  '''Wraps a stream object so that all its output gets flushed right away
     Unbuffered I/O

     A lot of times, daemons will run in the background with output
     going to a file or to a pipe

     This makes sure that the output is handled immediatly
  '''
  def __init__(self, stream):
    '''Create stream
    :param stream: stream to be wrapped.
    '''
    self.stream = stream
  def write(self, data):
    '''Auto flush writes
    :param bytes|str data: data to output
    '''
    self.stream.write(data)
    self.stream.flush()
  def writelines(self, datas):
    '''Auto flush writelines
    :param bytes|str datas: datas to output
    '''
    self.stream.writelines(datas)
    self.stream.flush()
  def __getattr__(self, attr):
    '''internal function to make the stream transparent'''
    return getattr(self.stream, attr)

def unbuffered_io():
  '''Makes stdout and stderr unbuffered streams

  sys.stdout and sys.stderr is modified.  Note that the underlying
  OS objects are unchanged.
  '''
  sys.stdout = Unbuffered(sys.stdout)
  sys.stderr = Unbuffered(sys.stderr)

###$_end-include
