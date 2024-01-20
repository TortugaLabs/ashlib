#!/bin/sh
###$_requires: version.sh
#
# Copyright (c) 2020 Alejandro Liu
# Licensed under the MIT license:
#
# Permission is  hereby granted,  free of charge,  to any  person obtaining
# a  copy  of  this  software   and  associated  documentation  files  (the
# "Software"),  to  deal in  the  Software  without restriction,  including
# without  limitation the  rights  to use,  copy,  modify, merge,  publish,
# distribute, sublicense, and/or sell copies of the Software, and to permit
# persons  to whom  the Software  is  furnished to  do so,  subject to  the
# following conditions:
#
# The above copyright  notice and this permission notice  shall be included
# in all copies or substantial portions of the Software.
#
# THE  SOFTWARE  IS  PROVIDED  "AS  IS",  WITHOUT  WARRANTY  OF  ANY  KIND,
# EXPRESS  OR IMPLIED,  INCLUDING  BUT  NOT LIMITED  TO  THE WARRANTIES  OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
# NO EVENT SHALL THE AUTHORS OR  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR  OTHER LIABILITY, WHETHER  IN AN  ACTION OF CONTRACT,  TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#@@@ spp.1.md
#@ :version: <%VERSION%>
#@
#@ # NAME
#@
#@ *spp* - bash pre-processor
#@
#@ # SYNOPSIS
#@
#@ **spp** \[**--output=output**] \[**-I** _include-path] \[**-D** _cmd_] _file.m.ext_  _..._
#@
#@ # DESCRIPTION
#@
#@ Reads some textual data and output post-processed data.
#@
#@ Uses HERE_DOC syntax for the pre-processing language.
#@ So for example, variables are expanded directly as `$varname`
#@ whereas commands can be embedded as `$(command call)`.
#@
#@ As additional extension, lines of the form:
#@
#@ ```bash
#@ ##! command
#@ ```
#@
#@ Are used to include arbitrary shell commands.  These however
#@ are executed in line (instead of a subshell as in `$(command)`.
#@ This means that commands in `##!` lines can be used to define
#@ variables, macros or include other files.
#@
#@ ## OPTIONS
#@
#@ --output=output|-o
#@
#@ :  Sets the output filename.  If specified, all the input
#@    files will be sent to the output filename.  Use `-` for
#@    standard output.
#@
#@ -Iinclude-dir
#@
#@ :  Adds `include-dir` to the executable `PATH` (which is used
#@    in source commands (`.`).
#@
#@ -Dcmd
#@
#@ :  `cmd` will be eval'ed by the shell.  Used to define variables
#@    from the command line
#@
#@ file.m.ext
#@
#@ :   Input file to process.  Use `-` for standard input.  If `output`
#@     is not specified, the output will be `file.ext` unless the file
#@     extension can not be recognized.  In that case the output will
#@     be the same as the input file name with `.out` appended.
#@
#@ # SPECIAL VARIABLES
#@
#@ Within the pre-processed file, the following variables are
#@ available:
#@
#@ - name::
#@   input name without extensions.
#@ - input::
#@   input file name
#@ - output::
#@   output file name
#@
set -euf -o pipefail

###$_requires: pp/pp_cmd.sh
###$_requires: pp/pp_include.sh

include() { pp_include "$@"; }
pp_cmd "$@"

