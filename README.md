# Office Internet Ping & Telegram Alert Bot (`mss-ping-tgbot`)

A lightweight, automated Bash-based network monitoring tool that pings an office IP address and sends real-time Telegram notifications when the internet connection goes down or recovers.

---

## 🚀 Features

- **Real-Time Outage & Recovery Alerts**: Alerts instantly when connection drops (`🚨 DOWN`) and when it comes back (`✅ RECOVERED`).
- **No Spam (State Transition Logic)**: Uses a state file to ensure alerts are sent only once per outage and once upon recovery, keeping your group chat clean.
- **Delivery Verification**: Only updates the alert state when Telegram's API successfully acknowledges receipt (`--fail`).
- **Network Timeout Safeguards**: Includes ICMP packet deadlines (`-W 2 -w 10`) to prevent hung cron or systemd jobs during severe network drops.
- **Secure Configuration**: Sensitive bot tokens and chat IDs are stored in `.env` (excluded by `.gitignore`).
- **Manual Test Mode**: Built-in `--test` flag to verify connectivity and messaging anytime with a single command.

---

## 📁 Project Structure

```text
mss-ping-tgbot/
├── bot.sh          # Main monitoring and notification script
├── .env            # Environment configuration (Contains secrets - DO NOT COMMIT)
├── .env.example    # Configuration template
├── .gitignore      # Protects .env and temporary files
└── README.md       # Project documentation
```

---

## 🛠️ Prerequisites

- **Operating System**: Linux / Unix
- **Required Packages**:
  - `bash` (v4.0+)
  - `curl`
  - `iputils-ping` (standard `ping` command)

---

## ⚙️ Setup & Configuration

### 1. Obtain Telegram Bot Credentials

#### Step A: Get Bot API Token via `@BotFather`
1. Open Telegram and search for [@BotFather](https://t.me/BotFather).
2. Send `/newbot` and follow the instructions to set up your bot name and username.
3. BotFather will provide your **HTTP API Token** (e.g., `123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ`). Keep this safe!

#### Step B: Get Chat Room ID via `@getidsbot`
To find the Chat ID of your Telegram group where notifications should be posted:
1. Open Telegram and search for [@getidsbot](https://t.me/getidsbot).
2. **Invite `@getidsbot` to your Telegram group**:
   - Add/invite `@getidsbot` into the target group.
   - Upon joining (or when a message is sent in the group), `@getidsbot` will reply with the chat details including the **Chat ID**.
   - Copy the Chat ID (for Telegram groups/supergroups, this is a negative number, e.g., `-100xxxxxxxxxx` or `-xxxxxxxxxx`). **Include the leading minus sign (`-`)**.
   - Remove `@getidsbot` from your group once you have the ID.
3. **Add your own bot** created in Step A to the group, and grant it permissions to send messages.

> [!TIP]
> If you want alerts sent to your **personal Telegram chat** instead of a group, open a direct message with [@getidsbot](https://t.me/getidsbot) and send `/start` to get your numeric personal User ID.

---

### 2. Configure Environment

1. Copy `.env.example` to `.env` if not already present:
   ```bash
   cp .env.example .env
   ```

2. Secure file permissions so only your user can read the bot token:
   ```bash
   chmod 600 .env
   ```

3. Configure variables in `.env`:
   ```bash
   # Target IP address to monitor (e.g. office gateway or public IP)
   IP="203.0.113.1"

   # Telegram Bot Token (from @BotFather)
   TOKEN="your_telegram_bot_token"

   # Telegram Group / Channel / User ID (from @getidsbot)
   CHAT_ID="-100xxxxxxxxxx"

   # Status lock file path
   STATUS_FILE="/tmp/office_status.txt"
   ```

4. Ensure `bot.sh` is executable:
   ```bash
   chmod +x bot.sh
   ```

---

## 📖 Usage

### 1. Manual Test Mode (`--test` or `-t`)
Test ping reachability and send a test message to the Telegram group to verify that credentials and permissions work:
```bash
./bot.sh --test
```

**Output example:**
```text
Running manual test against 203.0.113.1...
Ping succeeded. Sending confirmation message to Telegram...
Test message delivered successfully to Telegram!
```

### 2. Regular Monitoring Mode
Run the script directly:
```bash
./bot.sh
```
- If the target IP is **ONLINE** and was previously online: Script runs silently and exits with code 0.
- If the target IP is **DOWN** and state file does not exist: Sends `🚨 ALARM` message and creates status file.
- If the target IP is **RECOVERED** and state file exists: Sends `✅ RECOVERED` message and removes status file.

---

## ⏰ Automated Scheduling

### Option 1: Using `cron` (Every minute)

Open crontab:
```bash
crontab -e
```

Add the following line (replace `/path/to/mss-ping-tgbot` with the absolute path to your script):
```cron
* * * * * /path/to/mss-ping-tgbot/bot.sh >/dev/null 2>&1
```

---

### Option 2: Using a `systemd` User Timer (Alternative to cron)

If `cron` is not installed on your system, you can use `systemd` user timers:

1. Create directory for user services:
   ```bash
   mkdir -p ~/.config/systemd/user
   ```

2. Create service file `~/.config/systemd/user/office-ping.service`:
   ```ini
   [Unit]
   Description=Office Internet Ping Telegram Monitor

   [Service]
   Type=oneshot
   ExecStart=/path/to/mss-ping-tgbot/bot.sh
   ```

3. Create timer file `~/.config/systemd/user/office-ping.timer`:
   ```ini
   [Unit]
   Description=Run Office Internet Ping Monitor every minute

   [Timer]
   OnBootSec=1min
   OnUnitActiveSec=1min
   AccuracySec=5s

   [Install]
   WantedBy=timers.target
   ```

4. Enable and start the timer:
   ```bash
   systemctl --user daemon-reload
   systemctl --user enable --now office-ping.timer
   ```

5. Check timer status:
   ```bash
   systemctl --user list-timers office-ping.timer
   ```

---

## 🛡️ Security Notes

- Keep `.env` out of version control (already specified in `.gitignore`).
- Never share your Telegram Bot Token or private Chat ID publicly.
- If a token is compromised, revoke it immediately via [@BotFather](https://t.me/BotFather) with the `/revoke` command.
