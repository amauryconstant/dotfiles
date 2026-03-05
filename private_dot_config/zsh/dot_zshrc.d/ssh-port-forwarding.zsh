#!/usr/bin/env zsh
#
# ssh-port-forwarding.zsh - SSH port forwarding helpers
#

# Forward local port(s) to remote host
# Usage: fip <host> <port1> [port2] ...
fip() {
  (( $# < 2 )) && echo "Usage: fip <host> <port1> [port2] ..." && return 1
  local host="$1"
  shift
  for port in "$@"; do
    ssh -f -N -L "$port:localhost:$port" "$host" && echo "Forwarding localhost:$port -> $host:$port"
  done
}

# Disconnect port forwarding
# Usage: dip <port1> [port2] ...
dip() {
  (( $# == 0 )) && echo "Usage: dip <port1> [port2] ..." && return 1
  for port in "$@"; do
    pkill -f "ssh.*-L $port:localhost:$port" && echo "Stopped forwarding port $port" || echo "No forwarding on port $port"
  done
}

# List active port forwards
lip() {
  pgrep -af "ssh.*-L [0-9]+:localhost:[0-9]+" || echo "No active forwards"
}
