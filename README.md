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

## Notes

- ###$_include: <module> \
  For actual scripts that need to include modules.  These scripts
  would be modified in-place if needed.
- ###$_requires: <module> \
  For included module dependances.  If a module needs another module
  use reqquires.  These are *not* modified in-place, but are only
  used for modules included by scripts.

Example, the scripts in `scripts` use `###$_include` to include the
main module in `utils`.  In `utils`, the included module use
`###$_requires` to embed their dependancies.



## TODO

