#python3
#from inspect import getframeinfo, stack

def myself():
  '''Return information of the caller

  :returns object: with attributes

  Among the attributes returned:

  - filename
  - lineno
  - function
  - code_context : list of lines being executed.
  '''
  caller = getframeinfo(stack()[1][0])
  return caller

###$_end-include
