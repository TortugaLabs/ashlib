#!/usr/bin/env python3
'''Extract docstring from bash scripts

## Description

Extracts documentation from source files.  It is meant to be used
to extract documentation from Shell scripts, but it should work
with any language that uses `#` as the comment indicator.

It has the following modes:

- API documentation
- Generic documentation
  - Man page generation
  - Man page viewing

### API documentation

It will look for lines containing the `#$` tag to introduce comments.
It uses [sphonx][sphinx]'s [markdown][markdown] parser, and can
generated indexed code.

The way this works it is quite simplistic.  When it finds a line with

```bash
 ... _content_ ... #$ _summary description_
```

It considers that _content_ is a language element to be documented,
and the _summary description_ is the one line summary of the object
element.

Subsequent lines of the form:

```bash
#$ _text_
```

i.e. lines without any content on the left of the `#$` marker
are considered the content of the entry of the previously found
language element.  Lines that appear *before* any language elements
are found are tread as contet for the _file level_ element.

## Generic documentation

This is for non-API type documentation.  i.e. it is for any generic
documentation files.  It will look for lines as follows:

```bash
#@@@ _filename_
```

This indicate the beginning of generic documentation content.  Found
content will be placed in [_output_]/[_gdoc_]_filename_.  Where:

- _output_ : argument passed as `--output`
- _gdoc_ : argument passed as `--gdoc`.
- _filename_ : taken from the `#@@@` line.

From then on, lines of the form:

```bash
#@\\[_int_] _text_
```

Are added to the content of the last found _filename_.  Lines with `#@`
found before the first `#@@@` line are ignored.

It is possible to order the documentation using the option _int_
specification.  If not given, it defaults to `int(0)`.  If
specified, it is used to sort the output lines.  The lines are arranged
in numberic order by _int_.  (Negative numbers are allowed).


### Man page generation

When generating **generic** documentation, **ashdoc** treats files
with ending of `.[1-8].md` specially.  These files are considered
man pages.

If the `--manify` option is given, these files will be converted
into `man` pages using `pandoc`.

Refer to [generating manpages from markdown][generating-manpage]
on how to write man pages.  Or use [this template][template].

Keep in mind that the `metablock` is generated from the _filename_
and lines with:

```bash
:version: VERSION
```

If the `--manify` option was *not* given, the [markdown][markdown]
content is modified.  A `#` is added containing the filename (without
path and `.md` extension) and existing `#` are promoted by adding an
additional `#`.

### Viewing man pages

Running:

```bash
ashdoc --manify=view input.sh
```
Will extract a man page and display it on-screen as a Linux formatted
man page.

  [markdown]: https://daringfireball.net/projects/markdown/syntax
  [sphinx]: https://www.sphinx-doc.org/en/master/
  [generating-manpage]: https://eddieantonio.ca/blog/2015/12/18/authoring-manpages-in-markdown-with-pandoc/
  [template]: https://gist.githubusercontent.com/eddieantonio/55752dd76a003fefb562/raw/38f6eb9de250feef22ff80da124b0f439fba432d/hello.1.md

```{argparse}
   :filename: ../ashdoc.py
   :func: cli_parser
```

'''
import re
import os
import sys
import subprocess
import tempfile
from argparse import ArgumentParser

C_MARKER = '#$'
RE_SIMPLE = re.compile(r'^\s*#\$ ?')
RE_ELEMENTS = [
  ( 'function', re.compile(r'^\s*([_A-Za-z][_A-Za-z0-9]*)\s*\(\s*\)\s*{\s*#\$ ?') ),
  ( 'function', re.compile(r'^\s*([_A-Za-z][_A-Za-z0-9]*)\s*\(\s*\)\s*#\$ ?') ),
]
C_GMARKER = '#@'
RE_GMARKER_START = re.compile(r'^\s*#@@@ *')
RE_GMARKER_CONTENT = re.compile(r'^\s*#@(-?[0-9]*) ?')

# Text File ID
RE_TEXT_FILE_ID = re.compile(r'<%([_A-Za-z][\._A-Za-z0-9]*)%>')
RE_TEXT_FILE_ID_CHECK = re.compile(r'^[_A-Z][_A-Z0-9]*$')

