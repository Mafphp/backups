#!/bin/bash

# Application name
APP_NAME="gitlab"

# Log file location
LOG_FILE="/var/log/${APP_NAME}_sync.log"

# Maximum number of backups to retain
MAX_BACKUPS=7

# Function to log messages
log_message() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
}

# Check if a timestamp argument is provided
if [ -z "$1" ]; then
    echo "Error: No timestamp provided."
    echo "Usage: $0 <timestamp>"
    exit 1
fi

# Use the provided timestamp
TIMESTAMP="$1"

# Define the target directory on the host where you want to store the backups
BACKUP_TARGET_DIR="/backups/${APP_NAME}"

# Create a backup directory with the timestamp
BACKUP_DIR="$BACKUP_TARGET_DIR/$TIMESTAMP"

# Sync the backup to Google Drive
cd /srv/restic && docker compose run --rm restic backup /backup/$TIMESTAMP
cd /srv/restic && docker compose run --rm restic forget --prune --keep-weekly 4 --keep-monthly 12 --keep-yearly 10

# Remove old backups from local disk
LOCAL_BACKUPS=$(ls -1d $BACKUP_TARGET_DIR/*/ | sort -r | tail -n +$(($MAX_BACKUPS + 1)))
for BACKUP in $LOCAL_BACKUPS; do
    # Add debugging information
    echo "Attempting to delete: $BACKUP"
    rm -rf "$BACKUP"
    if [ $? -eq 0 ]; then
        echo "Removed old backup from local disk: $BACKUP"
        log_message "Removed old backup from local disk: $BACKUP"
    else
        echo "Failed to remove old backup from local disk: $BACKUP"
        log_message "Failed to remove old backup from local disk: $BACKUP"
    fi
done

# Print a success message
log_message "Sync process for ${APP_NAME} completed successfully."
echo "${APP_NAME} Sync completed, saved to: $BACKUP_DIR, and synced to Minio."