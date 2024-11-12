#python3



def cidr_to_netmask(cidr):
  '''Convert CIDR prefix to netmask
  :param int|str cidr: prefix to convert
  :returns str: netmask

  From: https://stackoverflow.com/questions/33750233/convert-cidr-to-subnet-mask-in-python
  '''
  cidr = int(cidr)
  mask = (0xffffffff >> (32 - cidr)) << (32 - cidr)
  return (str( (0xff000000 & mask) >> 24)   + '.' +
          str( (0x00ff0000 & mask) >> 16)   + '.' +
          str( (0x0000ff00 & mask) >> 8)    + '.' +
          str( (0x000000ff & mask)))

###$_end-include

# ~ instr = 'one two fjd cd gghh demo docgs fact'
# ~ print(strtr(instr,{'one': '11', 'two': '22', 'fact': 'FACT', 'demo': 'DEMO', 'gghh dem': 'GGHH z123' }))
