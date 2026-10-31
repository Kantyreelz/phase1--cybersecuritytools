#!/usr/bin/env python3
import sys
# Check whether one log line shows a  failed ssh password attempt
def is_ssh_failure(line):
    return "Failed password" in line
# Get the word after "from", which is the source IP in an SSH log line.
def extract_source_ip(line):
    words = line.split()

    if "from" in words:
        from_position = words.index("from")
        return words[from_position + 1]

    return None
# Read the log and count failed SSH attempts for each source IP.
def analyze_log(file_path):
    attempts = {}
    total_lines = 0

    with open(file_path, "r") as log_file:
        for line in log_file:
            total_lines = total_lines + 1

            if is_ssh_failure(line):
                source_ip = extract_source_ip(line)

                if source_ip is None:
                   continue
                elif source_ip in attempts:
                        attempts[source_ip] = attempts[source_ip] + 1
                else:
                        attempts[source_ip] = 1
    return total_lines, attempts
# Get the log filename from the command line.
def main():
    if len(sys.argv) == 2 and sys.argv[1] == "--help":
        print("Usage: python3 tool.py <log_file>")
        print("Analyze failed SSH login attempts in a log file.")
        return

    if len(sys.argv) != 2:
        print("Usage: python3 tool.py <log_file>")
        return

    log_file = sys.argv[1]
    try:
        total_lines, attempts = analyze_log(log_file)
    except FileNotFoundError:
        print("Error: the log file was not found.")
        return
    except PermissionError:
        print("Error: you do not have permission to read that file.")
        return
    # Show a summary of the failed SSH attempts.
    print(f"Log file: {log_file}")
    print(f"Lines scanned: {total_lines}")

    failed_attempts = 0
    for count in attempts.values():
        failed_attempts = failed_attempts + count

    print(f"Failed SSH attempts: {failed_attempts}")
    print(f"Unique source IPs: {len(attempts)}")

    if attempts:
        print("Attempts by source IP:")
        for source_ip in attempts:
            print(f"  {source_ip}: {attempts[source_ip]}")
    else:
        print("No failed SSH login attempts found.")
if __name__ == "__main__":
     main()
