#!/bin/bash
#
# Linux Security Checker (v2)
# Checks a few basic security settings on a Linux computer.
# It only READS settings. It never changes anything.
#
# Exit codes:  0 = all good   1 = warnings   2 = failures   3 = wrong usage

# =============================================================
# PART 1: Counters
# =============================================================
# NOTE: These variables count how many checks ended in each result.
# We use them at the end to print a summary and choose the exit code.
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

# =============================================================
# PART 2: Small helper functions
# =============================================================
# NOTE: A function is a named block of code we can reuse.
# Instead of writing echo + counting in every check, each check
# just calls pass, warn, fail or info.
# "$1" means "the first thing written after the function name".
# Example:  pass "Firewall is active."

pass() {
    echo "[PASS] $1"
    PASS_COUNT=$((PASS_COUNT + 1))   # add 1 to the counter
}

warn() {
    echo "[WARN] $1"
    WARN_COUNT=$((WARN_COUNT + 1))
}

fail() {
    echo "[FAIL] $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

# info is only a note. It is not counted as good or bad.
info() {
    echo "[INFO] $1"
}

# =============================================================
# PART 3: Help message
# =============================================================
show_help() {
    echo "Linux Security Checker"
    echo ""
    echo "Usage: bash linuxsecuritychecker.sh [--help]"
    echo ""
    echo "Checks the firewall, the SSH service and the /etc/shadow file."
    echo "To save the report to a file, run:"
    echo "  bash linuxsecuritychecker.sh | tee report.txt"
    echo ""
    echo "Exit codes: 0 = all good, 1 = warnings, 2 = failures, 3 = wrong usage"
}

# =============================================================
# PART 4: Read the options typed by the user
# =============================================================
# NOTE: "$#" is how many words the user typed after the script name.
# The loop looks at each word. "case" works like a list of
# "if this word is X, do Y". "shift" moves on to the next word.

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Error: unknown option: $1"
            echo "Use --help for instructions."
            exit 3
            ;;
    esac
    shift
done

# =============================================================
# PART 5: The checks
# =============================================================

# ---------- Check 1: Firewall ----------
# WHY: A firewall blocks unwanted network connections.
# NOTE: Phase 1 used "sudo ufw status", which asked for a password
# and made the script stop. Instead we ask systemd whether the
# firewall service is running. That needs no password.
# "command -v ufw" checks that the program is installed.
# "> /dev/null 2>&1" hides the output so only the result matters.

check_firewall() {
    if command -v ufw > /dev/null 2>&1; then
        if systemctl is-active --quiet ufw 2> /dev/null; then
            pass "UFW firewall is active."
        else
            fail "UFW is installed but not active."
        fi
    elif command -v firewall-cmd > /dev/null 2>&1; then
        if firewall-cmd --state > /dev/null 2>&1; then
            pass "firewalld is running."
        else
            fail "firewalld is installed but not running."
        fi
    else
        fail "No firewall found (looked for ufw and firewalld)."
    fi
}

# ---------- Check 2: SSH service ----------
# WHY: SSH lets people log in remotely. If you do not need it,
# it is safer turned off. If you do need it, it must be configured
# well (we check that in a later step).
# NOTE: The service is called "ssh" on Debian/Kali/Ubuntu but
# "sshd" on Red Hat/CentOS/Fedora, so we try both.
# "||" means "or": the check passes if either name is running.

check_ssh_service() {
    # NOTE: /run/systemd/system exists only when systemd is really running.
    # Some places (containers, WSL) have no systemd, and then we cannot
    # tell whether SSH is running, so we say so instead of guessing.
    if [ ! -d /run/systemd/system ]; then
        info "systemd is not running, so the SSH service was not checked."
        return
    fi

    if systemctl is-active --quiet ssh || systemctl is-active --quiet sshd; then
        info "SSH service is running. Make sure you really need it."
    else
        pass "SSH service is not running."
    fi
}

# ---------- Check 3: /etc/shadow permissions ----------
# WHY: /etc/shadow stores password hashes. Only root should be
# able to read it. (Do not confuse it with /etc/passwd, which
# stores usernames and is readable by everyone on purpose.)
# NOTE: Phase 1 used [ -r /etc/shadow ], which gives a false
# warning when you run the script as root, because root can read
# everything. Here we look at the file's permission number instead.
# "stat -c '%a'" prints the permissions, for example 640.
# The LAST digit is for "everyone else". If it is 0, others have
# no access, so the pattern "*0" means "ends with 0".

check_shadow() {
    if [ ! -e /etc/shadow ]; then
        info "/etc/shadow was not found, so it was not checked."
        return
    fi

    mode=$(stat -c '%a' /etc/shadow)
    owner=$(stat -c '%U' /etc/shadow)

    case "$mode" in
        *0)
            if [ "$owner" = "root" ]; then
                pass "/etc/shadow is protected (permissions $mode, owner $owner)."
            else
                fail "/etc/shadow is owned by $owner, but it should be root."
            fi
            ;;
        *)
            fail "/etc/shadow can be accessed by other users (permissions $mode)."
            ;;
    esac
}

# =============================================================
# PART 6: Run everything
# =============================================================
# NOTE: This is the "table of contents" of the script. To add a
# new check later, write a function above and add one line here.

echo "================================"
echo "  LINUX SECURITY CHECKER"
echo "================================"

check_firewall
check_ssh_service
check_shadow

# =============================================================
# PART 7: Summary and exit code
# =============================================================
# NOTE: The exit code lets other programs (or a scheduled job)
# know the result without reading the text.
# Fails are more serious than warnings, so we test them first.

echo "--------------------------------"
echo "Summary: $PASS_COUNT passed, $WARN_COUNT warnings, $FAIL_COUNT failures"

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 2
elif [ "$WARN_COUNT" -gt 0 ]; then
    exit 1
else
    exit 0
fi
