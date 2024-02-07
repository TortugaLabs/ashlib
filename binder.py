#!/usr/bin/env python3
'''Code binder

## Description

This script is used to embed code snippets into scripts.  It can later
be used to update snippets in case the original snippet was modified.

```{argparse}
   :filename: ../binder.py
   :func: cli_parser
```

'''
#
# Binder
#
import os
import sys
import re
import subprocess
import shutil
from argparse import ArgumentParser, Action
import fwalktree

# used for exception handling
import inspect

cf = {
  'include_path': [],
  'scoped_includes': {},
  'context': {
     'file': '<stdin>',
     'line': 0,
  },
  'opts': None,
}
'''global config settings'''


ENV_BINDER_PATH = 'BINDER_PATH'
'''Environment variable name used for defining snippets path'''


# Check for '\s*###$include: <snippet>'
RE_INCLUDE_SNIPPET = re.compile(r'(\s*)###\$_include:\s*([^#\s]+)(.*)')
'''Regular expression for matching include directives'''

# Check for '\s*###$begin-include: <snippet>'
RE_BEGIN_SNIPPET = re.compile(r'(\s*)###\$_begin-include:\s*([^#\s]+)(.*)')
'''Regular expression for matching the beginning of an included snippet'''

# Check for '\s*###$end-include'
RE_END_SNIPPET = re.compile(r'(\s*)###\$_end-include:?(\s.*|)$')
'''Regular expression for matching the end of an included snippet'''

# Check for require's
RE_REQUIRE_SNIPPET = re.compile(r'(\s*)###\$_requires?:\s*([^#\s]+)(.*)')
'''Regular expression for matching required snippets'''

# Embedded documentation
RE_EMBED_DOC = re.compile(r'(\s*)#\$\s*')
'''Regular expression Main pattern for matching embedded docs'''
RE_EMBED_DOC2 = re.compile(r'\s+#\$\s*')
'''Regular expression Alternative pattern for matching embedded docs'''

# Text File ID
RE_TEXT_FILE_ID = re.compile(r'<%([_A-Za-z][:\._A-Za-z0-9]*)%>')
'''Regular expression for matching text file ids'''
RE_TEXT_FILE_ID_CHECK = re.compile(r'^[_A-Z][:_A-Z0-9]*$')
'''Regular expression for matching text file ids'''

# Markers
FMT_INCLUDE_SNIPPET = '{prefix}###$_include: {snippet}{comment}\n'
'''Format to generate include directives'''
FMT_BEGIN_SNIPPET = '{prefix}###$_begin-include: {snippet}{comment}\n'
'''Format to generate beginning of included snippet markets'''
FMT_END_SNIPPET = '{prefix}###$_end-include: {snippet}\n'
'''Format to generate end of included snippet markets'''
FMT_DEF_META = 'fdir: {fdir}\ngitrepo: {giturl} ({remote})\ncommit: {describe}\ngitlog:---\n{log}\n===\n'
'''Format to generate meta data section'''
FMT_META_LINE = '{prefix}###| {text}\n'
'''Format to generate meta data lines'''
FMT_REQUIRES_DONE = '{prefix}###$_requires-satisfied: {snippet} as {snfile}\n'
'''Format to output redundant requires'''


included = {}
'''hash tracking files that have been included already'''

def find_snippet(snippet, incdirs):
  ''' Find the given snippet file in include directories

  :param str snippet: name of snippet
  :param list incdirs: List of str containing directories to search
  :returns None|str: found snippet file path, None if not found

  Will also check the `scoped_includes` if needed.
  '''
  # ~ print('CONTEXT: ', cf['context'])
  # ~ print('  SNIPPET: ',snippet)
  # ~ print('  INCLUDEDIRS: ', incdirs)

  i = snippet.find(':')
  if i != -1:
    if snippet[:i] in cf['scoped_includes']:
      snfile = '{dir}/{file}'.format(dir=cf['scoped_includes'][snippet[:i]],
                                      file=snippet[i+1:])
      if os.path.isfile(snfile):
        return snfile

  for fdir in incdirs:
    if fdir is None: continue
    snfile = '{dir}/{snippet}'.format(dir=fdir,
                                      snippet=snippet)
    if os.path.isfile(snfile):
      # ~ print('  SNFILE: ', snfile)
      return snfile
  return None

