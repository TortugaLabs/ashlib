#!/usr/bin/env python3
'''Filtered walk tree

## Description

This module is used to recursively walk a directory tree selecting
files according a specific criteria

'''
import os
import fnmatch
import re
import sys

#
# FWalkTree
#
cf = {
  'filter': [
      ('*~','-'), ('.git','D-'),
      ('*.zip', 'F-'), ('*.jar', 'F-'),
      ('*.gz', 'F-'), ('*.xz', 'F-'), ('*.bz2', 'F-'),
      ('*.tar', 'F-'), ('*.cpio', 'F-'), ('*.tgz', 'F-'),
      ('*.iso', 'F-'),
      ('*.pyc', 'F-' ),
      ('*.exe', 'F-' ), ( '*.EXE', 'F-' ),
      ('*.[jJ][pP][gG]', 'F-' ), ( '*.jpeg', 'F-' ), ( '*.png', 'F-'),
      ('*.gif', 'F-'), ('*.ico','F-'),
      ('*.ttf', 'F-'), ('*.o','F-'),
      ('*.pdf','F-'),  ('*.epub','F-'),  ('*.cbz','F-'),  ('*.cbr','F-'),
      ('*.mp4', 'F-'),('*.mp3','F-'),('*.mov','F-'),('*.wav','F-'),
   ],
  'cli-filter': [],
  'pattern-dircfg': None,
  'follow-symlinks': False,
  'pattern-test': False,
  'report-binary': True,
}
'''Global config settings'''

DEF_PATTERN_DIRCFG = '.binderrc'
'''Default per-directory exclude patterns file'''
CHUNK_SIZE = 4096
'''When matching content, read this many characters'''
VISITED_DIRS = dict()
'''Used to prevent infinite loops when following symlinks'''

def filter_file(f,name=None):
  '''Apply file filters

  :param str f: file path to filter
  :param str name: base name of the file (without directory path)
  :returns bool: True if the file needs to be filtered, False if it should be processed

  Filter file names/paths using the filter as defined in the `cf['cli-filter']`
  and `cf['filter']` global configuration variables.
  '''
  if name is None: name = os.path.basename(f)

  isdir = os.path.isdir(f)
  for pat,op in cf['cli-filter'] + cf['filter']:
    if op[0] == 'D' and (not isdir): continue # Dir only patterns...
    if op[0] == 'F' and isdir: continue # File only patterns...

    if op.startswith('FC'):
      # This is a file content check
      try:
        with open(f,'r') as fp:
          txt = fp.read(CHUNK_SIZE)
          if pat.search(txt): return op[-1] == '-'
      except UnicodeDecodeError:
        if cf['report-binary']:
          sys.stderr.write(f'{sfile}: Unprocessed binary file\n')
        return False
    else:
      # File name wildcard check
      if fnmatch.fnmatch(f,pat[1:]) if pat[0] == '/' else fnmatch.fnmatch(name,pat):
        return op[-1] == '-'
  return False

def add_filter_rule(ln,filterid):
  '''Add a filter specification to a filter table

  :param str ln: Filter rule specification
  :param str filterid: Filter to update (filter or cli-filter).

  This function updates either `cf['filter']` or `cf['cli-filter']`
  by adding the given rule.  Rules are of the form:

  `<prefix>match`

  Prefix can be one of:

  - `D+` : Includes matching directory names
  - `D-` : Excludes matching directory names
  - `F+` : Includes matching file names
  - `F-` : Excluses matching file names
  - `+` : Includes matching file or directory names.  If no prefix
    is specified, this is the default.
  - `-` : Exclusdes matching file or directory names.
  - `FC+` : Include files based on a regular expression matching
     the file contents.
  - `FC-` : Exclude files based on a regular expression matching
     the file contents.

  If a file/directory name match starts with `/`, it matches the
  full path, otherwise it tests only against the base name.

  For FC rules, the DOTALL and IGNORECASE flags are used by default.
  You can use inline syntax notation to change these settings.  Examples:

  Case sensitive
  ```
  (?-i:match)
  ```

  Multi-line and case sensitive.
  ```
  (?m-i:string expression)
  ```

  Available flags:

  - a : ASCII-only matching
  - i : ignore case
  - l : locale dependent match
  - m : multi-line (applyes to "^" and "$' matches)
  - s : dot matches all (including newlines)
  - u : unicode matches
  - x : verbose expressions

  **TIP:** `.*` is greedy by default.  Use `.*?` for non greedy
  wildcard match.

  '''
  rule = ( ln, '+' )
  for prefix in [ 'D+', 'D-', 'F+', 'F-', '+', '-' , 'FC+', 'FC-']:
    if ln.startswith(prefix):
      if prefix.startswith('FC'):
        # The prefix indicates a Content RegExp match
        rule = ( re.compile(ln[len(prefix):],re.DOTALL|re.IGNORECASE) , prefix )
      else:
        rule = ( ln[len(prefix):] , prefix)
      break
  cf[filterid].append(rule)

