#!/bin/bash
############################################################
# @author Elias De Hondt, Kobe Wijnants, Quinten Willekens #
# @since 18/09/2024                                        #
############################################################

reset="\e[0m"    # Reset
red="\e[0;31m"   # Red
green="\e[0;32m" # Green

# Functie: Error afhandeling.
function error_exit() {
  echo -e "\n*\n* ${red}$1${reset}\n*\n* Exiting script.\n"
  exit 1
}

# Functie: Succes afhandeling.
function success() {
  echo -e "\n*\n* ${green}$1${reset}\n*"
}

# SPINNER with PID check
function loading_icon() {
  local loading_message="${1}"
  local pid="${2}"
  local elapsed=0
  local loading_animation=('—' "\\" '|' '/')

  echo
  echo -n "${loading_message} "

  # Hide the cursor
  tput civis
  trap "tput cnorm" EXIT

  # Loop until the load interval is reached or the process ends
  while true; do
    # Check if the process is still running
    if ! kill -0 "${pid}" 2>/dev/null; then
      break
    fi

    for frame in "${loading_animation[@]}"; do
      printf "%s\b" "${frame}"
      sleep 0.25
    done
    elapsed=$((elapsed + 1))
  done

  # Reset cursor and print a newline
  tput cnorm
  printf " \b\n"
}