O_Q = False
'''quiet flag - do not show what is being done'''
O_V = False
'''verbose flag - show additional info (i.e. things that re not being done)'''
O_IDS = {}


O_MANIFY = None
RE_MANIFY = re.compile(r'\.[1-8]\.md$')
RE_MANIFY_VER = re.compile(r'\n:version:[ \t]*([^\n]*)\n')
RE_MANIFY_MUNGE = re.compile(r'\n([ \t]*)(#+[ \t]+[^\n]+)\n')

def update_file(fpath, ntxt, dryrun=True):
  '''Conditionally update a file

  :param str fpath: File to write
  :param str ntxt: New file contents
  :param bool dryrun: if True, only inform what would happen.
  '''
  if os.path.isfile(fpath):
    with open(fpath,'r') as fp:
      otxt = fp.read()
    if ntxt == otxt:
      if O_V: sys.stderr.write('{fname}: no changes found\n'.format(fname=fpath))
      return

  # Make sure the directory exists
  dname = os.path.dirname(fpath)
  if dname != '' and not os.path.isdir(dname):
    if not dryrun: os.makedirs(dname)

  if dryrun:
    if not O_Q: sys.stderr.write('{fname}: WONT update\n'.format(fname=fpath))
  else:
    with open(fpath,'w') as fp:
      fp.write(ntxt)
    if not O_Q: sys.stderr.write('{fname}: updated\n'.format(fname=fpath))


def gen_index(title, output, files,dryrun=True):
  '''Generate index file
  :param str title: document title
  :param str output: output file
  :param list files: list of string with files to display
  '''

  txt = '''.. index:: ! {title}
{title}
{underline}

This pages contains auto-generated documentation [#f1]_.

.. toctree::
   :titlesonly:

'''.format(
        title = title,
        underline = '='*len(title),
    )
  for f in files:
    if f.endswith('.md'):
      f = f[:-3]
    if f.endswith('.rst'):
      f = f[:-4]
    txt += '   {file}\n'.format(file=f)
  txt += '\n.. [#f1] Created with ashdoc\n'

  update_file(output, txt, dryrun)

def process_file(f, output, toc=[], dryrun=True, apigen='', gdocgen=None):
  '''Process the given file

  :param str f: file to process
  :param str output: output directory
  :param list toc: list to received generated files
  :param str dryrun: If not None, will not make changes to files
  :param str apigen: If not None, generate API documentation
  :param str gdocgen: If not None, generate generic documentation
  '''

  if f.endswith('.sh'):
    basename = f[:-3]
  elif f.endswith('.bash'):
    basename = f[:-3]
  else:
    basename = f
  of= '{dirpath}/{basename}.md'.format(dirpath=output.rstrip('/'),basename=basename)

  if output != '': output = output.rstrip('/') + '/'
  if not apigen is None and apigen != '': apigen = apigen.rstrip('/') + '/'
  if not gdocgen is None and gdocgen != '': gdocgen = gdocgen.rstrip('/') + '/'

  content = {}
  cnt = extract_docstr(f, basename, content, apigen, gdocgen)
  if cnt == 0:
    if O_V: sys.stderr.write('{fname}: no embedded documentation found (ignoring)\n'.format(fname=f))
    return

  for doc in content:
    toc.append(doc)
    update_file(output + doc, content[doc], dryrun)

