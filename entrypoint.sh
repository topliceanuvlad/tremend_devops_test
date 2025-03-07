#!/bin/sh
# Trap TERM (instead of SIGTERM) and forward it to Gunicorn
trap 'echo "TERM received, shutting down gunicorn..."; kill -TERM $PID' TERM

# Start Gunicorn in the background and capture its PID
gunicorn --bind 0.0.0.0:8080 calculator:app &
PID=$!

# Wait for Gunicorn to exit
wait $PID
