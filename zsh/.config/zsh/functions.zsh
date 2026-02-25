# Create directory and cd into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Extract any archive
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2) tar xjf "$1" ;;
      *.tar.gz)  tar xzf "$1" ;;
      *.tar.xz)  tar xJf "$1" ;;
      *.bz2)     bunzip2 "$1" ;;
      *.gz)      gunzip "$1" ;;
      *.tar)     tar xf "$1" ;;
      *.tbz2)    tar xjf "$1" ;;
      *.tgz)     tar xzf "$1" ;;
      *.zip)     unzip "$1" ;;
      *.Z)       uncompress "$1" ;;
      *.7z)      7z x "$1" ;;
      *)         echo "'$1' cannot be extracted" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Find and kill process by name
fkill() {
  local pid
  pid=$(ps aux | grep -i "$1" | grep -v grep | awk '{print $2}')
  if [ -n "$pid" ]; then
    echo "Killing process $pid"
    kill -9 "$pid"
  else
    echo "No process found matching '$1'"
  fi
}

# Quick notes
note() {
  local notes_dir="$HOME/notes"
  mkdir -p "$notes_dir"
  if [ -z "$1" ]; then
    $EDITOR "$notes_dir"
  else
    $EDITOR "$notes_dir/$1.md"
  fi
}
