#!/bin/bash
# install.sh - One command installer for Raycast Enforced Focus

set -e
USERNAME=$(whoami)

echo "🎯 Installing Simple Enforced Focus..."
echo "This will block distracting sites/apps whenever your Mac is awake."
echo

# Create directories
mkdir -p ~/Scripts
mkdir -p ~/Library/LaunchAgents

# Create the main script
cat > ~/Scripts/simple-enforced-focus.sh << 'EOF'
#!/bin/bash
# Simple enforced focus that runs whenever Mac is awake

# Configuration - EDIT THESE TO CUSTOMIZE
FOCUS_GOAL="Always%20Focused"
FOCUS_CATEGORIES="blocking"
FOCUS_DURATION="43200" # 12 hours
FOCUS_MODE="block"
CHECK_INTERVAL=60 # Check every 60 seconds
LOG_FILE="$HOME/Library/Logs/simple-enforced-focus.log"

# Logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" | tee -a "$LOG_FILE"
}

# Check if Raycast is running
is_raycast_running() {
    pgrep -x "Raycast" >/dev/null
}

# Start Raycast if not running
ensure_raycast() {
    if ! is_raycast_running; then
        log "Starting Raycast..."
        open -a "Raycast"
        sleep 3
    fi
}

# Check if focus session is currently active
is_focus_active() {
    # Check if Raycast Focus UI elements are visible
    # Look for focus-related processes or UI indicators
    if pgrep -f "RaycastFocus" >/dev/null 2>&1; then
        return 0
    fi
    
    # Alternative: Check for focus session via AppleScript
    local result=$(osascript -e '
        tell application "System Events"
            try
                -- Look for Raycast focus indicators in menu bar or floating windows
                if exists (processes where name is "Raycast") then
                    tell process "Raycast"
                        -- Check if focus session UI is visible
                        if exists window "Raycast" then
                            return "active"
                        end if
                        -- Check for focus menu bar item
                        if exists menu bar item "Raycast" of menu bar 1 then
                            return "active"
                        end if
                    end tell
                end if
                return "inactive"
            on error
                return "unknown"
            end try
        end tell
    ' 2>/dev/null)
    
    if [[ "$result" == "active" ]]; then
        return 0
    else
        return 1
    fi
}

# Start focus session only if not already active
start_focus() {
    ensure_raycast
    
    # Check if focus is already active to avoid annoying red glow
    if is_focus_active; then
        log "Focus session already active, skipping start"
        return 0
    fi
    
    log "Starting new focus session"
    local url="raycast://focus/start?goal=$FOCUS_GOAL&categories=$FOCUS_CATEGORIES&duration=$FOCUS_DURATION&mode=$FOCUS_MODE"
    open "$url" 2>/dev/null
    
    # Give it a moment to start
    sleep 2
}

# Main monitoring loop
main() {
    log "Simple enforced focus monitor started (PID: $$)"
    
    cleanup() {
        log "Shutting down enforced focus monitor"
        if is_raycast_running; then
            log "Stopping focus session..."
            open "raycast://focus/complete" 2>/dev/null
        fi
        exit 0
    }
    
    trap cleanup SIGTERM SIGINT
    
    log "Starting initial focus session..."
    start_focus
    
    while true; do
        # Only try to start focus if it's not already active
        if ! is_focus_active; then
            log "Focus session not active, starting..."
            start_focus
        fi
        
        sleep $CHECK_INTERVAL
    done
}

case "$1" in
    "daemon"|"")
        main
        ;;
    "start")
        log "Manual start requested"
        start_focus
        ;;
    "stop")
        log "Manual stop requested"
        if is_raycast_running; then
            open "raycast://focus/complete"
        fi
        ;;
    "status")
        if is_raycast_running; then
            echo "Raycast is running"
        else
            echo "Raycast is not running"
        fi
        if pgrep -f "simple-enforced-focus.sh" >/dev/null; then
            echo "Focus monitor is running"
        else
            echo "Focus monitor is not running"
        fi
        ;;
    *)
        echo "Usage: $0 [daemon|start|stop|status]"
        exit 1
        ;;
esac
EOF

chmod +x ~/Scripts/simple-enforced-focus.sh

# Create the LaunchAgent
cat > ~/Library/LaunchAgents/com.user.simple.enforced.focus.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.simple.enforced.focus</string>
    
    <key>Program</key>
    <string>/Users/$USERNAME/Scripts/simple-enforced-focus.sh</string>
    
    <key>KeepAlive</key>
    <true/>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>StandardOutPath</key>
    <string>/Users/$USERNAME/Library/Logs/simple-enforced-focus-out.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/$USERNAME/Library/Logs/simple-enforced-focus-err.log</string>
    
    <key>LimitLoadToSessionType</key>
    <string>Aqua</string>
</dict>
</plist>
EOF

# Load the LaunchAgent
launchctl load ~/Library/LaunchAgents/com.user.simple.enforced.focus.plist

echo "✅ Installation complete!"
echo
echo "🎯 Enforced Focus is now running and will:"
echo "   • Start blocking when you log in"
echo "   • Restart automatically if you cancel it"
echo "   • Work across sleep/wake cycles"
echo
echo "📝 Management commands:"
echo "   ~/Scripts/simple-enforced-focus.sh status   # Check status"
echo "   ~/Scripts/simple-enforced-focus.sh stop     # Stop current session"
echo "   tail -f ~/Library/Logs/simple-enforced-focus.log  # View logs"
echo
echo "🛑 To uninstall:"
echo "   launchctl unload ~/Library/LaunchAgents/com.user.simple.enforced.focus.plist"
echo "   rm ~/Library/LaunchAgents/com.user.simple.enforced.focus.plist"
echo "   rm ~/Scripts/simple-enforced-focus.sh"
echo
echo "🔧 To customize what gets blocked, edit:"
echo "   ~/Scripts/simple-enforced-focus.sh"
echo "   (Look for FOCUS_CATEGORIES at the top)"
echo
