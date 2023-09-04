#
# Environment files
#
[ -f "$HOME/secrets.cfg" ] && . "$HOME/secrets.cfg"
[ -f "$mydir.env" ] && . "$mydir.env"