def include_snippet(line, mv, cwd, reent = False):
  '''Include snippet

  :param str line: line containing include/require statement
  :param Match mv: match object that found include/require statement
  :param str cwd: current direct for including/requring file
  :param bool reent: (Optional, defaults to False) True if called from include_snippet, otherwise False.

  Search for the requested snippet and processes it.
  '''
  prefix = mv.group(1)
  snippet = mv.group(2)
  comment = mv.group(3).rstrip('\r\n')

  if cf['opts'].unbind:
    return FMT_INCLUDE_SNIPPET.format(prefix=prefix,
                                      snippet=snippet,
                                      comment=comment)

  snfile = find_snippet(snippet,[ cwd ] + cf['include_path'])
  if snfile is None:
    sys.stderr.write('{snippet}: not found ({file}, {line})\n'.format(
                      snippet=snippet,
                      **cf['context']))
    return line

  if snfile in included:
    return FMT_REQUIRES_DONE.format(prefix=prefix,
                                    snippet=snippet,
                                    snfile=snfile,
                                    comment=comment) if reent else line

  sntext = ''
  if not reent:
    sntext += FMT_BEGIN_SNIPPET.format(prefix=prefix,
                                      snippet=snippet,
                                      comment=comment)

  sndir = os.path.dirname(snfile)
  # ~ print('--SNFILE: ',snfile)
  # ~ print('--SNDIR:  ',sndir)
  if sndir == '': sndir = '.'
  if cf['opts'].meta:
    meta = {
      'snippet': snippet,
      'fdir': fdir,
    }
    res = gitcmd(['remote'], sndir)
    if res is None:
      meta['remote'] = '<none>'
      meta['giturl'] = '<none>'
    else:
      meta['remote'] = res
      meta['giturl'] = gitcmd(['remote','get-url',res],sndir,'<none>')
    meta['describe'] = gitcmd(['describe'],sndir,'<none>')
    meta['log'] = gitcmd(['log','--decorate=short','-n','1','--',os.path.basename(snfile)],sndir,'<none>')

    for ml in cf['opts'].meta.format(**meta).split('\n'):
      sntext += FMT_META_LINE.format(prefix=prefix,text=ml)

  with open(snfile, 'r') as fp:
    included[snfile] = (snippet, cf['context'])
    oldcontext = cf['context'].copy()
    cf['context'] = {
     'file': snfile,
     'line': 0,
    }

    c = 0
    for line in fp:
      c += 1 ; cf['context']['line'] += 1
      if c == 1 and line[:3] == '#!/': continue # Skip hashbang
      if RE_END_SNIPPET.match(line): break
        # ~ sys.stderr.write('{snippet}: not embeddable ({file}, {line})\n{snippet}: Found EOS in {snfile}, {snline}\n'.format(
                      # ~ snippet=snippet,
                      # ~ **cf['context'],
                      # ~ snfile=snfile,
                      # ~ snline=c))
        # ~ return line
      # Skip embeded robodoc comments
      if (not cf['opts'].doc) and RE_EMBED_DOC.match(line): continue
      if RE_EMBED_DOC2.search(line):
        line = RE_EMBED_DOC2.split(line,1)[0] + '\n'

      mv = RE_REQUIRE_SNIPPET.match(line)
      if mv:
        sntext += include_snippet(line, mv, sndir, True)
        continue

      # Embedding text-file ids
      mv = RE_TEXT_FILE_ID.search(line)
      if mv:
        # OK, make sure the syntax is right...
        idpath = mv.group(1).replace('.','/')
        if RE_TEXT_FILE_ID_CHECK.match(os.path.basename(idpath)):
          idfile = find_snippet(idpath,[sndir]+cf['include_path'])
          if not idfile is None:
            txid = ''
            with open(idfile,'r') as fp:
              txid = fp.read()
            txid.strip()
            if txid != '':
              i = txid.find('\n')
              if i > 0: txid = txid[:i].strip()
              line = line[0:mv.start()] + txid + line[mv.end():]
          else:
            sys.stderr.write('TEXT_FILE_ID: "{txid}": not found ({file}, {line})\n'.format(
                        txid=mv.group(1), file = snippet, line = c))

      sntext += prefix
      sntext += line

  cf['context'] = oldcontext

  if not sntext[-1] == '\n': sntext += '\n'

  if not reent:
    sntext += FMT_END_SNIPPET.format(prefix=prefix,
                                   snippet=snippet)

  return sntext

