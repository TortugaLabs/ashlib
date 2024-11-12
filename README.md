# ashlib


ASHLIB is a snippet library that implements useful functions for either
bash or sh.

## Copyright

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

## Usage

The way it works is via the `binder.py` script which lets you
embed snippets into your scripts.  It will also update
snippets if they ever change.

## Folder structure

- `scripts` : contains bound scripts.  Copy these to include into your
  own code.
- `utils` : contains code that is included by bound scripts.
- `cgilib` : library for CGI programming
- `compat` : compatibility functions
- `docs` : [sphinx][sphinx] based documentation
- `mk` : snippets used in `Makefiles`
- `mypylib` : Python snippets
- `pp` : shell-based pre-processor
- `testlib` : routines for testing


## Binder codes

- `###$_include: <module>` \
  These are processed only on top-level files that will be modified
  in-place.  Should not be used within embedded snippets.
- `###$_requires: <module>` \
  For included module dependances.  If a module needs another module
  use reqquires.  These are *not* modified in-place, but are only
  used for modules included by scripts.
- `###$_begin-include: <module>` \
  This is to mark the beginning of an included module.
- `###$_end-include: <module>` \
  This is to mark the end of an included module
- `#$` is used for the start of documentation separator.
  Lines that begin with `#$` are removed unless the `--doc` option was given.
- `<%TEXT_FILE_ID%>` \
  Are replaced by the contents of `TEXT_FILE_ID`.

Example, the scripts in `scripts` use `###$_include` to include the
main module in `utils`.  In `utils`, the included module use
`###$_requires` to embed their dependancies.

## Changes

- 3.1.0-RC1:
  - New features: is_path, ghrelease --test, readfile,
    jsgen, pysetup, dotenv
- 3.0.1:
  - version info
  - scoped includes
  - more documentation
  - Added recursive options to ashdoc
  - Recursive functionality in binder refactored into fwalktree
    and supports matching file contents
- 3.0.0:
  - Re-factor to binder sytem.

## TODO

- Add code:
  ```python
  textchars = bytearray({7,8,9,10,12,13,27} | set(range(0x20, 0x100)) - {0x7f})
  is_binary_string = lambda bytes: bool(bytes.translate(None, textchars))

  is_binary_string(open('/usr/bin/python', 'rb').read(1024)) # Returns True
  is_binary_string(open('/usr/bin/dh_python3', 'rb').read(1024) # Returns False
  ```
  To detect binary files.


  [sphinx]: https://www.sphinx-doc.org/en/master/
