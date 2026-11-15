# 🐧 Linux Security Checker

A read-only Bash tool that checks a Linux system for common security weaknesses. It reports **PASS**, **WARN**, or **FAIL** for each check, prints a short **fix tip** for every problem it finds, and ends with an exit code that scripts and scheduled jobs can read.

This is the Phase 2 upgrade of the Bash security checker I built in Phase 1 for the IqraSec Academy Scripting & Automation internship.

## 📌 Project Overview

Checking a Linux machine by hand means running many commands and knowing how to read each result. My Phase 1 version printed a few raw status lines, asked for a sudo password in the middle of the run, and gave a false warning when run as root. This version gives a clear verdict for each check, runs without password prompts, and tells the user what to do next.

## ✨ Key Features

### 1. Firewall Status
- Checks whether UFW is installed and active.
- Checks firewalld when UFW is not present.
- Reports FAIL when the firewall is inactive or when no supported firewall tool is found.
- Reads the service state, so no sudo password prompt appears during the run.

### 2. SSH Service Status
- Checks whether the SSH service is running (supports both the `ssh` and `sshd` service names).
- Reports INFO when SSH is running and PASS when it is not.
- Skips the check with a clear INFO message when systemd is not available.

### 3. Password File Protection
- Reads the permissions and owner of `/etc/shadow`.
- Reports FAIL if other users can access the file or if it is not owned by root.
- Avoids the false warning that appears when the script is run as root.

### 4. SSH Configuration
- Reads `PermitRootLogin` and `PasswordAuthentication` from `/etc/ssh/sshd_config`.
- Ignores commented lines and accepts any letter case.
- Reports FAIL when direct root login is allowed.
- Reports WARN when password login is on or when a setting is missing.

### 5. Root-Level Accounts
- Checks `/etc/passwd` for accounts other than `root` that have UID 0.
- Names each extra account in the result.

### 6. Empty Password Accounts
- Checks `/etc/shadow` for accounts that have no password.
- Prints account names only, never password hashes.
- Needs `sudo`. Without it, the check is skipped with an INFO message.

### 7. Open Network Ports
- Lists ports that are listening and open to the network.
- Ignores ports reachable only from the same computer (localhost).
- Reports FAIL for risky ports: 21 (FTP), 23 (Telnet), 69 (TFTP), 111 (rpcbind), 445 (SMB), 3389 (Remote Desktop), and 5900 (VNC).

### 8. System Updates Check
- Counts available package updates through APT.
- Reports WARN with the number of packages waiting.
- Uses the saved package list, so it needs no root access and no internet connection.
- Works on APT-based systems (tested on Kali Linux).

### 9. Clear Results and Summary
- Every check ends in PASS, WARN, FAIL, or INFO.
- A summary line at the end counts the passes, warnings, and failures.

### 10. Fix Tips
- Each WARN and FAIL shows the command or setting that fixes it.
- The tool only shows the tip. It never runs it.

### 11. Exit Codes
- 0 = all checks passed, 1 = warnings, 2 = failures, 3 = wrong usage or the report could not be saved.
- Scripts and scheduled jobs can read the result without reading the text.

### 12. Timestamped Reports
- `--save` writes the results to a file named with the date and time.
- `--dir` saves the report in a folder of your choice.
- The report folder and files are created with private permissions.

### 13. Safe and Read-Only
- Never changes files, services, firewall rules, or accounts.
- Says so when a check cannot run, instead of guessing.
- Includes a `--help` option.

| # | Check | What it looks at | Problem result |
|---|---|---|---|
| 1 | Firewall | Whether UFW or firewalld is active | FAIL |
| 2 | SSH service | Whether the SSH service (`ssh` or `sshd`) is running | INFO if running |
| 3 | `/etc/shadow` | File permissions and owner of the password-hash file | FAIL |
| 4 | SSH settings | `PermitRootLogin` and `PasswordAuthentication` in `/etc/ssh/sshd_config` | FAIL or WARN |
| 5 | UID 0 accounts | Accounts other than `root` that have root powers | FAIL |
| 6 | Empty passwords | Accounts with no password (needs root) | FAIL |
| 7 | Open ports | Listening ports open to the network, flagging risky ones (21, 23, 69, 111, 445, 3389, 5900) | FAIL |
| 8 | Package updates | Number of upgradable packages (apt-based systems) | WARN |

