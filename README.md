# CYBERSECURITY TOOLS : PHASE 1 AND PHASE 2
# Phase 1: Cybersecurity Tools.

A collection of small cybersecurity and automation tools built for Phase 1.

## Tools

- **Python SSH Log Analyzer** — analyzes Linux authentication logs and counts failed SSH attempts by source IP. See [Python-Tool](Python-Tool/README.md).
- **Bash System Information Tool** — displays system details such as uptime, memory, disk space, and network interfaces. See [Bash-Tool](Bash-Tool/README.md).
- **Linux Security Checker** — reports UFW firewall status, SSH service status, and whether the current user can read `/etc/shadow`. See [Bash-Tool](Bash-Tool/README.md).

## Repository Structure

- `Python-Tool/` — Python log analyzer, sample log, documentation, and screenshots.
- `Bash-Tool/` — Bash system information tool, Linux security checker, documentation, and screenshots.

In Phase 1, the Linux Security Checker only reports status; it doesn't change firewall settings or read the contents of /etc/shadow.


See the README inside each tool’s folder for its requirements and run instructions.

## Phase 2: Linux Security Checker (upgraded)

An upgraded version of the Phase 1 Bash security checker. It runs 8 read-only checks (firewall, SSH service, `/etc/shadow` permissions, SSH settings, extra UID 0 accounts, empty passwords, risky open ports, and pending updates). Each check reports PASS, WARN, FAIL, or INFO, every warning or failure comes with a fix tip, and the exit code (0, 1, 2) lets scripts read the result. `--save` writes a timestamped report. See [Phase-2/linux-security-checker](Phase-2/linux-security-checker/README.md).

## Repository Structure

phase1--cybersecuritytools/
├── README.md
├── LICENSE
├── Phase_1_Report.pdf
├── Python-Tool/
│   └── Python log analyzer, sample log, documentation, screenshots
├── Bash-Tool/
│   └── System information tool, Linux security checker (Phase 1),
│       documentation, screenshots
└── Phase-2/
    └── linux-security-checker/
        ├── linuxsecuritychecker.sh
        ├── README.md
        └── screenshots/

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
