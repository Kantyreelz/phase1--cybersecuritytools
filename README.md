# Phase 1: Cybersecurity Tools

A collection of small cybersecurity and automation tools built for Phase 1.

## Tools

- **Python SSH Log Analyzer** — analyzes Linux authentication logs and counts failed SSH attempts by source IP. See [Python-Tool](Python-Tool/README.md).
- **Bash System Information Tool** — displays system details such as uptime, memory, disk space, and network interfaces. See [Bash-Tool](Bash-Tool/README.md).
- **Linux Security Checker** — reports UFW firewall status, SSH service status, and whether the current user can read `/etc/shadow`. See [Bash-Tool](Bash-Tool/README.md).

## Repository Structure

- `Python-Tool/` — Python log analyzer, sample log, documentation, and screenshots.
- `Bash-Tool/` — Bash system information tool, Linux security checker, documentation, and screenshots.

The Linux Security Checker only reports status; it doesn’t change firewall settings or read the contents of /etc/shadow.


See the README inside each tool’s folder for its requirements and run instructions.