## 🌍 Real-World Applications

### 1. Quick Security Baseline
Gives a fast first look at a new Linux machine or virtual machine, covering the firewall, SSH settings, important accounts, open ports, and pending updates in one run instead of many separate commands.

### 2. System Administration
Helps administrators spot common weak settings, such as root login over SSH, password login, risky open ports, and a firewall that is turned off. The exit codes (0, 1, 2) let scripts and scheduled jobs read the result without reading the text.

### 3. IT Support
Assists technicians with a first security check when investigating a Linux machine. A saved report with `--save` records what was found and when. Reports list account names and ports, so share them with care.

### 4. Tracking Changes Over Time
Because each saved report is named with the date and time, an administrator can keep reports from different days and compare them, for example before and after fixing a warning.

### 5. Cybersecurity Learning
Helps students understand basic Linux hardening, including:
- Firewall status
- SSH service and SSH configuration settings
- Password file protection (`/etc/shadow`)
- Accounts with root powers (UID 0) and accounts with no password

## ⚙️ How Linux Security Checker Works

Linux Security Checker uses standard Linux utilities to read security-related settings and compare them with safe values. It only reads settings and never changes anything.

1. **Launch:** Run the Bash script, optionally with `sudo` and with `--save` to keep a report.
2. **Read options:** The script reads any options you typed (`--help`, `--save`, `--dir`) and stops with a clear message if one is wrong.
3. **Collect:** Each of the 8 checks reads one setting using standard tools: `systemctl` for services, `stat` for file permissions, `grep` and `awk` for configuration files, `ss` for open ports, and `apt` for updates.
4. **Analyze:** Each result is compared with a safe value. For example, `/etc/shadow` must not be accessible to other users and must belong to root, `PermitRootLogin` must not be `yes`, and ports such as 21 (FTP) and 23 (Telnet) must not be open to the network.
5. **Display:** Results appear as PASS, WARN, FAIL, or INFO. Every WARN and FAIL includes a fix tip.
6. **Summarize:** A summary line counts the passes, warnings, and failures.
7. **Report (optional):** With `--save`, the same output is written to a timestamped text file in a private folder.
8. **Exit:** The script exits with code 0 (all good), 1 (warnings), or 2 (failures), so other scripts can read the result.

## Requirements

- A Linux system with Bash
- Standard tools: `grep`, `awk`, `stat`, `id`, `tr`, `sort`
- `systemctl` (systemd) for the firewall and SSH service checks
- `ss` (from the `iproute2` package) for the open ports check
- `apt` for the package updates check (Debian, Ubuntu, Kali)
- Root access (`sudo`) only for the empty-password check

Tested on Kali Linux.

## 🖥️ Usage

Download the repository and run the script:

```bash
git clone https://github.com/Kantyreelz/phase1--cybersecuritytools.git
cd phase1--cybersecuritytools/Phase-2/linux-security-checker
bash linuxsecuritychecker.sh
```

Run it with `sudo` to include the empty-password check:

```bash
sudo bash linuxsecuritychecker.sh
```

Save the report to a file:

```bash
bash linuxsecuritychecker.sh | tee report.txt
```

Show the help message:

```bash
bash linuxsecuritychecker.sh --help
```

### Exit codes

| Code | Meaning |
|---|---|
| 0 | All checks passed |
| 1 | At least one warning, no failures |
| 2 | At least one failure |
| 3 | Wrong usage (unknown option) |

Check the code right after a run with `echo $?`.

## 📁 Saved Reports

When you run the checker with `--save`, it creates a `reports` folder in the folder where you ran the command and writes the results to a timestamped text file.

Example:

```text
linux-security-checker/
│
├── linuxsecuritychecker.sh
│
├── reports/
│   ├── report-20261115-064454.txt
│   └── report-20261116-101500.txt
│
└── screenshots/
```

File names follow the pattern `report-YYYYMMDD-HHMMSS.txt` (year, month, day, hour, minute, second), so each run creates a new file and older reports are never overwritten.

