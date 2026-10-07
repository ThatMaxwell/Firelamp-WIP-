# Firelamp OS: start the desktop when logging in on the first console.
[[ -f ~/.bashrc ]] && . ~/.bashrc

if [[ -z $WAYLAND_DISPLAY && $XDG_VTNR -eq 1 && ! -e ~/.no-firelamp-session ]] &&
   ! grep -qw firelamp.nosession /proc/cmdline; then
    exec /usr/local/bin/firelamp-session
fi
