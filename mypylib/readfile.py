#!python3

def readfile(name):
  '''Read the contents of a file as whole

  :param str name: File name to read
  :returns str: contents of file
  '''
  with open(name,'r') as fp:
    text = fp.read()
  return text
