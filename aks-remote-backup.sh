#!/bin/sh
set -e

# Important locations
TEMPLOCATION="/tmp"
SNEEZYLIB="/home/sneezy"
BACKUPDIR="."
POD=pod/sneezymud-0
NAMESPACE="-ndefault"

# Setting the backup filename
FNAME="$BACKUPDIR/sneezy-backup-`date +%s`.tar"

# Perform the backup
kubectl "$NAMESPACE" exec -t pod/sneezy-db-0 -- mysqldump -h sneezy-db -u root -p111111 --databases sneezy immortal > "$TEMPLOCATION/dbdump.sql"
(kubectl "$NAMESPACE" exec -t "$POD" -c sneezymud -- tar -c --exclude='core' -C "$SNEEZYLIB" lib || true ) > "$FNAME"
tar --owner=sneezy:1000 --group=sneezy:1000 -rf "$FNAME" -C "$TEMPLOCATION" dbdump.sql

# Remove our temps
rm "$TEMPLOCATION/dbdump.sql"

# xz "$FNAME"
gzip "$FNAME"

# Push the backup to any online repositories.
#drive push -no-prompt -quiet -destination backups "$FNAME"
kubectl cp -c sneezy-webclient "$FNAME".gz sneezymud-0:/usr/share/nginx/html/static/sneezy-backup.tar.gz
