# Shell helpers shared by Bash and Zsh.

# Preview the current Hugo site on an address assigned to this machine.
hugo-lan() {
  if ! command -v hugo >/dev/null 2>&1; then
    printf 'hugo is not installed or is not on PATH.\n' >&2
    return 127
  fi

  local host_ip a b c d
  local ipv4_pattern='^[0-9]{1,3}(\.[0-9]{1,3}){3}$'

  while true; do
    printf "This machine's LAN IPv4 address (blank to cancel): "
    if ! IFS= read -r host_ip; then
      printf '\n'
      return 1
    fi
    [[ -n "$host_ip" ]] || return 1

    if [[ "$host_ip" =~ $ipv4_pattern ]]; then
      IFS=. read -r a b c d <<<"$host_ip"
      if ((10#$a <= 255 && 10#$b <= 255 && 10#$c <= 255 && 10#$d <= 255)); then
        host_ip="$((10#$a)).$((10#$b)).$((10#$c)).$((10#$d))"
        [[ "$host_ip" != '0.0.0.0' ]] && break
      fi
    fi
    printf 'Enter a valid host IPv4 address, such as 192.168.1.10.\n' >&2
  done

  printf 'Preview: http://%s:1313/ (drafts included; Ctrl-C to stop)\n' "$host_ip"
  command hugo server -D --bind "$host_ip" --baseURL "http://$host_ip:1313/" --port 1313
}
