#!/bin/bash
set -e

# ======= USER LIST (username:password) =======
declare -A USERS
USERS=(
  ["aiub"]="cloudly@aiub" 
)

SSH_PORT="22"

echo "=== Creating users and setting passwords..."
for USER in "${!USERS[@]}"; do
  if id "$USER" &>/dev/null; then
    echo "User $USER already exists."
  else
    useradd -m -s /bin/bash "$USER"
    echo "Created user $USER"
  fi

  echo "$USER:${USERS[$USER]}" | chpasswd
  usermod -aG sudo "$USER"
  echo "Set password and added $USER to sudo group."
done

echo "=== Configuring sudoers (no password for sudo)..."
echo "%sudo ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/90-nopasswd
chmod 440 /etc/sudoers.d/90-nopasswd

echo "=== Disabling UFW firewall (if enabled)..."
ufw disable 2>/dev/null || true

echo "=== Updating SSH config..."
SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP="/etc/ssh/sshd_config.backup_$(date +%F-%H%M%S)"
cp "$SSHD_CONFIG" "$BACKUP"
echo "Backup created at $BACKUP"

# Ensure Port 333
if grep -qE "^#?Port " $SSHD_CONFIG; then
  sed -i "s/^#\?Port .*/Port $SSH_PORT/" $SSHD_CONFIG
else
  echo "Port $SSH_PORT" >> $SSHD_CONFIG
fi

# Enable password authentication
if grep -qE "^#?PasswordAuthentication" $SSHD_CONFIG; then
  sed -i "s/^#\?PasswordAuthentication.*/PasswordAuthentication yes/" $SSHD_CONFIG
else
  echo "PasswordAuthentication yes" >> $SSHD_CONFIG
fi

# Disable conflicting configs in /etc/ssh/sshd_config.d
if [ -d /etc/ssh/sshd_config.d ]; then
  for FILE in /etc/ssh/sshd_config.d/*; do
    sed -i "s/^PasswordAuthentication.*/#PasswordAuthentication no/" "$FILE"
  done
fi

echo "=== Restarting SSH service..."
systemctl restart ssh
systemctl status ssh --no-pager

echo "=== DONE! Summary:"
echo "- Users created: ${!USERS[@]}"
echo "- All added to sudo group"
echo "- SSH port set to $SSH_PORT"
echo "- PasswordAuthentication enabled"
echo "- UFW firewall disabled"
echo "- Backup SSH config: $BACKUP"
echo ""
echo "✅ Connect like this:"
echo "ssh -p $SSH_PORT <username>@<server-ip>"
  echo "Port $SSH_PORT" >> $SSHD_CONFIG
fi

# Enable password authentication
if grep -qE "^#?PasswordAuthentication" $SSHD_CONFIG; then
  sed -i "s/^#\?PasswordAuthentication.*/PasswordAuthentication yes/" $SSHD_CONFIG
else
  echo "PasswordAuthentication yes" >> $SSHD_CONFIG
fi

# Disable conflicting configs in /etc/ssh/sshd_config.d
if [ -d /etc/ssh/sshd_config.d ]; then
  for FILE in /etc/ssh/sshd_config.d/*; do
    sed -i "s/^PasswordAuthentication.*/#PasswordAuthentication no/" "$FILE"
  done
fi

echo "=== Restarting SSH service..."
systemctl restart ssh
systemctl status ssh --no-pager

echo "=== DONE! Summary:"
echo "- Users created: ${!USERS[@]}"
echo "- All added to sudo group"
echo "- SSH port set to $SSH_PORT"
echo "- PasswordAuthentication enabled"
echo "- UFW firewall disabled"
echo "- Backup SSH config: $BACKUP"
echo ""
echo "✅ Connect like this:"
echo "ssh -p $SSH_PORT <username>@<server-ip>"
