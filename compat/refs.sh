#!/bin/sh
#
## Symbolic/Reference functions
##
## Let's you add a level of indirection to shell scripts
#
assign() {
## Assigns a value to the named variable
## # USAGE
##     assign varname varvalue
## # ARGS
## * varname -- variable to assign a value
## * value -- value to assign
## # DESC
## This function assigns a value to the named variable.  Unlink straight
## assignment with `=`, the variable name can be a variable itself referring
## to the actual variable.
  eval "$1=\"\$2\""
}

get() {
## Returns the value of varname.
## # USAGE
##   get varname
## # ARGS
## * varname -- variable to lookup.
## # OUTPUT
##   value of varname
## # DESC
## `get` will display the value of the provided varname.  Unlike direct
## references with `$`, the varname can be itself a variable containing
## the actual variable to be referenced.
  eval echo \"\$$1\" || :
}
