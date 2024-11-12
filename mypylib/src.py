#python3
#from inspect import getframeinfo, stack

def src():
  '''Return file,line of caller

  :returns (str,int): file and line of caller
  '''
  caller = getframeinfo(stack()[1][0])
  return (caller.filename,caller.lineno)

###$_end-include
