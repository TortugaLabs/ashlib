#python3

def strtr(strng, replace):
  '''Replaces substrings defined in the `replace` dictionary with
  its replacement value.

  :param str string: String to convert
  :param dict replace: Mapping of string substitutions
  :returns str: string with the replaced contents

  Based on [phps-strtr-for-python](https://stackoverflow.com/questions/10931150/phps-strtr-for-python).

  Equivalent to php [strtr](https://www.php.net/manual/en/function.strtr.php)
  function.
  '''
  buf, i = [], 0
  while i < len(strng):
    for s, r in replace.items():
      if strng[i:len(s)+i] == s:
        buf.append(r)
        i += len(s)
        break
    else:
      buf.append(strng[i])
      i += 1
  return ''.join(buf)

###$_end-include

# ~ instr = 'one two fjd cd gghh demo docgs fact'
# ~ print(strtr(instr,{'one': '11', 'two': '22', 'fact': 'FACT', 'demo': 'DEMO', 'gghh dem': 'GGHH z123' }))
