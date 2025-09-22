This project is a Work in Progress!

# Raycast Enforced Focus

Automatically enforces Raycast focus sessions whenever your Mac is awake. Perfect for staying focused by blocking distracting websites and apps.

## Features

- 🎯 **Auto-starts** focus sessions when you're using your Mac
- 🔄 **Auto-restarts** if you try to cancel (every 60 seconds)
- 😴 **Survives sleep/wake** cycles automatically
- 🚀 **Simple setup** - one command installation
- ⚙️ **Customizable** - easily change what gets blocked

## Quick Install
```bash
curl -s https://raw.githubusercontent.com/Pedroecz17/focus-enforcer-raycast/refs/heads/main/install.sh | bash
```
## What Gets Blocked

By default: `social,news,entertainment,gaming,youtube`

## Management

```bash
# Check status
~/Scripts/simple-enforced-focus.sh status

# Stop current session (restarts in 60s)
~/Scripts/simple-enforced-focus.sh stop

# View logs
tail -f ~/Library/Logs/simple-enforced-focus.log
```

## Customization
Edit `~/Scripts/simple-enforced-focus.sh` and change the `FOCUS_CATEGORIES` variable.

## Uninstall
```bash
launchctl unload ~/Library/LaunchAgents/com.user.simple.enforced.focus.plist
rm ~/Library/LaunchAgents/com.user.simple.enforced.focus.plist
rm ~/Scripts/simple-enforced-focus.sh
```

### Requirements

- macOS only
- Raycast 
