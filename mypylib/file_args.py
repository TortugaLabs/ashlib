#python
#import sys
#import os

def file_args(args):
  """Read arguments from files

  :param list args: arguments to process
  :returns list: replacement args

  Arguments that beging with '@' are replaced with the contents
  of an argument file.  Unless the file does not exists and
  then the argument is just added as is.

  Argument file syntax:

  - Empty lines and lines staring with '#' or ';' are ignored.
  - Lines are automatically pre-pended with '--' so as to pass
    them as extended flag variables.
  - Lines that begin with "'" are treated as verbatim, i.e.
    the '--' is not added.
  - Lines that begin with three single quotes "'''" are treated as
    heredocs, so from the on input is read until a line
    with "'''" is found.  The whole input until then is added
    as a single argument.

  """

  newargs = []
  for i in args:
    if i.startswith('@'):
      if not os.path.isfile(i[1:]):
        newargs.append(i)
        continue
      with open(i[1:],'r') as fp:
        in_heredoc = False
        for ln in fp:
          if in_heredoc:
            if ln.strip() == "'''":
              in_heredoc =  False
              newargs[-1] = newargs[-1].rstrip()
              continue
            newargs[-1] += ln
          else:
            ln = ln.strip()
            if ln.startswith(('#',';')) or ln == '': continue # comments
            if ln.startswith("'''"):
              in_heredoc = True
              ln = ln[3:]
              if ln != '': ln += '\n'
            elif ln.startswith("'"):
              ln = ln[1:]
              if ln.endswith("'"): ln = ln[:-1]
            else:
              ln = '--' + ln
            newargs.append(ln)
    else:
      newargs.append(i)
  return newargs

###$_end-include

if __name__ == '__main__':
  import sys
  import os
  sys.argv = file_args(sys.argv)
  print(sys.argv)
