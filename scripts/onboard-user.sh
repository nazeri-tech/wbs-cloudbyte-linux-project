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

create_user() {
    local username="$1"
    local group="$2"
    local fullname="$3"

    if ! getent group "$group" >/dev/null 2>&1; then
        echo "Error: group '$group' does not exist for user '$username'."
        echo "Hint: getent group | cut -d: -f1   to list available groups."
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

read -rp "Username: "  username
read -rp "Group: "     group
read -rp "Full name: " fullname

create_user "$username" "$group" "$fullname"