def bind_stream(fp,cwd):
  rc = 0
  orig = ''
  moded = ''
  find_eos = None

  cf['context']['line'] = 0

  for line in fp:
    orig += line
    cf['context']['line'] += 1

    if find_eos:
      find_eos['line'] += line
      if RE_END_SNIPPET.match(line):
        # Found EOS
        moded += include_snippet(find_eos['line'], find_eos['mv'], cwd)
        find_eos = None
    else:
      mv = RE_INCLUDE_SNIPPET.match(line)
      if mv:
        moded += include_snippet(line, mv, cwd)
        continue
      mv = RE_BEGIN_SNIPPET.match(line)
      if mv:
        find_eos = {
          'line': line,
          'mv': mv,
          'count': cf['context']['line']
        }
        continue
      moded += line

  if find_eos:
    sys.stderr.write('{snippet}: unterminated bound snippet ({file}, {cline})\n'.format(
                  snippet=find_eos['mv'].group(2),
                  cline=find_eos['count'],
                  **cf['context']))
    moded += find_eos['line']
  return moded, orig


def bind_file(f):
  '''Bind the given file

  :param str f: file path to bind

  Will process the given file.  Execution is controlled via the
  `cf['opts']` global dictionary.
  '''
  cf['context']['file'] = f
  cf['context']['line'] = 0

  cwd = os.path.dirname(f)
  if cwd == '': cwd = '.'

  included.clear()  # Clear the included cache...
  # ~ sys.stderr.write("{file},{count}\n".format(file=f,count=len(included)))

  with open(f,'r') as fp:
    cf['context']['file'] = f
    moded, orig = bind_stream(fp,cwd)

  if moded != orig or cf['opts'].force:
    sys.stderr.write('{file}: updating\n'.format(file=f))
    if cf['opts'].dry_run: return # Don't do anything
    if cf['opts'].backup:
      bfile = '{name}{suffix}'.format(name=f, suffix=cf['opts'].backup)
      if os.path.exists(bfile): os.remove(bfile)
      shutil.copy2(f, bfile, follow_symlinks = False)
    with open(f,'w') as fp:
      fp.write(moded)

def append_path(pathspec):
  '''Append a entry to the include path

  :param str pathspec: path directory specification

  It the `pathspec` contains a `=`, this defines a scoped
  path.  Otherwise `pathspec` is simply added to the
  include search path.

  - `cf['include_path']` is updated.
  - `cf['scoped_includes'] may be updated.
  '''
  if pathspec == '': return
  i = pathspec.find('=')
  if i != -1:
    scope = pathspec[:i]
    if scope == '': scope = None
    pathspec = pathspec[i+1:]
  else:
    scope = None
  if pathspec == '': return
  if not os.path.isdir(pathspec): return

  if not scope is None:
    cf['scoped_includes'][scope] = pathspec
  cf['include_path'].append(pathspec)

def init_path(arginc):
  '''Initialize include path

  :param list arginc: List of include directories

  Initializes `cf['include_path']` with the directories provided
  as `-I` command line options, or a colon (:) separated string in
  `BINDER_PATH` environment variable or the input of the current
  file being processed.

  Explicitly scoped paths are possible by using the notation:

  `scope-name=directory-path`

  These directories are added to the path as `directory-path` but also
  defined as a scoped path name `scope-name`.  You can then refer to
  these directories with the `scope-name`.
  '''
  if not arginc is None:
    for d in arginc:
      append_path(d)

  var = os.getenv(ENV_BINDER_PATH)
  if not var is None:
    for d in var.split(':'):
      append_path(d)

  if not cf['opts'].no_std_path:
    d = os.path.dirname(__file__)
    if d == '': d='.'
    cf['include_path'].append(d)
    cf['scoped_includes']['ASHLIB'] = d

  # ~ print('INIT_INCLUDE_PATH:',cf['include_path'])
  # ~ print('SCOPED_INCLUDES:',cf['scoped_includes'])

git_cache = {}
def gitcmd(cmdline,cwd, err=None):
  '''Execute the given git command

  :param list cmdline: command line with arguments
  :param str cwd: working directory
  :param mixed|None err: value to return in case an error
  :returns str|mixed: Returns the git command stdout, unless there was an error.

  It will execute the given command running in `cwd`.  In case the
  command returns an error code or there was no output in `stdout`,
  it will return the value provided by `err`, which defaults to `None`.

  The output of the given command is cached for memory vs. time performance
  optimization.
  '''
  if cmdline[0] != 'git': cmdline.insert(0,'git')

  ckey = str([cmdline,cwd])
  if not ckey in git_cache:
    git_cache[ckey] = subprocess.run(cmdline,
                                     capture_output=True,
                                     text=True,
                                     cwd=cwd)

  if git_cache[ckey].returncode == 0 and git_cache[ckey].stdout != '':
    return git_cache[ckey].stdout.strip()
  return err

