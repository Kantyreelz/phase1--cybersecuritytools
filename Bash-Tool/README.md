# System Information Tool

## Tool Name
System Information Tool (`securityinformationtool.sh`)

## Objective
A simple Bash script that displays basic information about the Linux computer where it is run.

## Features
- Displays the current user and computer name.
- Shows the date, time, and system uptime.
- Displays memory and disk space usage.
- Lists network interfaces and IP addresses.
- Provides instructions with the `--help` option.
- Displays an error message for an unknown option.

## Requirements
- A Linux system with Bash.
- Standard Linux commands: `date`, `uptime`, `free`, `df`, and `ip`.

## How to Run
Open a terminal in the `Bash-Tool` folder and run the script with Bash.

## Example Usage
Show system information:

```bash
bash securityinformationtool.sh```

## Show the help instructions
```bash
bash securityinformationtool.sh --help```

## Show a Wrong input
```bash
bash securityinformationtool.sh --hell```

## Example Output
The values vary depending on the computer running the script.

```text
SYSTEM INFORMATION
User: [redacted]
Hostname: [redacted]
Date: [date]
Time: [time]
Uptime: [uptime]
Memory: [memory information]
Disk space: [total, used, and available space]
IP addresses: [redacted]
```

## Challenges Faced
- Correcting the date and time command.
- Making the script respond properly to help and unknown options.

## Future Improvements
- Show more details about the Linux distribution.
- Let the user save the report to a file.
- Let the user choose which information to display.