def extract_docstr(f, basename, content = {}, apigen='', gdocgen=None):
  '''Extract documentation from the file

  :param str f: file to process
  :param str basename: File basename
  :param dict content: dictionary that will receive generated content
  :param str apigen: If not None, generate API documentation
  :param str gdocgen: If not None, generate generic documentation):
  :returns int: count of generated files
  '''

  # ~ fname = os.path.basename(f)
  fname = f
  txt = ''
  autohdr = True
  gdoc = {}
  gdoc_current = None
  sndir = os.path.dirname(f)
  if sndir != '': sndir += '/'

  with open(f,'r') as fp:
    l = 0
    for line in fp:
      l += 1
      # Try Embedding text-file ids
      mv = RE_TEXT_FILE_ID.search(line)
      if mv:
        # OK, make sure the syntax is right...
        idpath = mv.group(1).replace('.','/')
        if RE_TEXT_FILE_ID_CHECK.match(os.path.basename(idpath)):
          if os.path.isfile(sndir + idpath):
            with open(sndir + idpath,'r') as fp:
              txid = fp.read()
            txid.strip()
            if txid != '':
              i = txid.find('\n')
              if i > 0: txid = txid[:i].strip()
              line = line[0:mv.start()] + txid + line[mv.end():]
          elif idpath in O_IDS:
            line = line[0:mv.start()] + O_IDS[idpath] + line[mv.end():]
          else:
            sys.stderr.write('{file}, {line}: TEXT_FILE_ID "{txid}" not found\n'.format(
                        txid=mv.group(1), file = f, line = l))

      if C_MARKER in line:
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
      if C_GMARKER in line:
        mv = RE_GMARKER_START.match(line)
        if mv:
          line = line[len(mv.group(0)):]
          i = line.find('#')
          if i != -1: line = line[0:i]
          line = line.strip()
          gdoc_current = line
          gdoc[gdoc_current] = {}
          continue
        if gdoc_current is None: continue
        mv = RE_GMARKER_CONTENT.match(line)
        if mv:
          prefix = 0 if mv.group(1) == '' else int(mv.group(1))
          if not prefix in gdoc[gdoc_current]:
            gdoc[gdoc_current][prefix] = ''
          line = line[len(mv.group(0)):]
          gdoc[gdoc_current][prefix] += line

  # ~ import yaml
  # ~ print(yaml.dump(gdoc))
  # ~ import pprint
  # ~ pprint.pprint(gdoc)

  if txt != '' and not apigen is None:
    fname = apigen + basename
    content[fname + '.md'] =  '```{{index}} ! {filename} (file)\n```\n# {filename}\n'.format(
            filename = fname) + txt
  if len(gdoc) > 0 and not gdocgen is None:
    for doc in gdoc:
      txt = ''
      for i in sorted(gdoc[doc]):
        txt += gdoc[doc][i]
      if txt == '': continue
      if RE_MANIFY.search(doc):
        if not O_MANIFY is None:
          doc, txt = manify(doc, txt)
        else:
          # We do a special case here...
          txt = '# '+ doc[:-3] + RE_MANIFY_MUNGE.sub(r'\n\1#\2\n','\n'+txt)

      content[gdocgen + doc] = txt

  # ~ for i in content:
    # ~ print('>>>>',i+content[i][0],'<<<<')
    # ~ print(content[i][1])
    # ~ print('===')

  # ~ import yaml
  # ~ print(yaml.dump(content))
  # ~ return 0
  # ~ import pprint
  # ~ pprint.pprint(gdoc)

  return len(content)

MANSECT = {
  '1': 'General commands',
  '2': 'System calls',
  '3': 'Library functions',
  '4': 'Special files and drivers',
  '5': 'File formats and conventions',
  '6': 'Games and screensavers',
  '7': 'Miscellanea',
  '8': 'System administration commands and daemons',
}

def manify(srcfile, txt):
  '''Special handling for man files.

  This function does the special processing required for man pages.
  It does by taking the extracted text, adding additional meta
  data needed (which is infered from the input) and running
  pandoc to do the conversion.

  :param str srcfile: input file to process
  :param str txt: input text
  :returns str srcfile, str txt: generated man page, man page content
  '''
  srcfile = srcfile[:-3]
  sn = srcfile[-1:]
  title = os.path.basename(srcfile[:-2]).upper()
  sect = MANSECT[sn]
  mv = RE_MANIFY_VER.search('\n'+txt)
  if mv:
    ver = mv.group(1)
    txt = txt[:mv.start()] + txt[mv.end()-1:]
  else:
    ver = ''

  header = '% {title}({sn}) {ver} | {sect}\n'.format(
            title = title,
            sn = sn,
            ver = ver,
            sect = sect,
          )
  rc = subprocess.run(['pandoc', '--standalone', '--to', 'man'],
                            capture_output=True,
                            text=True,
                            input = header + txt)

  if rc.returncode == 0:
    txt = rc.stdout

    if O_MANIFY == 'view':
      with tempfile.NamedTemporaryFile(mode='w+') as fp:
        fp.write(txt)
        fp.flush()
        subprocess.run(['man', fp.name])
  else:
    if rc.stderr == '':
      sys.stderr.write('pandoc returned {}\n'.format(rc.returncode))
    else:
      sys.stderr.write(rc.stderr)

  return srcfile, txt


