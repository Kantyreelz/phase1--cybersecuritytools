#!/bin/bash
#
# Linux Security Checker (v2)
# Read-only security checks. Each check ends in PASS, WARN, FAIL or INFO.
# Exit codes: 0 = all good, 1 = warnings, 2 = failures,
#             3 = wrong usage or the report could not be saved

# --- Counters and helpers -------------------------------------------------
# Each helper prints one result line and counts it. warn and fail take an
# optional second text ($2): a tip showing how to fix the problem.
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

pass() { echo "[PASS] $1"; PASS_COUNT=$((PASS_COUNT + 1)); }
info() { echo "[INFO] $1"; }
warn() { echo "[WARN] $1"; [ -n "${2:-}" ] && echo "       Fix: $2"; WARN_COUNT=$((WARN_COUNT + 1)); }
fail() { echo "[FAIL] $1"; [ -n "${2:-}" ] && echo "       Fix: $2"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

# --- Settings -------------------------------------------------------------
# The files we read. Each can be replaced by an environment variable, which
# the tests use to check the script against fake files, for example:
#   SSHD_CONFIG=/tmp/test_config bash linuxsecuritychecker.sh
SSHD_CONFIG="${SSHD_CONFIG:-/etc/ssh/sshd_config}"
PASSWD_FILE="${PASSWD_FILE:-/etc/passwd}"
SHADOW_FILE="${SHADOW_FILE:-/etc/shadow}"

show_help() {
    cat << 'HELP'
Linux Security Checker

Usage: bash linuxsecuritychecker.sh [options]

Options:
  -h, --help      Show this help message
  -s, --save      Save a timestamped report in the 'reports' folder
  -d, --dir DIR   Save the report in DIR instead (use together with --save)

Checks the firewall, the SSH service, the SSH settings, the /etc/shadow file,
user accounts (extra UID 0 users, empty passwords) and open network ports.
Run with sudo to include the empty-password check.
Example:  bash linuxsecuritychecker.sh --save

Exit codes: 0 = all good, 1 = warnings, 2 = failures,
            3 = wrong usage or the report could not be saved
HELP
}

# --- Options --------------------------------------------------------------
SAVE=0
REPORT_DIR="reports"

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help) show_help; exit 0 ;;
        -s|--save) SAVE=1 ;;
        -d|--dir)
            [ -n "${2:-}" ] || { echo "Error: --dir needs a folder name."; exit 3; }
            REPORT_DIR="$2"; shift ;;
        *) echo "Error: unknown option: $1"; echo "Use --help for instructions."; exit 3 ;;
    esac
    shift
done

# --- Checks ---------------------------------------------------------------

# 1. Firewall: a firewall blocks unwanted connections. We ask systemd if the
#    service is running, so no sudo password is needed.
check_firewall() {
    if command -v ufw > /dev/null 2>&1; then
        if systemctl is-active --quiet ufw 2> /dev/null; then
            pass "UFW firewall is active."
        else
            fail "UFW is installed but not active." "sudo ufw allow ssh (only if you use SSH), then: sudo ufw enable"
        fi
    elif command -v firewall-cmd > /dev/null 2>&1; then
        if firewall-cmd --state > /dev/null 2>&1; then
            pass "firewalld is running."
        else
            fail "firewalld is installed but not running." "sudo systemctl enable --now firewalld"
        fi
    else
        fail "No firewall found (looked for ufw and firewalld)." "Install one: sudo apt install ufw, then: sudo ufw enable"
    fi
}

# 2. SSH service: remote login is safest off unless you need it.
#    The service is "ssh" on Debian/Kali/Ubuntu and "sshd" on Red Hat systems.
check_ssh_service() {
    if [ ! -d /run/systemd/system ]; then
        info "systemd is not running, so the SSH service was not checked."
    elif systemctl is-active --quiet ssh || systemctl is-active --quiet sshd; then
        info "SSH service is running. Make sure you really need it."
    else
        pass "SSH service is not running."
    fi
}