Each report contains:
- The report title and the date and time it was created.
- The result of every check (PASS, WARN, FAIL, or INFO), with a fix tip under each WARN and FAIL.
- The summary line with the number of passes, warnings, and failures.

Use `--dir` to save reports in a different folder:

```bash
bash linuxsecuritychecker.sh --save --dir ~/audit-reports
```

The `reports` folder is created with private permissions (700) and each report file with private permissions (600). Reports are stored locally and are never uploaded anywhere. Because they list account names and open ports, do not upload them to GitHub or share them without checking them first.
##  Example output

```
================================
  LINUX SECURITY CHECKER
================================
[PASS] UFW firewall is active.
[PASS] SSH service is not running.
[PASS] /etc/shadow is protected (permissions 640, owner root).
[WARN] PermitRootLogin is not set. The default is usually safe, but set it to 'no' to be sure.
       Fix: In /etc/ssh/sshd_config set: PermitRootLogin no   then: sudo systemctl restart ssh
[WARN] PasswordAuthentication is not set, so the default (yes) applies.
       Fix: Set up SSH keys first (ssh-keygen, ssh-copy-id). Then set PasswordAuthentication no and restart ssh.
[PASS] Only root has UID 0.
[INFO] Not running as root, so empty passwords were not checked (use sudo).
[PASS] No risky ports are open to the network.
[INFO] No ports are open to the network.
[PASS] No package updates are waiting (based on the saved package list).
--------------------------------
Summary: 6 passed, 2 warnings, 0 failures
```

![Checker running on Kali Linux](screenshots/checker-output.png)

## 💻 Technologies Used

| Technology | Purpose |
|---|---|
| Bash | Main scripting language |
| systemctl | Firewall and SSH service status checks |
| ufw / firewall-cmd | Firewall detection (UFW and firewalld) |
| stat | File permission and owner checks (`/etc/shadow`) |
| grep / awk | Reading SSH settings and checking `/etc/passwd` and `/etc/shadow` |
| tr / sort | Output processing (removing duplicate ports, formatting lists) |
| id | Detecting whether the script runs as root |
| ss | Open network port information |
| APT | Package update information |
| date / mkdir / chmod | Timestamped report names and private report folders |

---

## 🛡️ Security & Reliability

Linux Security Checker is designed as a read-only checking utility.

- Does not modify system configuration.
- Does not install, update, or remove packages.
- Does not change firewall settings.
- Does not stop, start, or restart services.
- Does not change user accounts or passwords.
- Does not delete files.
- Does not need an internet connection (the update check reads the saved package list).
- Does not print password hashes, only account names.
- Does not require root privileges, except for the empty-password check, which is skipped with an INFO message when run without `sudo`.
- Creates files only when you use `--save`, and then only a private `reports` folder and report files.
- Shows fix tips but never runs them.
- Handles unavailable tools (no systemd, `ss`, `apt`, or config file) with an INFO message instead of guessing.
- Reports stay on your computer and are never uploaded anywhere.

## ⛔ Limitations

- The SSH settings check reads only `/etc/ssh/sshd_config`. Settings kept in `/etc/ssh/sshd_config.d/` are not read.
- The firewall check looks at whether the firewall service is active. It does not review the firewall rules.
- The updates check uses the package list saved on the machine, so it is only as fresh as the last `sudo apt update`. It supports apt-based systems only.
- The empty-password check needs root.
- This is a quick baseline check. It does not replace full auditing tools such as Lynis or OpenSCAP.
- The fix tips are suggestions. Read each command before you run it.

## Privacy note

The output can include account names and open port numbers. Check a saved report before sharing it publicly, and hide usernames and IP addresses in screenshots.

## 🔬 Testing

I ran the tool on Kali Linux, both normally and with `sudo`, and compared each result with the actual system settings.
<img width="813" height="518" alt="image" src="https://github.com/user-attachments/assets/6b6a7c2e-b345-437a-91d8-8aef02abcc5e" />

## 📜 License

This project is licensed under the MIT License. See the [LICENSE](../../LICENSE) file in the repository root.

## Author

Okesanya Favour Oyedele, IqraSec Academy Scripting & Automation internship, Phase 2.
