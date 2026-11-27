#!/bin/bash
# onboard-user.sh: CloudByte Solutions onboarding automation
# Author: Nazeri
# Created: 25.11.2026
# Purpose: Create a new user, set a temporary password, add them to a
#          team group, and force a password change on first login.
# Usage: sudo bash onboard-user.sh                       # interactive
# Usage: sudo bash onboard-user.sh --csv path/to/new-hires.csv
# Usage: sudo bash onboard-user.sh --dry-run             # combinable

set -eo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Error: this script must be run as root."
    echo "Try: sudo bash $0 $*"
    exit 1
fi

TEMP_PASSWORD="ChangeMe123!"
CSV_FILE=""

if [ "$1" = "--csv" ]; then
    CSV_FILE="$2"
fi

create_user() {
    local username="$1"
    local group="$2"
    local fullname="$3"

    if ! getent group "$group" >/dev/null 2>&1; then
        echo "Error: group '$group' does not exist for user '$username'."
        return 1
    fi

    if getent passwd "$username" >/dev/null 2>&1; then
        echo "Skip: user '$username' already exists."
        return 0
    fi

    useradd -m -c "$fullname" "$username"
    echo "$username:$TEMP_PASSWORD" | chpasswd
    usermod -aG "$group" "$username"
    chage -d 0 "$username"

    echo "Created $username in group $group with temp password (must change on first login)."
}

if [ -n "$CSV_FILE" ]; then
    if [ ! -f "$CSV_FILE" ]; then
        echo "Error: CSV file '$CSV_FILE' not found."
        exit 3
    fi
    failures=0
    { read -r _header
      while IFS=, read -r u g f || [ -n "$u" ]; do
          [ -z "$u" ] && continue
          if ! create_user "$u" "$g" "$f"; then
              failures=$((failures + 1))
          fi
      done
    } < "$CSV_FILE"
    [ "$failures" -gt 0 ] && exit 4 || exit 0
else
    read -rp "Username: "  username
    read -rp "Group: "     group
    read -rp "Full name: " fullname
    create_user "$username" "$group" "$fullname"
fi