def cli_parser():
  '''Generate ArgumetParser object

  :returns ArgumetnParser: argument parser object
  '''
  cli = ArgumentParser(prog='ashdoc', description='Extract documentation strings')
  cli.add_argument('-q','--quiet',help='Do not display actions', action='store_true')
  cli.add_argument('-Q','--no-quiet',dest='quiet',help='Display what is being done', action='store_false')
  cli.add_argument('-v','--verbose',help='Show everything that is happening',action='store_true')
  cli.add_argument('-V','--no-verbose',dest='verbose', help='Do not show everything', action='store_false')
  cli.add_argument('-D','--define', help='Add TXTID', action='append')
  cli.add_argument('--dry-run', help='Do not modify files',action='store_true')
  cli.add_argument('--obj-heading',help='Object heading level', default = '3')
  cli.add_argument('--header',help='Header to generate', default = '## Definitions')
  cli.add_argument('--title',help='Index title', default = 'Reference Documentation')
  cli.add_argument('--prune',help='Delete non generated files (Use only with --api and --toc default options)', action = 'store_true')
  cli.add_argument('-o','--output',help='Output location')
  cli.add_argument('--toc',help='Generate index file contain TOC', nargs='?',default='index.rst', const='index.rst')
  cli.add_argument('--no-toc',dest='toc',help='Disable index file generation', action='store_const', const=None)
  cli.add_argument('--api',help='Generate API', nargs='?',default='', const='')
  cli.add_argument('--no-api',dest='api',help='Disable API generation', action='store_const', const=None)
  cli.add_argument('--gdoc',help='Generate Generic docs', default=None, const='', action='store_const')
  cli.add_argument('--no-gdoc',dest='gdoc',help='Disable Gneric doc generation', action='store_const', const=None)
  cli.add_argument('--manify',help='Enable manify extensions', nargs='?', default=None, const='')
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
    if not O_Q: sys.stderr.write("Removing empty folder: {p}\n".format(p=path))
    os.rmdir(path)

if __name__ == '__main__':
  cli = cli_parser()
  args = cli.parse_args()
  O_OBJHDR = args.header

  O_MANIFY = args.manify
  if not O_MANIFY is None:
    if O_MANIFY == 'view':
      args.quiet =True
      args.verbose = False
      args.dry_run = True
      args.prune = False
      args.api = None
      args.toc = None
      args.gdoc = ''
      args.output = ''
    elif  O_MANIFY != '':
      sys.stderr.write('{}: Unknown view mode\n'.format(O_MANIFY))
      sys.exit(1)

  O_Q = args.quiet
  O_V = args.verbose
  if not args.define is None:
    for d in args.define:
      if '=' in d:
        k,v = d.split('=', 1)
      else:
        k = d
        v = d
      O_IDS[k] = v

  # ~ print(args)
  # ~ sys.exit(1)
  # ~ print([O_Q, O_V])

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
  # ~ print(args)
  for f in args.files:
    process_file(f, args.output,
                  toc=toclst, dryrun=args.dry_run,
                  apigen=args.api, gdocgen = args.gdoc)

  if not args.toc is None:
    gen_index(args.title,args.output.rstrip('/') + ('' if args.output == '' else '/') + args.toc, toclst, args.dry_run)

  if args.prune:
    pp = len(args.output.rstrip('/'))+1
    for path,subdirs,files in os.walk(args.output):
      for name in files:
        # ~ print('path: %s' % path)
        # ~ print('subdirs: %s' % subdirs)
        fpath = os.path.join(path,name)
        f = fpath[pp:]
        if not args.toc is None and args.toc == f: continue
        if f in toclst: continue
        if args.dry_run:
          if O_Q: sys.stderr.write('{f}: WONT remove\n'.format(f=fpath))
        else:
          os.unlink(fpath)
          if not O_Q: sys.stderr.write('{f}: removed\n'.format(f=fpath))
    if not args.dry_run:
      removeEmptyFolders(args.output)

# ~ t = process_file('vcmp.sh')
# ~ print(t)
# ~ t = process_file('yesno.sh')
# ~ print(t)



