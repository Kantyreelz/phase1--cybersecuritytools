# SSH Log Analyzer

## Objective

A simple Python command-line tool that reads a Linux authentication log, finds failed SSH password attempts, and counts them by source IP address.

## Features

- Reads a log file supplied on the command line.
- Finds SSH log lines containing `Failed password`.
- Counts failed attempts by source IP address.
- Reports the number of lines scanned and failed attempts found.
- Shows usage information with `--help`.
- Prints a clear message if the log file is missing or unreadable.

## Requirements

- Python 3.
- No additional Python packages.
- A Linux authentication log or the included `sample_auth.log`.

## How to Run

From this folder, show the usage information:

```bash
python3 tool.py --help
```

Analyze the included sample log:

```bash
python3 tool.py sample_auth.log
```

Analyze a system authentication log:

```bash
python3 tool.py /var/log/auth.log
```

You may need administrator permission to read a system log.

## Example Usage

```bash
python3 tool.py sample_auth.log
```

## Example Output

```text
Log file: sample_auth.log
Lines scanned: 5
Failed SSH attempts: 4
Unique source IPs: 2
Attempts by source IP:
  192.0.2.15: 3
  198.51.100.23: 1
```
## Challenges Faced

- Linux authentication logs can use different formats. This version focuses on SSH lines containing `Failed password`.
- Some matching lines may not contain a source IP after `from`, so the program skips those lines.

## Future Improvements

- Recognize more authentication log formats.
- Add support for IPv6 addresses.
- Add options to filter by date or save results to a report file.
