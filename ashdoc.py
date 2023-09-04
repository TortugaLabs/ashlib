#!/usr/bin/env python3
'''ashdoc

Extract docstring from bash scripts
'''
import re
import os
import sys
from argparse import ArgumentParser

C_MARKER = '#$'
RE_SIMPLE = re.compile(r'^\s*#\$ ?')
RE_ELEMENTS = [
  ( 'function', re.compile(r'^\s*([_A-Za-z][_A-Za-z0-9]*)\s*\(\s*\)\s*{\s*#\$ ?') ),
  ( 'function', re.compile(r'^\s*([_A-Za-z][_A-Za-z0-9]*)\s*\(\s*\)\s*#\$ ?') ),
]

def gen_index(title, output, files,dryrun=True):
  '''Generate index file
  :param str title: document title
  :param str output: output directory
  :param list files: list of string with files to display
  '''

  txt = '''.. index:: ! {title}
{title}
{underline}

This pages contains auto-generated documentation [#f1]_.

.. toctree::
   :titlesonly:

   {files}

.. [#f1] Created with ashdoc
'''.format(
        title = title,
        underline = '='*len(title),
        files = '\n   '.join(files),
    )

  of= '{dirpath}/index.rst'.format(dirpath=output.rstrip('/'))

  if os.path.isfile(of):
    with open(of,'r') as fp:
      otxt = fp.read()
    if txt == otxt:
      sys.stderr.write('{fname}: no changes found\n'.format(fname='index.rst'))
      return

  if dryrun:
    sys.stderr.write('{fname}: WONT udpate\n'.format(fname='index.rst'))
  else:
    with open(of,'w') as fp:
      fp.write(txt)
    sys.stderr.write('{fname}: udpated\n'.format(fname='index.rst'))

def process_file(f, output, toc=[], dryrun=True):
  '''Process the given file

  :param str f: file to process
  :param str output: output directory
  '''

  if f.endswith('.sh'):
    basename = f[:-3]
  elif f.endswith('.bash'):
    basename = f[:-3]
  else:
    basename = f
  of= '{dirpath}/{basename}.md'.format(dirpath=output.rstrip('/'),basename=basename)

  ntxt = extract_docstr(f)
  if ntxt is None:
    sys.stderr.write('{fname}: no embedded documentation found (ignoring)\n'.format(fname=f))
    return

  toc.append(basename)
  if os.path.isfile(of):
    with open(of,'r') as fp:
      otxt = fp.read()
    if ntxt == otxt:
      sys.stderr.write('{fname}: no changes found\n'.format(fname=f))
      return

  # Make sure the directory exists
  dname = os.path.dirname(of)
  if dname != '' and not os.path.isdir(dname):
    if not dryrun: os.makedirs(dname)

  if dryrun:
    sys.stderr.write('{fname}: WONT udpate\n'.format(fname=f))
  else:
    with open(of,'w') as fp:
      fp.write(ntxt)
    sys.stderr.write('{fname}: udpated\n'.format(fname=f))


def extract_docstr(f):
  '''Extract documentation from the file

  :param str f: file to process
  '''

  # ~ fname = os.path.basename(f)
  fname = f
  txt = ''
  autohdr = True

  with open(f,'r') as fp:
    for line in fp:
      if not C_MARKER in line: continue

      mv = RE_SIMPLE.match(line)
      if mv:
        txt += line[len(mv.group(0)):]
        continue

      # ~ found = False
      for otype,re in RE_ELEMENTS:
        mv = re.match(line)
        if not mv: continue

        # ~ found = True
        if autohdr:
          autohdr = False
          txt += O_OBJHDR + '\n'

        txt += '```{{index}} {oid} ({otype} in {filename})\n```\n{prefix} {oid}\n'.format(
                oid = mv.group(1),
                otype = otype,
                filename = f,
                prefix = O_PREFIX)
        s  = line[len(mv.group(0)):].strip()
        if s != '': txt += ':summary: {summary}\n'.format(summary = s)
        break

      # ~ if found: continue


  if txt == '': return None

  return '```{{index}} ! {filename} (file)\n```\n# {filename}\n'.format(filename = fname) + txt

def cli_parser():
  '''Generate ArgumetParser object

  :returns ArgumetnParser: argument parser object
  '''
  cli = ArgumentParser(prog='ashdoc', description='Extract documentation strings')
  cli.add_argument('--dry-run', help='Do not modify files',action='store_true')
  cli.add_argument('--obj-heading',help='Object heading level', default = '3')
  cli.add_argument('--header',help='Header to generate', default = '## Definitions')
  cli.add_argument('--title',help='Index title', default = 'Reference Documentation')
  cli.add_argument('--prune',help='Delete non generated files', action = 'store_true')
  cli.add_argument('-o','--output',help='Output location')
  cli.add_argument('files', help='File(s) to process', nargs='*')
  return cli

def removeEmptyFolders(path, removeRoot=True):
  # https://gist.github.com/jacobtomlinson/9031697
  'Function to remove empty folders'
  if not os.path.isdir(path):
    return

  # remove empty subfolders
  files = os.listdir(path)
  if len(files):
    for f in files:
      fullpath = os.path.join(path, f)
      if os.path.isdir(fullpath):
        removeEmptyFolders(fullpath)

  # if folder empty, delete it
  files = os.listdir(path)
  if len(files) == 0 and removeRoot:
    sys.stderr.write("Removing empty folder: {p}\n".format(p=path))
    os.rmdir(path)

if __name__ == '__main__':
  cli = cli_parser()
  args = cli.parse_args()
  O_OBJHDR = args.header

  if re.match(r'^[0-9]+$', args.obj_heading):
    O_PREFIX = '#' * int(args.obj_heading)
  else:
    O_PREFIX = args.obj_heading

  if args.output is None:
    sys.stderr.write('No output specified, no files will be generated\n')
    sys.exit(1)

  if len(args.files) == 0:
    sys.stderr.write('No input files specified\n')
    sys.exit(0)

  toclst=[]
  for f in args.files:
    process_file(f, args.output, toclst, args.dry_run)

  gen_index(args.title, args.output, toclst, args.dry_run)

  if args.prune:
    pp = len(args.output.rstrip('/'))+1
    for path,subdirs,files in os.walk(args.output):
      for name in files:
        # ~ print('path: %s' % path)
        # ~ print('subdirs: %s' % subdirs)
        fpath = os.path.join(path,name)
        f = fpath[pp:]
        if f == 'index.rst': continue
        if f.endswith('.md'): f = f[:-3]
        if f in toclst: continue
        if args.dry_run:
          sys.stderr.write('{f}: WONT remove\n'.format(f=fpath))
        else:
          os.unlink(fpath)
          sys.stderr.write('{f}: removed\n'.format(f=fpath))
    if not args.dry_run:
      removeEmptyFolders(args.output)

# ~ t = process_file('vcmp.sh')
# ~ print(t)
# ~ t = process_file('yesno.sh')
# ~ print(t)



