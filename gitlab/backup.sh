#!/bin/bash

# Log file location
LOG_FILE="/var/log/gitlab_backup.log"

APP_NAME=gitlab

CONTAINER_NAME=gitlab

# Function to log messages
log_message() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
}


# Define the backup directory inside the GitLab container
BACKUP_SOURCE_DIR="/var/opt/${APP_NAME}/backups"

# Define the target directory on the host where you want to store the backups
BACKUP_TARGET_DIR="/backups/${APP_NAME}"

# Check if a timestamp argument is provided
if [ -z "$1" ]; then
    echo "Error: No timestamp provided."
    echo "Usage: $0 <timestamp>"
    exit 1
fi

# Use the provided timestamp
TIMESTAMP="$1"


# Step 1: Remove previous backups
log_message "Removing previous backups from $BACKUP_SOURCE_DIR in container $CONTAINER_NAME."
docker exec $CONTAINER_NAME /bin/bash -c "rm -rf $BACKUP_SOURCE_DIR/*.tar"
log_message "Previous backups removed."
echo "Previous backups removed."

# Start the backup process
log_message "Starting ${APP_NAME} backup process."
echo "Starting ${APP_NAME} backup process."
# Run GitLab backup
docker exec $CONTAINER_NAME gitlab-rake gitlab:backup:create
log_message "GitLab backup created inside the container."

# Create a backup directory with the timestamp
BACKUP_DIR="$BACKUP_TARGET_DIR/$TIMESTAMP"
mkdir -p "$BACKUP_DIR"
log_message "Created local backup directory: $BACKUP_DIR."

# Copy the latest backup to the target directory
LATEST_BACKUP=$(docker exec $CONTAINER_NAME sh -c "ls -1t $BACKUP_SOURCE_DIR | head -n 1")
docker cp $CONTAINER_NAME:"$BACKUP_SOURCE_DIR/$LATEST_BACKUP" "$BACKUP_DIR"
log_message "Copied latest GitLab backup ($LATEST_BACKUP) to: $BACKUP_DIR."

# Copy gitlab.rb and gitlab-secrets.json to the timestamped folder
docker cp $CONTAINER_NAME:/etc/gitlab/gitlab.rb "$BACKUP_DIR/gitlab.rb"
docker cp $CONTAINER_NAME:/etc/gitlab/gitlab-secrets.json "$BACKUP_DIR/gitlab-secrets.json"
log_message "Copied gitlab.rb and gitlab-secrets.json to: $BACKUP_DIR."

# Print a success message
log_message "GitLab backup process completed successfully."
echo "GitLab backup completed, saved to: $BACKUP_DIR."
