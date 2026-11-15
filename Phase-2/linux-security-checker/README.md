# Linux Security Checker

A read-only Bash tool that checks a Linux system for common security weaknesses. It reports **PASS**, **WARN**, or **FAIL** for each check, prints a short **fix tip** for every problem it finds, and ends with an exit code that scripts and scheduled jobs can read.

This is the Phase 2 upgrade of the Bash security checker I built in Phase 1 for the IqraSec Academy Scripting & Automation internship.

## Why I built it

Checking a Linux machine by hand means running many commands and knowing how to read each result. My Phase 1 version printed a few raw status lines, asked for a sudo password in the middle of the run, and gave a false warning when run as root. This version gives a clear verdict for each check, runs without password prompts, and tells the user what to do next.

## What it checks

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

## Features

- **Clear results:** every check ends in PASS, WARN, FAIL, or INFO, followed by a summary count.
- **Fix tips:** each WARN and FAIL shows the command or setting that fixes it. The tool only shows the tip. It never runs it.
- **Exit codes for automation:** the result can be read by other scripts or scheduled jobs.
- **No sudo prompt in the middle of a run:** the firewall check reads the service state instead of calling `sudo ufw status`.
- **Honest about what it skipped:** if a check cannot run (no systemd, no `ss`, not root), it says so with an INFO line instead of guessing.
- **Read-only:** it never changes files, services, firewall rules, or accounts, and it never prints password hashes.

## Requirements

- A Linux system with Bash
- Standard tools: `grep`, `awk`, `stat`, `id`, `tr`, `sort`
- `systemctl` (systemd) for the firewall and SSH service checks
- `ss` (from the `iproute2` package) for the open ports check
- `apt` for the package updates check (Debian, Ubuntu, Kali)
- Root access (`sudo`) only for the empty-password check

Tested on Kali Linux.

## Usage

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

## Example output

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

## How it works

- **Counters and helpers:** `pass`, `warn`, `fail`, and `info` are small functions that print a tagged line and update a counter. `warn` and `fail` accept an optional second text, which is the fix tip.
- **One function per check:** each check is its own function. The "run everything" section at the bottom calls them in order, so adding a check means writing one function and adding one line.
- **Exit code:** at the end the script exits with 2 if there were failures, 1 if there were only warnings, and 0 otherwise.
- **Source comments:** every check has a comment explaining why it matters and how the commands work.

## Limitations

- The SSH settings check reads only `/etc/ssh/sshd_config`. Settings kept in `/etc/ssh/sshd_config.d/` are not read.
- The firewall check looks at whether the firewall service is active. It does not review the firewall rules.
- The updates check uses the package list saved on the machine, so it is only as fresh as the last `sudo apt update`. It supports apt-based systems only.
- The empty-password check needs root.
- This is a quick baseline check. It does not replace full auditing tools such as Lynis or OpenSCAP.
- The fix tips are suggestions. Read each command before you run it.

## Privacy note

The output can include account names and open port numbers. Check a saved report before sharing it publicly, and hide usernames and IP addresses in screenshots.

## Testing

I ran the tool on Kali Linux, both normally and with `sudo`, and compared each result with the actual system settings.

<!-- Add the automated test results here after the tests folder is added. -->

## Future improvements

- Support `dnf` and `yum` systems for the updates check
- Read the `/etc/ssh/sshd_config.d/` folder
- Add an option to save a timestamped report
- Add JSON output
- Add automated tests and ShellCheck in GitHub Actions

## License

This project is licensed under the MIT License. See the [LICENSE](../../LICENSE) file in the repository root.

## Author

Okesanya Favour Oyedele, IqraSec Academy Scripting & Automation internship, Phase 2.
