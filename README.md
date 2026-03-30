# Daily Ops Standup — Setup Guide

A daily standup generator powered by [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and MCP servers. Pulls from Granola (meetings), Slack, Linear (issues), and Google Calendar to auto-generate a formatted standup post.

## Files

| File | Purpose |
|------|---------|
| `daily-standup-agent.md` | Agent system prompt (what Claude does) |
| `daily-standup.sh` | Shell wrapper (how it runs) |
| `standup-notes.md` | Optional — drop manual notes here before running (call transcripts, anything not in MCP) |

## Prerequisites

1. **Claude Code CLI** installed (`npm install -g @anthropic-ai/claude-code`)
2. **ANTHROPIC_API_KEY** set in environment
3. MCP servers configured (see below)

## MCP Server Configuration

Connect the MCP servers you want the agent to pull from. The agent supports:

- **Granola** — meeting notes and transcripts
- **Slack** — channel messages and DMs
- **Linear** — issue tracking and project updates
- **Google Calendar** — today's schedule

Refer to each provider's MCP documentation for setup instructions.

## Running

### Manual (recommended to start)

```bash
chmod +x daily-standup.sh
./daily-standup.sh
```

Claude will gather data from all available MCP sources and print a formatted standup to your terminal. The output is also saved to `standup-{date}.md`.

### Slack Notification

Set the `SLACK_STANDUP_WEBHOOK` environment variable to a [Slack incoming webhook URL](https://api.slack.com/messaging/webhooks) to auto-post the standup after generation:

```bash
export SLACK_STANDUP_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

### Cron

```bash
crontab -e
```

```cron
# Example: Run at 4pm ET every day
SHELL=/bin/bash
PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/share/npm/bin
0 16 * * * /path/to/daily-standup.sh >> ~/logs/daily-standup.log 2>&1
```

> **Note:** On macOS, you may need to grant Full Disk Access to `/bin/bash` in System Settings > Privacy & Security for cron to work.

### Terminal Alias

Add to `~/.zshrc` or `~/.bashrc`:

```bash
alias standup="/path/to/daily-standup.sh"
```

## Adding Manual Notes

For things MCP can't reach (call recordings, Claude conversations, etc.):

```bash
echo "- Reviewed hardware PRD on call with vendor" >> standup-notes.md
echo "- Claude session: drafted job description for new role" >> standup-notes.md
```

The script reads and clears this file each run.

## Customization

Edit `daily-standup-agent.md` to customize:
- **Output format** — change the standup template
- **Priority ordering** — adjust what goes first
- **Data sources** — add/remove MCP sources, configure channel IDs and team IDs
- **Synthesis rules** — change how data is deduplicated and prioritized
