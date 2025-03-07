#!/bin/sh
# Trap SIGTERM and forward it to the Gunicorn process
trap 'echo "SIGTERM received, shutting down gunicorn..."; kill -TERM $PID' SIGTERM

# Start Gunicorn in the background and capture its PID
gunicorn --bind 0.0.0.0:8080 calculator:app &
PID=$!

# Wait for Gunicorn to exit
wait $PID
