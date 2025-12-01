#!/usr/bin/env zsh

# ─────────────────────────────────────────────
# FLAG HANDLING
# ─────────────────────────────────────────────

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  cat << EOF

📘 docs — interactive cheat sheet + TLDR viewer

Usage:
  docs                # Open selector
  docs --help, -h     # Show this help

Inside selector:
  Choose a topic (language or command)
  Then type your query (loop until you're satisfied)

Examples:
  docs
    -> select python
    -> Query: sort list

  docs
    -> select git
    -> Query: submodule add

Features:
  • TLDR for commands
  • cheat.sh for languages
  • Google fallback
  • Satisfaction loop (try new queries without reselecting topic)
  • Caching (no history)

EOF
  exit 0
fi

# ─────────────────────────────────────────────
# CONFIG
# ─────────────────────────────────────────────

LANGUAGES_STR="bash sh zsh python js node ts java cpp c lua"
COMMANDS_STR="git find sed awk xargs mv curl tr cat ls chmod chown"

all_options_list=$(
  printf "%s %s" "$LANGUAGES_STR" "$COMMANDS_STR" | tr ' ' '\n'
)

CACHE_DIR="$HOME/.cache/cht_cache"
mkdir -p "$CACHE_DIR"

is_command() {
  echo "$COMMANDS_STR" | grep -wqs "$1"
}

# ─────────────────────────────────────────────
# FZF TOPIC SELECTOR
# ─────────────────────────────────────────────

selected=$(
  printf '%s\n' "$all_options_list" |
    fzf --prompt="Select topic: " \
        --height=50%
)

[[ -z "$selected" ]] && { echo "Cancelled."; exit 1; }

# ─────────────────────────────────────────────
# QUERY LOOP
# ─────────────────────────────────────────────

while true; do

  read "query?Query: "
  [[ -z "$query" ]] && { echo "No query entered."; exit 1; }

  encoded_query=${query// /+}
  cache_file="$CACHE_DIR/${selected}_${encoded_query}.cache"

  show_output() {
    if command -v bat >/dev/null; then
      bat --plain --language=md
    else
      cat
    fi
  }

  # Cache
  if [[ -f "$cache_file" ]]; then
    cat "$cache_file" | show_output
  else

    TMP_TLDR="/tmp/docs_tldr_$$"

    # TLDR if command
    if is_command "$selected"; then
      if tldr "$selected" >"$TMP_TLDR" 2>/dev/null; then
        if grep -iq "$query" "$TMP_TLDR"; then
          cat "$TMP_TLDR" | tee "$cache_file" | show_output
          goto_show_satisfaction
        fi
      fi
    fi

    # cheat.sh
    try_cheat() {
      local url="$1"
      local response=$(curl -s "$url")

      if echo "$response" | grep -qi "<!doctype html>"; then return 1; fi
      if echo "$response" | grep -qi "Unknown topic"; then return 1; fi

      echo "$response" | tee "$cache_file" | show_output
      return 0
    }

    if try_cheat "https://cht.sh/$selected/$encoded_query"; then
      :
    elif try_cheat "https://cht.sh/$selected~$encoded_query"; then
      :
    else
      echo ""
      echo "────────────────────────────────────────────"
      echo " ❌ No TLDR or cheat.sh match for \"$query\""
      echo "────────────────────────────────────────────"
      echo ""

      search="${selected} ${query}"
      search="${search// /+}"
      url="https://www.google.com/search?q=$search"

      echo "🌐 Opening: $url"
      echo ""

      if command -v open >/dev/null; then
        open "$url"
      else
        xdg-open "$url"
      fi
    fi
  fi

  # ─────────────────────────────────────────────
  # SATISFACTION CHECK
  # ─────────────────────────────────────────────

  echo ""
  read "ans?Are you happy with this result? (y/n): "

  case "$ans" in
    y|Y|yes|YES)
      echo "Done."
      exit 0
      ;;
    n|N|no|NO)
      echo "Okay, try again..."
      echo ""
      continue
      ;;
    *)
      echo "Unknown response. Exiting."
      exit 0
      ;;
  esac

done