# 3. /etc/shadow holds password hashes. The last digit of its permission
#    number is for "everyone else": it must be 0. The owner must be root.
check_shadow() {
    if [ ! -e "$SHADOW_FILE" ]; then
        info "/etc/shadow was not found, so it was not checked."
        return
    fi
    mode=$(stat -c '%a' "$SHADOW_FILE")
    owner=$(stat -c '%U' "$SHADOW_FILE")
    shadow_fix="sudo chown root:shadow /etc/shadow && sudo chmod 640 /etc/shadow"

    case "$mode" in
        *0) if [ "$owner" = "root" ]; then
                pass "/etc/shadow is protected (permissions $mode, owner $owner)."
            else
                fail "/etc/shadow is owned by $owner, but it should be root." "$shadow_fix"
            fi ;;
        *) fail "/etc/shadow can be accessed by other users (permissions $mode)." "$shadow_fix" ;;
    esac
}

# 4. SSH settings: root login and password login are the risky ones.
#    We read the first matching, non-comment line of sshd_config.
#    Limitation: files in /etc/ssh/sshd_config.d/ are not read.
ssh_value() { grep -i -m1 "^[[:space:]]*$1" "$SSHD_CONFIG" | awk '{print tolower($2)}'; }

check_ssh_config() {
    if [ ! -f "$SSHD_CONFIG" ]; then
        info "$SSHD_CONFIG not found, so SSH settings were not checked."
        return
    elif [ ! -r "$SSHD_CONFIG" ]; then
        info "$SSHD_CONFIG cannot be read by this user, so it was not checked."
        return
    fi
    root_fix="In /etc/ssh/sshd_config set: PermitRootLogin no   then: sudo systemctl restart ssh"
    pw_fix="Set up SSH keys first (ssh-keygen, ssh-copy-id). Then set PasswordAuthentication no and restart ssh."

    root_login=$(ssh_value PermitRootLogin)
    case "$root_login" in
        yes) fail "SSH allows direct root login (PermitRootLogin yes)." "$root_fix" ;;
        no|prohibit-password|without-password|forced-commands-only)
            pass "SSH root login is restricted (PermitRootLogin $root_login)." ;;
        "") warn "PermitRootLogin is not set. The default is usually safe, but set it to 'no' to be sure." "$root_fix" ;;
        *) warn "PermitRootLogin has an unusual value: $root_login" "$root_fix" ;;
    esac

    password_auth=$(ssh_value PasswordAuthentication)   # missing line = default "yes"
    case "$password_auth" in
        no) pass "SSH password login is off (keys only)." ;;
        yes) warn "SSH password login is on. Keys are safer than passwords." "$pw_fix" ;;
        "") warn "PasswordAuthentication is not set, so the default (yes) applies." "$pw_fix" ;;
        *) warn "PasswordAuthentication has an unusual value: $password_auth" "$pw_fix" ;;
    esac
}

# 5. Only the account named root should have UID 0 (root powers).
check_uid_zero() {
    extra=$(awk -F: '$3 == 0 && $1 != "root" {print $1}' "$PASSWD_FILE" | tr '\n' ' ')
    if [ -n "$extra" ]; then
        fail "Extra account(s) with root powers (UID 0): $extra" "Check the account. Remove it (sudo userdel NAME) or give it a normal UID."
    else
        pass "Only root has UID 0."
    fi
}

# 6. An empty password field in /etc/shadow means the account has no password.
#    Only root can read that file. Only account NAMES are printed, never hashes.
check_empty_passwords() {
    if [ "$(id -u)" -ne 0 ]; then
        info "Not running as root, so empty passwords were not checked (use sudo)."
        return
    fi
    empty=$(awk -F: '$2 == "" {print $1}' "$SHADOW_FILE" | tr '\n' ' ')
    if [ -n "$empty" ]; then
        fail "Account(s) with an empty password: $empty" "Set a password (sudo passwd NAME) or lock the account (sudo passwd -l NAME)."
    else
        pass "No accounts have an empty password."
    fi
}