def read_filtercfg(cfgfile,filter='filter'):
  '''Defines filters from configuration file

  :param str cfgfile: file name of configuration file to read
  :param str filter: type of filter to load.  `filter` if not specified

  Loads a filter specification from file.  The `cf[filter]` global
  configuration is updated.
  '''
  cfilter = list(cf[filter])
  nfilter = []
  with open(cfgfile,'r') as fp:
    for ln in fp:
      ln = ln.strip()
      if ln == '' or ln[0] == '#': continue
      if ln == '!RESET!':
        cfilter = []
        nfilter = []
        continue
      add_filter_rule(ln,filter)

  if filter == 'filter':
    cf[filter] = nfilter + cfilter
  else:
    cf[filter] = cfilter + nfilter


def walktree(dirname, lamb):
  '''Walk directory tree

  :param str dirname: Directory to walk
  :param function lamb: Function to call when a file is found
  :returns int: returns a count of failed files.

  This function will walk a directory tree, calling the function
  `lamb` when a suitable file is found.

  TODO:Prevent symlink infinite loops
  '''

  dirname = dirname.rstrip('/')

  if os.path.realpath(dirname) in VISITED_DIRS: return 0
  VISITED_DIRS[os.path.realpath(dirname)] = 1

  if cf['pattern-dircfg']:
    ofilter = list(cf['filter'])
    sfile = f'{dir}/{cf["pattern-dircfg"]}'
    if os.path.isfile(sfile): read_filtercfg(sfile)

  subs = os.listdir(dirname)
  rc = 0
  for i in subs:
    sfile = f'{dirname}/{i}'
    if sfile[:2] == './': sfile = sfile[2:] # This is not needed but make things nicer looking
    if os.path.islink(sfile) and (not cf['follow-symlinks']): continue # Skipping symlink
    if not (os.path.isfile(sfile) or os.path.isdir(sfile)): continue # Ignore "special" files

    ftest = filter_file(sfile,i)
    isdir = os.path.isdir(sfile)
    if cf['pattern-test']:

      print('PATTERN:{file}{isdir} - {yesno}'.format(file=sfile,
                                isdir='/' if isdir else '',
                                yesno='FILTERED' if ftest else 'PROCESS'))
      if isdir and not ftest: walktree(sfile,lamb)
      continue

    if ftest: continue

    try:
      if isdir:
        walktree(sfile,lamb)
      else:
        lamb(sfile)
    except UnicodeDecodeError:
      if cf['report-binary']:
        sys.stderr.write(f'{sfile}: Unprocessed binary file\n')
    except Exception as err:
      sys.stderr.write('{file}: {err} (type: {type})\n{trace}\n'.format(
                                file=sfile,
                                err=str(err),
                                type=type(err),
                                trace=itrc()))
      rc += 1

  if cf['pattern-dircfg']: # Restore previous filter config
    cf['filter'] = ofilter

  return rc

def apply_cli_opts(ns):
  '''Apply CLI options

  :param namespace ns: NameSpace created by argument parse.parse_args

  Modify `cf` settings from the given namespace from parse args.
  '''

  if ns.reset_std_patterns: cf['filter'] = []
  if ns.pattern:
    for cfg in ns.pattern:
      add_filter_rule(cfg,'cli-filter')
  if ns.pattern_file:
    for cfg in ns.pattern_file:
      read_filtercfg(cfg,'cli-filter')

  cf['pattern-dircfg'] = ns.pattern_dircfg
  cf['follow-symlinks'] = ns.follow_symlinks
  cf['pattern-test'] = ns.pattern_test
  cf['report-binary'] = ns.report_binary

if __name__ == '__main__':
  from argparse import ArgumentParser, Action

  cli = ArgumentParser(prog='fwalktree', description='fwalktree test')
  cli.add_argument('--follow-symlinks', help='When recursive, follow symlinks', action='store_true')
  cli.add_argument('--no-follow-symlinks', dest='follow_symlinks', help='Do not follow symlinks', action='store_false')
  cli.set_defaults(follow_symlinks=True)
  cli.add_argument('--without-dircfg', help='Disable per-directory config file', action='store', const=None, dest='pattern_dircfg', default=DEF_PATTERN_DIRCFG)
  cli.add_argument('--pattern-dircfg', help='Per-directory config file', nargs='?', const='.binderrc', default=DEF_PATTERN_DIRCFG)
  cli.add_argument('--reset-std-patterns', help='Reset built-in patterns', action='store_true')
  cli.add_argument('--pattern-file', help='Read patterns from file', action='append')
  cli.add_argument('--pattern', help='Add pattern rule', action='append')
  cli.add_argument('--pattern-test', help='Test pattern rules', action='store_true')
  cli.add_argument('--report-binary', help='Show detected binary files', action='store_true')
  cli.add_argument('file', help='File/directories to process', nargs='*')

  opts = cli.parse_args()
  print(opts)
  apply_cli_opts(opts)

  def process(f):
    print(f'Processing {f}')

  if len(opts.file):
    for f in opts.file:
      if os.path.isdir(f):
        walktree(f,process)
      else:
        print(f'{f} is not a directory')
  else:
    print('No directories specified')

