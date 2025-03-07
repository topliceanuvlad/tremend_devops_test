#!/bin/sh
# Replace the current shell with gunicorn so it becomes PID1.
# This allows gunicorn's built-in graceful shutdown to work when Docker stops the container.
exec gunicorn --bind 0.0.0.0:8080 calculator:app