# 7. Open ports: "ss -tuln" lists listening ports. Addresses starting with
#    127. or [::1] are local only, so we skip them. Everything else is open
#    to the network. Port = text after the last colon, address = before it.
RISKY_PORTS=" 21 23 69 111 445 3389 5900 "   # FTP Telnet TFTP rpcbind SMB RDP VNC

check_ports() {
    if ! command -v ss > /dev/null 2>&1; then
        info "The ss command was not found, so open ports were not checked."
        return
    fi
    open_ports=""
    risky_ports=""
    for entry in $(ss -tuln 2> /dev/null | awk 'NR > 1 {print $5}'); do
        port=${entry##*:}
        case "${entry%:*}" in 127.*|"[::1]") continue ;; esac
        open_ports="$open_ports $port"
        case "$RISKY_PORTS" in *" $port "*) risky_ports="$risky_ports $port" ;; esac
    done
    # sort -un removes duplicates (IPv4 and IPv6 repeat ports); grep . drops empty lines
    open_ports=$(echo "$open_ports" | tr ' ' '\n' | sort -un | grep . | tr '\n' ' ')
    risky_ports=$(echo "$risky_ports" | tr ' ' '\n' | sort -un | grep . | tr '\n' ' ')

    if [ -n "$risky_ports" ]; then
        fail "Risky port(s) open to the network: $risky_ports" "Find it: sudo ss -tulnp | grep :PORT. Stop it (sudo systemctl disable --now NAME) or block it (sudo ufw deny PORT)."
    else
        pass "No risky ports are open to the network."
    fi
    if [ -n "$open_ports" ]; then
        info "Ports open to the network: $open_ports"
    else
        info "No ports are open to the network."
    fi
}

# 8. Updates: count packages apt says are upgradable. This reads the saved
#    package list (no root, no internet), so it is only as fresh as the last
#    "sudo apt update". Only apt-based systems are supported.
check_updates() {
    if ! command -v apt > /dev/null 2>&1; then
        info "apt was not found, so package updates were not checked."
        return
    fi
    update_count=$(apt list --upgradable 2> /dev/null | grep -c "upgradable")
    if [ "$update_count" -eq 0 ]; then
        pass "No package updates are waiting (based on the saved package list)."
    else
        warn "$update_count package(s) can be updated." "sudo apt update && sudo apt upgrade"
    fi
}

# --- Run everything -------------------------------------------------------
# To add a check: write a function above and add one line here.
run_all() {
    echo "================================"
    echo "  LINUX SECURITY CHECKER"
    echo "================================"
    echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"

    check_firewall
    check_ssh_service
    check_shadow
    check_ssh_config
    check_uid_zero
    check_empty_passwords
    check_ports
    check_updates

    echo "--------------------------------"
    echo "Summary: $PASS_COUNT passed, $WARN_COUNT warnings, $FAIL_COUNT failures"
}

# --- Show the report, or save it too --------------------------------------
# "run_all > file" (no pipe) keeps the counters, which the exit code needs.
# Reports list account names and ports, so folder and file are made private.
# Do not upload saved reports to GitHub.
if [ "$SAVE" -eq 1 ]; then
    if [ ! -d "$REPORT_DIR" ]; then
        mkdir -p "$REPORT_DIR" 2> /dev/null || { echo "Error: could not create the folder: $REPORT_DIR"; exit 3; }
        chmod 700 "$REPORT_DIR"
    fi
    [ -w "$REPORT_DIR" ] || { echo "Error: cannot write to the folder: $REPORT_DIR"; exit 3; }

    REPORT_FILE="$REPORT_DIR/report-$(date '+%Y%m%d-%H%M%S').txt"
    run_all > "$REPORT_FILE"
    chmod 600 "$REPORT_FILE"
    cat "$REPORT_FILE"
    echo ""
    echo "Report saved to: $REPORT_FILE"
else
    run_all
fi

# --- Exit code: failures first, then warnings -----------------------------
if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 2
elif [ "$WARN_COUNT" -gt 0 ]; then
    exit 1
fi
exit 0