def itrc():
  '''Dump a inspect trace

  :returns str: inspect trace text

  This function is meant to run from an exception handler, to
  display the current stack trace for debugging.
  '''
  if not cf['opts'].dump_stack: return ''
  txt=''
  for fr in inspect.trace():
    txt += ' >> {filename},{line}:{fn} "{context}"\n'.format(
            filename = fr.filename,
            line = fr.lineno,
            fn = fr.function,
            context = fr.code_context[fr.index].strip('\r\n'))
  return txt #.rstrip('\r\n')

def cli_parser():
  '''Generate ArgumentParser object

  :returns ArgumentParser: argument parser object
  '''
  cli = ArgumentParser(prog='binder', description='Snippets binder')
  cli.add_argument('--dry-run', help='Do not modify files', action='store_true')
  cli.add_argument('-I','--include', help='Add Include path', action='append')
  cli.add_argument('-b','--backup', help='Backup changed files', nargs='?', const ='~')
  cli.add_argument('-M','--meta', help='Add meta data to snippets', nargs='?', const = FMT_DEF_META)
  cli.add_argument('-f','--force', help='Force output even when no change', action='store_true')
  cli.add_argument('-u','--unbind', help='Un-bind file', action='store_true')
  cli.add_argument('-d','--doc', help='Include embedded documentation', action='store_true')
  cli.add_argument('--no-std-path', help='Do not use standard path', action='store_true')
  cli.add_argument('-R','--recursive', help='Allow to recurse into directories', action='store_true')
  cli.add_argument('--follow-symlinks', help='When recursive, follow symlinks', action='store_true')
  cli.add_argument('--no-follow-symlinks', dest='follow_symlinks', help='When recursive, Do not follow symlinks', action='store_false')
  cli.set_defaults(follow_symlinks=True)
  cli.add_argument('--without-dircfg', help='Disable per-directory config file', action='store', const=None, dest='pattern_dircfg', default=fwalktree.DEF_PATTERN_DIRCFG)
  cli.add_argument('--pattern-dircfg', help='Per-directory config file', nargs='?', const='.binderrc', default=fwalktree.DEF_PATTERN_DIRCFG)
  cli.add_argument('--reset-std-patterns', help='Reset built-in patterns', action='store_true')
  cli.add_argument('--pattern-file', help='Read patterns from file', action='append')
  cli.add_argument('--pattern', help='Add pattern rule', action='append')
  cli.add_argument('--pattern-test', help='Test pattern rules', action='store_true')
  cli.add_argument('--report-binary', help='Show detected binary files', action='store_true')
  cli.add_argument('--dump-stack', help='Dump stack on errors', action='store_true')
  cli.add_argument('file', help='File to process', nargs='*')

  return cli

if __name__ == '__main__':
  cli = cli_parser()

  cf['opts'] = cli.parse_args()

  fwalktree.apply_cli_opts(cf['opts'])

  # ~ if cf['opts'].reset_std_patterns: cf['filter'] = []
  # ~ if cf['opts'].pattern:
    # ~ for cfg in cf['opts'].pattern:
      # ~ fwalktree.add_filter_rule(cfg,'cli-filter')
  # ~ if cf['opts'].pattern_file:
    # ~ for cfg in cf['opts'].pattern_file:
      # ~ fwalktree.read_filtercfg(cfg,'cli-filter')

  init_path(cf['opts'].include)
  #print(cf)
  #sys.exit(0)

  rc = 0
  if len(cf['opts'].file):
    for f in cf['opts'].file:
      if os.path.isdir(f) and cf['opts'].recursive:
        rc += fwalktree.walktree(f,bind_file)
      else:
        try:
          bind_file(f)
        except Exception as err:
          sys.stderr.write('{file},{line}: {err} (type: {type})\n{trace}\n'.format(**cf['context'],
                                          err=str(err),
                                          type=type(err),
                                          trace=itrc()))
          rc += 1
  else:
    # Use binder as a filter
    try:
      moded, orig = bind_stream(sys.stdin, '.')
      if moded != orig or cf['opts'].force:
        sys.stdout.write(moded)
    except Exception as err:
      sys.stderr.write('{file},{line}: {err} (type: {type})\n{trace}\n'.format(**cf['context'],
                                        err=str(err),
                                        type=type(err),
                                        trace=itrc()))
      rc += 1

  sys.exit(rc)
