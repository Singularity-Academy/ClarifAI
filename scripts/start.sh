#!/bin/bash

# Store the base directory (project root)
BASE_DIR="$(pwd)"
echo "Running from directory: $BASE_DIR"

# Create logs directory if it doesn't exist
mkdir -p "$BASE_DIR/logs"

# File to store PIDs
PID_FILE="$BASE_DIR/logs/app.pid"

# Clean up function to kill all processes
cleanup() {
  echo "Shutting down all services..."
  if [ -f "$PID_FILE" ]; then
    while read pid; do
      echo "Killing process $pid"
      kill -9 $pid 2>/dev/null || true
    done < "$PID_FILE"
    rm "$PID_FILE"
  fi
  echo "All services stopped"
  exit 0
}

# Register the cleanup function for SIGINT and SIGTERM
trap cleanup SIGINT SIGTERM

# Remove old PID file if it exists
rm -f "$PID_FILE"

echo "Starting all services..."

# Start frontend (prevent browser from opening)
echo "Starting frontend..."
cd "$BASE_DIR/frontend" && BROWSER=none npm start > "$BASE_DIR/logs/frontend.log" 2>&1 &
FRONTEND_PID=$!
echo $FRONTEND_PID > "$PID_FILE"
echo "Frontend started with PID $FRONTEND_PID"

# Start backend
echo "Starting backend..."
cd "$BASE_DIR/backend" && go run . > "$BASE_DIR/logs/backend.log" 2>&1 &
BACKEND_PID=$!
echo $BACKEND_PID >> "$PID_FILE"
echo "Backend started with PID $BACKEND_PID"

# Start Python service
echo "Starting AI engine..."
cd "$BASE_DIR" && python3 run.py --log-level TRACE> "$BASE_DIR/logs/python.log" 2>&1 &
PYTHON_PID=$!
echo $PYTHON_PID >> "$PID_FILE"
echo "AI engine started with PID $PYTHON_PID"

# Start Caddy server
echo "Starting Caddy server..."
cd "$BASE_DIR" && caddy start > "$BASE_DIR/logs/caddy.log" 2>&1 &
CADDY_PID=$!
echo $CADDY_PID >> "$PID_FILE"
echo "Caddy server started with PID $CADDY_PID"

echo "All services are running. Press Ctrl+C to stop all services."
echo "Logs are available in the logs directory"
echo "Application running on http://localhost:1298"

# Wait for any process to exit
wait $FRONTEND_PID $BACKEND_PID $PYTHON_PID $CADDY_PID

# If we get here, one of the processes has exited
echo "A service has stopped unexpectedly. Shutting down all services..."
cleanup
