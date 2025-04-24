#!/bin/bash

SHARED_FILE="/etc/shared-aliases.sh"
SOURCE_LINE='[ -f /etc/shared-aliases.sh ] && . /etc/shared-aliases.sh'

# Check master file exists
if [ ! -f "$SHARED_FILE" ]; then
    echo "❌ Master alias file $SHARED_FILE not found."
    exit 1
fi

echo "[+] Syncing $SHARED_FILE to all containers..."

for CTID in $(pct list | awk 'NR>1 {print $1}'); do
    echo "→ Working on container $CTID..."

    # Push alias file to container
    pct push "$CTID" "$SHARED_FILE" /etc/shared-aliases.sh > /dev/null 2>&1 || {
        echo "   ⚠️ Failed to push alias file to container $CTID"
        continue
    }

    # Pull current .bashrc
    LOCAL_TMP="/tmp/bashrc_$CTID"
    pct pull "$CTID" /root/.bashrc "$LOCAL_TMP" 2>/dev/null || {
        echo "   ⚠️ Could not pull .bashrc from container $CTID"
        continue
    }

    # Only append if not already present
    if ! grep -Fxq "$SOURCE_LINE" "$LOCAL_TMP"; then
        echo "$SOURCE_LINE" >> "$LOCAL_TMP"
        echo "   ✅ Appended source line to .bashrc"
    else
        echo "   ✅ Source line already exists"
    fi

    # Push updated .bashrc back
    pct push "$CTID" "$LOCAL_TMP" /root/.bashrc > /dev/null 2>&1
    rm -f "$LOCAL_TMP"
done


#!/bin/bash

# Desired settings
LOCALE="en_GB.UTF-8"
TIMEZONE="Europe/London"
LOCALE_CONF_CONTENT="LANG=$LOCALE\nLANGUAGE=en_GB:en\nLC_ALL=$LOCALE"

# --- Update Host ---
echo "🖥️ Updating Proxmox host timezone and locale..."

# Set timezone
timedatectl set-timezone "$TIMEZONE"

# Enable locale in /etc/locale.gen
sed -i 's/^# *\(en_GB.UTF-8 UTF-8\)/\1/' /etc/locale.gen

# Generate and apply
locale-gen
update-locale LANG="$LOCALE" LC_ALL="$LOCALE" LANGUAGE="en_GB:en"

echo "✅ Host set to $LOCALE and timezone $TIMEZONE"

# --- Function to configure container ---
configure_container() {
    CTID="$1"
    echo -e "\n🔧 Configuring container $CTID..."

    # Install locales and tzdata silently
    pct exec "$CTID" -- bash -c "apt-get update -qq && apt-get install -y locales tzdata >/dev/null"

    # Uncomment en_GB.UTF-8 in locale.gen
    pct exec "$CTID" -- sed -i 's/^# *\(en_GB.UTF-8 UTF-8\)/\1/' /etc/locale.gen

    # Generate and apply locale
    pct exec "$CTID" -- locale-gen
    pct exec "$CTID" -- update-locale LANG="$LOCALE" LC_ALL="$LOCALE" LANGUAGE="en_GB:en"
    pct exec "$CTID" -- bash -c "echo -e '$LOCALE_CONF_CONTENT' > /etc/default/locale"

    # Set timezone
    pct exec "$CTID" -- ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    pct exec "$CTID" -- bash -c "echo $TIMEZONE > /etc/timezone"
    pct exec "$CTID" -- dpkg-reconfigure -f noninteractive tzdata

    echo "✅ $CTID: UK locale & timezone set"
}

# Get running containers only
running_cts=$(pct list | awk '$2 == "running" {print $1}')
if [ -z "$running_cts" ]; then
    echo "⚠️  No running containers found."
else
    for CTID in $running_cts; do
        configure_container "$CTID"
    done
fi

echo -e "\n🎉 All done! Host and running containers now use en_GB.UTF-8 and Europe/London timezone."
