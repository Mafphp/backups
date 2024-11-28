#!/bin/bash

# Application name
APP_NAME="gitlab"

# Log file location
LOG_FILE="/var/log/${APP_NAME}_sync.log"

# Maximum number of backups to retain
MAX_BACKUPS=7

# Google Drive path variable
GDRIVE_BACKUP_PATH="gdrive:/backups/${APP_NAME}"

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
mkdir -p "$BACKUP_DIR"
log_message "Created local backup directory: $BACKUP_DIR."

# Sync the backup to Google Drive
rclone mkdir "$GDRIVE_BACKUP_PATH/$TIMESTAMP" # Create the directory on Google Drive
rclone copy "$BACKUP_DIR" "$GDRIVE_BACKUP_PATH/$TIMESTAMP"
log_message "Synced backup to Google Drive: $GDRIVE_BACKUP_PATH/$TIMESTAMP."

# Remove old backups from Google Drive
REMOTE_BACKUPS=$(rclone lsf "$GDRIVE_BACKUP_PATH/" | sort -r | tail -n +$(($MAX_BACKUPS + 1)))
for BACKUP in $REMOTE_BACKUPS; do
    # Add debugging information
    echo "Attempting to delete: $GDRIVE_BACKUP_PATH/$BACKUP"
    rclone purge "$GDRIVE_BACKUP_PATH/$BACKUP"
    if [ $? -eq 0 ]; then
        echo "Removed old backup from Google Drive: $BACKUP"
        log_message "Removed old backup from Google Drive: $BACKUP"
    else
        echo "Failed to remove old backup from Google Drive: $BACKUP"
        log_message "Failed to remove old backup from Google Drive: $BACKUP"
    fi
done

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
log_message "Backup process for ${APP_NAME} completed successfully."
echo "${APP_NAME} backup completed, saved to: $BACKUP_DIR, and synced to Google Drive."