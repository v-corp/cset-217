# The Complete Bash Scripting Guide: From First Principles to Production Scripts
`date:` 2025-12-04 
`time:` 07:45:53 
`tags:` [[learning]][[devops]]
`description:`

---

## Foundation: What is Bash?

### The Shell Hierarchy

Bash sits in a specific layer between you (the user) and the kernel (the core of Linux).

```
┌─────────────────────────────────────────────┐
│ User (You typing commands)                  │
├─────────────────────────────────────────────┤
│ Shell: Bash, Zsh, Fish (interprets text)   │
├─────────────────────────────────────────────┤
│ Kernel: Linux (actually does the work)      │
├─────────────────────────────────────────────┤
│ Hardware: CPU, Memory, Disk                 │
└─────────────────────────────────────────────┘
```

**What Bash Does:**
- **Parses:** Reads text you type and understands it as commands.
- **Executes:** Calls the kernel to run programs.
- **Manages:** Handles files, processes, environment variables.

### Why Scripts Over Manual Commands?

**Scenario:** You need to back up 50 config files every day at 2 AM.

**Without a script (Manual):**
```bash
# Day 1: You sit at terminal and type 50 commands
cp /etc/app.conf /backup/app.conf.20251204
cp /etc/db.conf /backup/db.conf.20251204
# ... 48 more times, error-prone, you get tired
```

**With a script (Automation):**
```bash
# Day 1: Write the script once
#!/bin/bash
# Backup all .conf files
cp /etc/*.conf /backup/$(date +%Y%m%d)/

# Day 2-365: Cron runs it automatically at 2 AM
# No manual work needed
```

**The Payoff:**
- Runs reliably even when you sleep.
- Can't mistype commands.
- Easy to modify if requirements change.

---

## The Bash Execution Model

### Step 1: How Bash Reads Your Script

When you run `./script.sh`, here's what happens microsecond-by-microsecond:

```
1. User types: ./script.sh
2. OS checks: Is this file executable? (chmod +x)
3. OS reads line 1: #!/bin/bash
4. OS says: "Oh, use /bin/bash to interpret this"
5. /bin/bash opens the file and reads it line-by-line
6. Each line is parsed (broken into tokens)
7. Tokens are executed
```

### Step 2: The Shebang (#!) Explained

```bash
#!/bin/bash
```

This line does **nothing** when you run `bash script.sh` directly.

But when you run `./script.sh`, the OS kernel reads it:
- `#!` = "Special: use the program that follows"
- `/bin/bash` = Full path to the Bash interpreter

**Real-world comparison:**
```bash
#!/bin/bash          # "Use Bash interpreter"
#!/usr/bin/python3   # "Use Python3 interpreter"
#!/usr/bin/perl      # "Use Perl interpreter"
```

**Why a full path?** The kernel can't search $PATH. It needs the exact location.

### Step 3: Line-by-Line Execution

```bash
#!/bin/bash
echo "Line 1"        # Executed first
sleep 2              # Executed second (waits 2 seconds)
echo "Line 3"        # Executed third
```

**Unless** there's a loop or conditional. Then execution jumps around:

```bash
#!/bin/bash
echo "Start"
if true; then
    echo "Inside if"  # This is executed
else
    echo "Else"       # This is skipped
fi
echo "End"
```

### Step 4: Exit Codes (The Silent Language)

Every command returns an invisible number: 0-255.

```bash
#!/bin/bash
ls /tmp              # Success: returns 0
echo $?              # Print the last exit code: 0

ls /nonexistent      # Fail: returns 1 (or other error code)
echo $?              # Print it: 1
```

**The Contract:**
- Exit code **0** = Success (no errors)
- Exit code **1-255** = Failure (something broke)

**Why this matters:**
```bash
#!/bin/bash
if systemctl is-enabled firewalld; then
    # This block runs only if the command exits with 0
    echo "Firewalld is enabled"
else
    # This block runs if the command exits with non-zero
    echo "Firewalld is NOT enabled"
fi
```

The `if` statement doesn't care about printed text. It only cares about exit codes.

---

## Variables and Data Storage

### Variable Fundamentals

A variable is a named box that holds data.

```bash
NAME="Alice"           # String variable
AGE=30                 # Number variable (still stored as text in bash)
EMPTY=""               # Empty variable
UNSET_VAR              # This variable doesn't exist yet
```

**Critical Rule: No spaces around `=`**

```bash
# WRONG:
CITY = "Delhi"         # Bash thinks CITY is a command
MY_VAR = 42            # Error!

# RIGHT:
CITY="Delhi"           # Stores "Delhi" in CITY
MY_VAR=42              # Stores "42" in MY_VAR
```

### Getting Values: The `$` Prefix

To use a variable, prefix it with `$`:

```bash
#!/bin/bash
GREETING="Hello"
echo $GREETING         # Output: Hello
echo "Say $GREETING"   # Output: Say Hello
```

**Why the `$`?** Without it, Bash thinks you want a command:

```bash
GREETING="Hello"
echo GREETING          # Output: GREETING (just the word, not the value)
echo $GREETING         # Output: Hello (the actual value)
```

### Variable Scope: Where Variables Live

**Local Variables (inside a script):**
```bash
#!/bin/bash
SCRIPT_VAR="I only exist in this script"
echo $SCRIPT_VAR       # Works
```

Once the script ends, `$SCRIPT_VAR` disappears.

**Environment Variables (system-wide):**
```bash
#!/bin/bash
export SYSTEM_VAR="I exist in the whole system"
```

Now any program launched from this script can see `$SYSTEM_VAR`.

**Practical example:**
```bash
#!/bin/bash
export PATH="/usr/bin:/bin"  # Tell all child programs where to find commands
python my_script.py          # Python can see $PATH
```

### Naming Conventions

```bash
# UPPER_CASE: Constants (shouldn't change)
MAX_RETRIES=5
BACKUP_DIR="/home/backups"

# lower_case: Variables (will change)
current_date=$(date)
user_input=$1
```

---

## Command Substitution and Pipes

### Command Substitution: Capturing Output

**What:** Running a command and using its output as data.

**Syntax:** `$(command)` or `` `command` `` (backticks, older style)

```bash
#!/bin/bash
# Capture the current date
DATE=$(date +%Y-%m-%d)
echo "Today is $DATE"
# Output: Today is 2025-12-04

# Capture the number of files
FILE_COUNT=$(ls /tmp | wc -l)
echo "Files in /tmp: $FILE_COUNT"

# Nested command substitution
YEAR=$(date +%Y)
MONTH=$(date +%m)
FORMATTED="$YEAR-$MONTH"
echo $FORMATTED
```

**Why not just type the date?** Because you don't know the date when writing the script. The script discovers it at runtime.

### Real-world: The Backup Script Analysis

```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)     # Capture: 20251204_063145
BACKUP_DIR="/home/backups"
CONFIG_DIR="/home/configs"

# List all backup files that match the pattern, count them
VERSION=$(ls $BACKUP_DIR/backup_v*.tar.gz 2>/dev/null | wc -l)
# If no files exist:
#   ls returns error (suppressed by 2>/dev/null)
#   wc -l returns 0
# If 3 files exist (backup_v1.tar.gz, backup_v2.tar.gz, backup_v3.tar.gz):
#   ls outputs 3 lines
#   wc -l counts them: 3
# So VERSION = 3

# Increment the version
VERSION=$((VERSION + 1))        # Now VERSION = 4

mkdir -p $BACKUP_DIR             # Create directory if it doesn't exist
tar czf $BACKUP_DIR/backup_v${VERSION}.tar.gz -C $CONFIG_DIR .
# Creates: /home/backups/backup_v4.tar.gz

echo "$(date): backup_v${VERSION}.tar.gz created" >> /var/log/backup.log
# Appends to log: 2025-12-04 06:31:45: backup_v4.tar.gz created
```

### Pipes: Chaining Commands

A pipe `|` connects the output of one command to the input of another.

```bash
# Without pipes (two separate steps):
ls /tmp > temp_file.txt          # Save output to file
wc -l temp_file.txt              # Count lines in that file
rm temp_file.txt                 # Clean up

# With pipes (one step):
ls /tmp | wc -l                  # Count lines directly
```

**Why pipes?** More efficient, cleaner, no temporary files.

**Complex example:**
```bash
#!/bin/bash
# Find all .log files, count them by size
find /var/log -name "*.log" | xargs du -sh | sort -hr | head -5

# Breaking it down:
# find /var/log -name "*.log"    # Find all .log files
# xargs du -sh                   # Get size of each file
# sort -hr                       # Sort by size (human-readable, reverse)
# head -5                        # Show top 5
```

---

## File Descriptors and Redirection

### Understanding File Descriptors (FD)

Bash treats everything as files: input, output, errors.

Every program gets three default channels:

```
FD 0 (stdin):  Standard Input (keyboard)
FD 1 (stdout): Standard Output (screen)
FD 2 (stderr): Standard Error (error messages to screen)
```

**Analogy:** Imagine a desk with three trays:
- Tray 0: Papers coming *in* (requests)
- Tray 1: Papers going *out* (normal reports)
- Tray 2: Papers going *out* (error notices)

### Redirection Operators

**1. Redirect stdout (FD 1) with `>`**

```bash
#!/bin/bash
echo "Hello" > output.txt        # OVERWRITES output.txt with "Hello"
echo "World" > output.txt        # OVERWRITES again (Hello is gone)
# output.txt contains: World

ls /nonexistent > error.txt      # Error message goes to screen, not captured
```

**2. Append stdout with `>>`**

```bash
#!/bin/bash
echo "Line 1" >> log.txt
echo "Line 2" >> log.txt
echo "Line 3" >> log.txt
# log.txt contains:
# Line 1
# Line 2
# Line 3
```

**3. Redirect stderr (FD 2) with `2>`**

```bash
#!/bin/bash
ls /nonexistent 2> error.txt    # Error message goes to error.txt
ls /nonexistent 2> /dev/null    # Error message discarded
cat error.txt                   # Output: No such file or directory
```

**4. Redirect both stdout and stderr**

```bash
#!/bin/bash
# Method 1: Separate
ls /tmp > good.txt 2> bad.txt    # Good output to one file, errors to another

# Method 2: Combine both to same file
ls /tmp > output.txt 2>&1        # Both go to output.txt
# (2>&1 means "redirect FD 2 to wherever FD 1 is going")

# Method 3: Modern syntax
ls /tmp &> output.txt            # Both to output.txt (easier to remember)
```

### Input Redirection with `<`

```bash
#!/bin/bash
# Give a file as input to a command
wc -l < /var/log/syslog         # Count lines in syslog
# vs
wc -l /var/log/syslog           # Also works (slightly different)
```

### Here-documents: Multi-line Input

**What:** Passing multiple lines of text to a command.

```bash
#!/bin/bash
# Send multiple lines to a command
cat << 'EOF'
This is line 1
This is line 2
Variable $VAR is NOT expanded because of 'EOF'
EOF

# Output:
# This is line 1
# This is line 2
# Variable $VAR is NOT expanded because of 'EOF'
```

**In your backup script:**

```bash
#!/bin/bash
cat > backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/home/backups"
# ... rest of script
EOF

# This creates a NEW file called backup.sh with all the content between << 'EOF' and EOF
```

### The `/dev/null` Black Hole

```bash
#!/bin/bash
ls /nonexistent 2> /dev/null    # Error message disappears
# vs
ls /nonexistent 2> error.txt    # Error message saved
```

`/dev/null` is like a trash can. Anything sent there is destroyed.

---

## Control Flow: Logic in Scripts

### The `if` Statement: Making Decisions

**Basic Structure:**
```bash
if CONDITION; then
    # This runs if CONDITION is true
elif ANOTHER_CONDITION; then
    # This runs if first is false but this is true
else
    # This runs if all are false
fi
```

### How Conditions Work: Exit Codes

Remember: commands return exit codes (0 = success/true, non-zero = failure/false).

```bash
#!/bin/bash
if systemctl is-enabled firewalld; then
    # systemctl is-enabled returns 0 if enabled
    echo "Firewalld is already enabled"
else
    # systemctl is-enabled returns 1 if not enabled
    echo "Firewalld is NOT enabled"
fi
```

### Test Conditions: The `[` Command

`[` is actually a command (alias for `test`). It evaluates conditions:

```bash
#!/bin/bash
if [ -f /etc/hosts ]; then
    # -f means "file exists"
    echo "File exists"
fi

if [ -d /home ]; then
    # -d means "directory exists"
    echo "Directory exists"
fi

if [ -z "$VAR" ]; then
    # -z means "string is empty"
    echo "Variable is empty"
fi

if [ -n "$VAR" ]; then
    # -n means "string is NOT empty"
    echo "Variable has content"
fi

if [ "$VAR" = "expected" ]; then
    # String comparison
    echo "Variable matches"
fi

if [ 5 -gt 3 ]; then
    # -gt means "greater than"
    echo "5 is greater than 3"
fi

if [ 5 -lt 3 ]; then
    # -lt means "less than"
    echo "This won't print"
fi
```

**Common Test Operators:**

| Operator | Meaning | Example |
| --- | --- | --- |
| `-f` | File exists | `[ -f /etc/hosts ]` |
| `-d` | Directory exists | `[ -d /home ]` |
| `-e` | File or directory exists | `[ -e /tmp ]` |
| `-z` | String is empty | `[ -z "$VAR" ]` |
| `-n` | String is NOT empty | `[ -n "$VAR" ]` |
| `=` | Strings are equal | `[ "$A" = "$B" ]` |
| `!=` | Strings are different | `[ "$A" != "$B" ]` |
| `-gt` | Number is greater than | `[ 5 -gt 3 ]` |
| `-lt` | Number is less than | `[ 5 -lt 3 ]` |
| `-eq` | Numbers are equal | `[ 5 -eq 5 ]` |
| `-ne` | Numbers are NOT equal | `[ 5 -ne 3 ]` |

### The Firewall Script Analyzed

```bash
#!/bin/bash
LOG="/var/log/firewalld_setup.log"

# Check if firewalld is already enabled
if systemctl is-enabled --quiet firewalld; then
    # Exit code is 0, so this block runs
    echo "$(date): firewalld already enabled" >> $LOG
else
    # Exit code is non-zero, so this block runs if above is false
    systemctl enable --now firewalld
    echo "$(date): firewalld enabled and started" >> $LOG
fi

# Always run this regardless of the if/else
systemctl status firewalld --no-pager -l >> $LOG
```

**Why `--quiet`?** The `systemctl is-enabled` command normally prints "enabled" or "disabled". The `--quiet` flag suppresses that output. The `if` statement only cares about the exit code anyway.

### Boolean Logic: `&&` and `||`

**`&&` (AND): Run second command only if first succeeds**

```bash
#!/bin/bash
mkdir -p /backup && echo "Directory created"
# If mkdir succeeds (exit 0), then echo runs
# If mkdir fails (exit non-zero), echo doesn't run

cd /tmp && ls           # "List files only if cd to /tmp succeeded"
```

**`||` (OR): Run second command only if first fails**

```bash
#!/bin/bash
mkdir /backup || mkdir -p /backup
# "Try to create /backup. If that fails, create it with parents"

ping -c 1 8.8.8.8 || echo "Network down"
# "Ping Google. If it fails, print error message"
```

**Combining them:**

```bash
#!/bin/bash
mkdir -p /backup && echo "Success" || echo "Failed"
# If mkdir succeeds, print "Success"
# If mkdir fails, print "Failed"
```

### The `case` Statement: Multiple Choices

When you have many possible values:

```bash
#!/bin/bash
SERVICE=$1              # First argument passed to script

case $SERVICE in
    nginx)
        echo "Starting Nginx"
        systemctl start nginx
        ;;
    mysql)
        echo "Starting MySQL"
        systemctl start mysql
        ;;
    postgres)
        echo "Starting PostgreSQL"
        systemctl start postgresql
        ;;
    *)
        echo "Unknown service: $SERVICE"
        ;;
esac
```

**Usage:**
```bash
./script.sh nginx       # Output: Starting Nginx
./script.sh mysql       # Output: Starting MySQL
./script.sh apache      # Output: Unknown service: apache
```

### Loops: Repeating Code

**`for` Loop: Iterate over a list**

```bash
#!/bin/bash
# Basic for loop
for i in 1 2 3 4 5; do
    echo "Number: $i"
done
# Output:
# Number: 1
# Number: 2
# ... etc

# Loop over files
for file in /etc/*.conf; do
    echo "Processing $file"
    # Do something with each config file
done

# Loop with a range
for i in {1..10}; do
    echo "Iteration $i"
done
```

**`while` Loop: Repeat while condition is true**

```bash
#!/bin/bash
COUNTER=1
while [ $COUNTER -le 5 ]; do
    echo "Count: $COUNTER"
    COUNTER=$((COUNTER + 1))
done
# Output:
# Count: 1
# Count: 2
# Count: 3
# Count: 4
# Count: 5
```

**`until` Loop: Repeat until condition becomes true**

```bash
#!/bin/bash
COUNTER=1
until [ $COUNTER -gt 5 ]; do
    echo "Count: $COUNTER"
    COUNTER=$((COUNTER + 1))
done
# Same output as while loop above
```

---

## Arrays and Advanced Data

### Simple Arrays

Arrays store multiple values in one variable.

```bash
#!/bin/bash
# Create an array
FRUITS=("Apple" "Banana" "Orange")

# Access by index (0-based)
echo ${FRUITS[0]}       # Output: Apple
echo ${FRUITS[1]}       # Output: Banana
echo ${FRUITS[2]}       # Output: Orange

# Get all elements
echo ${FRUITS[@]}       # Output: Apple Banana Orange
echo ${FRUITS[*]}       # Output: Apple Banana Orange (slightly different)

# Get array length
echo ${#FRUITS[@]}      # Output: 3

# Loop through array
for fruit in "${FRUITS[@]}"; do
    echo "Fruit: $fruit"
done
```

### Associative Arrays (Hash Maps)

Key-value pairs, like a dictionary:

```bash
#!/bin/bash
declare -A USERS        # Declare as associative array

# Set values
USERS[alice]="admin"
USERS[bob]="user"
USERS[charlie]="guest"

# Access by key
echo ${USERS[alice]}    # Output: admin

# Loop through keys and values
for user in "${!USERS[@]}"; do
    echo "$user: ${USERS[$user]}"
done
# Output:
# alice: admin
# bob: user
# charlie: guest
```

### Arithmetic: The `$(( ))` Syntax

```bash
#!/bin/bash
A=5
B=3

# Basic arithmetic
SUM=$((A + B))          # 8
DIFF=$((A - B))         # 2
PROD=$((A * B))         # 15
QUOT=$((A / B))         # 1
MOD=$((A % B))          # 2

echo "Sum: $SUM, Diff: $DIFF, Prod: $PROD, Quot: $QUOT, Mod: $MOD"

# Increment
COUNTER=0
COUNTER=$((COUNTER + 1)) # Now 1

# In a loop
for i in {1..3}; do
    TOTAL=$((TOTAL + i))
done
echo "Total: $TOTAL"    # Output: Total: 6
```

---

## Functions: Reusable Code Blocks

### Basic Function Definition

```bash
#!/bin/bash
# Define a function
greet() {
    echo "Hello, World!"
}

# Call the function
greet                   # Output: Hello, World!
greet                   # Call it again
```

### Functions with Parameters

```bash
#!/bin/bash
greet() {
    NAME=$1             # First parameter
    AGE=$2              # Second parameter
    echo "Hello, $NAME! You are $AGE years old."
}

# Call with arguments
greet "Alice" 30        # Output: Hello, Alice! You are 30 years old.
greet "Bob" 25          # Output: Hello, Bob! You are 25 years old.
```

**Inside a function:**
- `$1`, `$2`, `$3`, ... are the parameters passed to the function
- `$@` or `$*` is all parameters
- `$#` is the number of parameters

```bash
#!/bin/bash
print_all() {
    echo "Number of args: $#"
    echo "All args: $@"
    for arg in "$@"; do
        echo "  - $arg"
    done
}

print_all "apple" "banana" "cherry"
# Output:
# Number of args: 3
# All args: apple banana cherry
#   - apple
#   - banana
#   - cherry
```

### Return Values: Exit Codes

Functions can return numbers (0 = success, 1-255 = failure):

```bash
#!/bin/bash
check_file() {
    if [ -f "$1" ]; then
        return 0        # Success
    else
        return 1        # Failure
    fi
}

if check_file "/etc/hosts"; then
    echo "File exists"
else
    echo "File does not exist"
fi

# Capture return code
check_file "/etc/hosts"
echo "Exit code was: $?"      # 0 or 1
```

### Returning Values via Output

Since functions can only return exit codes (0-255), return text via echo:

```bash
#!/bin/bash
get_greeting() {
    NAME=$1
    echo "Hello, $NAME!"
}

RESULT=$(get_greeting "Alice")
echo $RESULT            # Output: Hello, Alice!

# Practical example: get current user
get_current_user() {
    whoami              # This command's output is captured
}

CURRENT=$(get_current_user)
echo "Logged in as: $CURRENT"
```

### Local Variables in Functions

```bash
#!/bin/bash
GLOBAL_VAR="I'm global"

my_function() {
    local LOCAL_VAR="I only exist in this function"
    echo $GLOBAL_VAR    # Can access global: OK
    echo $LOCAL_VAR     # Can access local: OK
}

my_function
echo $GLOBAL_VAR        # Can access global: OK
echo $LOCAL_VAR         # Can't access local: EMPTY
```

---

## Text Processing: grep, sed, awk

### grep: Find Lines Matching a Pattern

```bash
#!/bin/bash
# Find lines containing "error" in a log file
grep "error" /var/log/syslog

# Case-insensitive search
grep -i "ERROR" /var/log/syslog

# Count matching lines
grep -c "error" /var/log/syslog

# Show line numbers
grep -n "error" /var/log/syslog

# Invert match (lines NOT containing "error")
grep -v "error" /var/log/syslog

# Use regular expressions
grep "^ERROR" /var/log/syslog   # Lines starting with ERROR

# Search in multiple files
grep "error" /var/log/*.log
```

### sed: Stream Editor (Find and Replace)

```bash
#!/bin/bash
# Replace first occurrence on each line
echo "apple apple apple" | sed 's/apple/orange/'
# Output: orange apple apple

# Replace all occurrences on each line
echo "apple apple apple" | sed 's/apple/orange/g'
# Output: orange orange orange

# Delete lines matching pattern
echo -e "apple\nbanana\napple" | sed '/apple/d'
# Output: banana

# Edit a file in place
sed -i 's/old/new/g' /path/to/file.txt

# Use different delimiter (useful for paths)
sed 's|/old/path|/new/path|g' file.txt

# Multiple substitutions
echo "Hello World" | sed 's/Hello/Hi/; s/World/Universe/'
# Output: Hi Universe
```

### awk: Text Processing Language

```bash
#!/bin/bash
# Print specific columns
echo "Alice 30 Engineer" | awk '{print $1, $3}'
# Output: Alice Engineer

# Use a different delimiter
echo "alice:30:engineer" | awk -F: '{print $1, $3}'
# Output: alice engineer

# Process multiple lines
echo -e "Alice 30\nBob 25\nCharlie 35" | awk '{print $1 " is " $2 " years old"}'
# Output:
# Alice is 30 years old
# Bob is 25 years old
# Charlie is 35 years old

# Conditional processing
echo -e "Alice 30\nBob 25\nCharlie 35" | awk '$2 > 28 {print $1}'
# Output:
# Alice
# Charlie

# Sum a column
echo -e "10\n20\n30" | awk '{sum += $1} END {print sum}'
# Output: 60
```

### Combining Tools: Pipelines

```bash
#!/bin/bash
# Find ERROR lines, count them, show top 5
grep "ERROR" /var/log/syslog | awk -F: '{print $1}' | sort | uniq -c | sort -rn | head -5

# Breaking it down:
grep "ERROR" /var/log/syslog     # Find ERROR lines
awk -F: '{print $1}'             # Extract first column (delimiter is :)
sort                             # Sort alphabetically
uniq -c                          # Count unique occurrences
sort -rn                          # Sort by count (numeric, reverse)
head -5                          # Show top 5
```

---

## Practical Scripts: Your Exam Scenarios

### Script 1: Backup Configs with Error Handling

```bash
#!/bin/bash

# Configuration
BACKUP_DIR="/home/backups"
CONFIG_DIR="/home/configs"
LOG_FILE="/var/log/backup.log"
RETENTION_DAYS=30

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function: Log messages
log_message() {
    local LEVEL=$1
    local MESSAGE=$2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$LEVEL] $MESSAGE" >> "$LOG_FILE"
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $MESSAGE"
}

# Function: Error handler
error_exit() {
    local MESSAGE=$1
    echo -e "${RED}ERROR: $MESSAGE${NC}" >&2
    log_message "ERROR" "$MESSAGE"
    exit 1
}

# Validate directories
if [ ! -d "$CONFIG_DIR" ]; then
    error_exit "Config directory does not exist: $CONFIG_DIR"
fi

# Create backup directory
mkdir -p "$BACKUP_DIR" || error_exit "Cannot create backup directory"

# Calculate version number
VERSION=$(ls "$BACKUP_DIR"/backup_v*.tar.gz 2>/dev/null | wc -l)
VERSION=$((VERSION + 1))

# Create timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="backup_v${VERSION}_${TIMESTAMP}.tar.gz"

# Perform backup
log_message "INFO" "Starting backup: $BACKUP_FILE"
if tar czf "$BACKUP_DIR/$BACKUP_FILE" -C "$CONFIG_DIR" .; then
    log_message "INFO" "Backup successful: $BACKUP_FILE"
else
    error_exit "Backup failed for: $BACKUP_FILE"
fi

# Verify backup
if [ -f "$BACKUP_DIR/$BACKUP_FILE" ]; then
    SIZE=$(du -sh "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
    log_message "INFO" "Backup verified. Size: $SIZE"
else
    error_exit "Backup file not found after creation"
fi

# Clean up old backups (retention policy)
CUTOFF_DATE=$(date -d "$RETENTION_DAYS days ago" +%Y%m%d)
log_message "INFO" "Removing backups older than $RETENTION_DAYS days"
find "$BACKUP_DIR" -name "backup_v*.tar.gz" -type f | while read BACKUP; do
    FILE_DATE=$(stat -c %y "$BACKUP" | cut -d' ' -f1 | tr -d '-')
    if [ "$FILE_DATE" -lt "$CUTOFF_DATE" ]; then
        rm "$BACKUP"
        log_message "INFO" "Removed old backup: $(basename $BACKUP)"
    fi
done

log_message "INFO" "Backup process completed"
exit 0
```

### Script 2: Firewalld Setup with Service Verification

```bash
#!/bin/bash

# Configuration
LOG_FILE="/var/log/firewalld_setup.log"
SERVICE_NAME="firewalld"
SERVICE_PATH="/usr/lib/systemd/system/firewalld.service"

# Function: Initialize log
init_log() {
    echo "========================================" >> "$LOG_FILE"
    echo "Firewalld Setup: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
}

# Function: Log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Initialize logging
init_log

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log "ERROR: This script must be run as root"
    echo "ERROR: This script must be run as root" >&2
    exit 1
fi

# Check if firewalld service file exists
if [ ! -f "$SERVICE_PATH" ]; then
    log "ERROR: Firewalld service file not found at $SERVICE_PATH"
    echo "ERROR: Firewalld not installed" >&2
    exit 1
fi

log "INFO: Starting firewalld setup"

# Check current status
if systemctl is-active --quiet $SERVICE_NAME; then
    log "INFO: $SERVICE_NAME is already running"
    echo "$SERVICE_NAME is already running"
else
    log "INFO: Starting $SERVICE_NAME"
    if systemctl start $SERVICE_NAME; then
        log "INFO: $SERVICE_NAME started successfully"
        echo "$SERVICE_NAME started successfully"
    else
        log "ERROR: Failed to start $SERVICE_NAME"
        exit 1
    fi
fi

# Check if enabled on boot
if systemctl is-enabled --quiet $SERVICE_NAME; then
    log "INFO: $SERVICE_NAME is enabled on boot"
    echo "$SERVICE_NAME is already enabled on boot"
else
    log "INFO: Enabling $SERVICE_NAME on boot"
    if systemctl enable $SERVICE_NAME; then
        log "INFO: $SERVICE_NAME enabled on boot"
        echo "$SERVICE_NAME enabled on boot"
    else
        log "ERROR: Failed to enable $SERVICE_NAME"
        exit 1
    fi
fi

# Verify status
log "INFO: Verifying service status"
echo "========== Service Status ==========" >> "$LOG_FILE"
systemctl status $SERVICE_NAME --no-pager -l >> "$LOG_FILE"
echo "====================================" >> "$LOG_FILE"

# Check if service is active
if systemctl is-active --quiet $SERVICE_NAME; then
    log "SUCCESS: $SERVICE_NAME setup complete and verified"
    echo "SUCCESS: $SERVICE_NAME setup complete"
    exit 0
else
    log "ERROR: $SERVICE_NAME is not running after setup"
    echo "ERROR: $SERVICE_NAME setup failed" >&2
    exit 1
fi
```

### Script 3: Advanced Git Workflow Script

```bash
#!/bin/bash

# Configuration
REPO_PATH="."
MAIN_BRANCH="main"
DEV_BRANCH="dev"

# Function: Validate git repository
validate_repo() {
    if [ ! -d ".git" ]; then
        echo "ERROR: Not in a git repository" >&2
        exit 1
    fi
}

# Function: Stash and switch branch
stash_and_switch() {
    local STASH_MESSAGE=$1
    local TARGET_BRANCH=$2

    # Save current work
    git stash push -m "$STASH_MESSAGE" || {
        echo "ERROR: Failed to stash changes"
        return 1
    }

    # Switch branch
    git checkout "$TARGET_BRANCH" || {
        echo "ERROR: Failed to checkout $TARGET_BRANCH"
        git stash pop  # Restore changes if checkout fails
        return 1
    }

    echo "Stashed: $STASH_MESSAGE"
    echo "Switched to: $TARGET_BRANCH"
}

# Function: Apply stash
apply_stash() {
    local STASH_ID=$1

    if git stash pop "$STASH_ID"; then
        echo "Stash applied successfully"
    else
        echo "ERROR: Failed to apply stash"
        return 1
    fi
}

# Function: Revert commit
revert_commit() {
    local COMMIT_HASH=$1

    if git revert "$COMMIT_HASH" --no-edit; then
        echo "Commit reverted: $COMMIT_HASH"
    else
        echo "ERROR: Failed to revert commit"
        return 1
    fi
}

# Function: Create and push tag
create_tag() {
    local TAG_NAME=$1
    local TAG_MESSAGE=${2:-"Release $TAG_NAME"}

    if git tag -a "$TAG_NAME" -m "$TAG_MESSAGE"; then
        echo "Tag created: $TAG_NAME"
        
        if git push origin "$TAG_NAME"; then
            echo "Tag pushed: $TAG_NAME"
        else
            echo "WARNING: Failed to push tag"
            return 1
        fi
    else
        echo "ERROR: Failed to create tag"
        return 1
    fi
}

# Main script
validate_repo

# Example workflow
case "${1:-help}" in
    stash)
        stash_and_switch "work in progress" "$DEV_BRANCH"
        ;;
    revert)
        if [ -z "$2" ]; then
            echo "Usage: $0 revert <commit-hash>"
            exit 1
        fi
        revert_commit "$2"
        ;;
    tag)
        if [ -z "$2" ]; then
            echo "Usage: $0 tag <version>"
            exit 1
        fi
        create_tag "$2"
        ;;
    status)
        git log --oneline --decorate --graph -10
        ;;
    *)
        echo "Usage: $0 {stash|revert <commit>|tag <version>|status}"
        exit 1
        ;;
esac
```

### Script 4: System Monitoring and Alerting

```bash
#!/bin/bash

# Configuration
THRESHOLD_CPU=80
THRESHOLD_DISK=80
THRESHOLD_MEMORY=80
ALERT_LOG="/var/log/system_alerts.log"
EMAIL="admin@example.com"

# Function: Log alert
log_alert() {
    local ALERT=$1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERT: $ALERT" >> "$ALERT_LOG"
    echo "ALERT: $ALERT"
}

# Function: Check CPU usage
check_cpu() {
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    CPU_INT=$(printf "%.0f" "$CPU_USAGE")
    
    if [ "$CPU_INT" -gt "$THRESHOLD_CPU" ]; then
        log_alert "CPU usage is ${CPU_INT}% (threshold: ${THRESHOLD_CPU}%)"
        return 1
    fi
    return 0
}

# Function: Check disk usage
check_disk() {
    df -h | tail -n +2 | while read line; do
        USAGE=$(echo "$line" | awk '{print $(NF-1)}' | sed 's/%//')
        MOUNT=$(echo "$line" | awk '{print $NF}')
        
        if [ "$USAGE" -gt "$THRESHOLD_DISK" ]; then
            log_alert "Disk usage on $MOUNT is ${USAGE}% (threshold: ${THRESHOLD_DISK}%)"
            return 1
        fi
    done
    return 0
}

# Function: Check memory usage
check_memory() {
    MEMORY_USAGE=$(free | grep Mem | awk '{printf("%.0f", ($3/$2) * 100)}')
    
    if [ "$MEMORY_USAGE" -gt "$THRESHOLD_MEMORY" ]; then
        log_alert "Memory usage is ${MEMORY_USAGE}% (threshold: ${THRESHOLD_MEMORY}%)"
        return 1
    fi
    return 0
}

# Function: Check service status
check_service() {
    local SERVICE=$1
    
    if ! systemctl is-active --quiet "$SERVICE"; then
        log_alert "Service $SERVICE is not running"
        # Attempt to restart
        systemctl restart "$SERVICE"
        if systemctl is-active --quiet "$SERVICE"; then
            log_alert "Service $SERVICE restarted successfully"
        fi
        return 1
    fi
    return 0
}

# Main monitoring loop
echo "System Monitoring Started: $(date)" >> "$ALERT_LOG"

check_cpu
check_disk
check_memory
check_service "nginx"
check_service "mysql"

echo "System check completed: $(date)" >> "$ALERT_LOG"
```

---



**1. Command Execution Model**
- Shebang tells OS which interpreter to use
- Each line is parsed left-to-right
- Exit codes (0 = success, 1-255 = failure) control flow

**2. Variables**
- No spaces around `=` when assigning
- Use `$VAR` to access
- `$(command)` captures command output

**3. Redirection**
- `>` overwrites, `>>` appends
- `2>` redirects errors
- `2>&1` combines stdout and stderr

**4. Control Flow**
- `if/then/else/fi` for conditionals
- `for/while` loops for repetition
- `case` for multiple choices
- `&&` and `||` for logic chaining

**5. Common Tools**
- `grep`: Find text patterns
- `sed`: Replace text
- `awk`: Process columnar data
- `tar`: Archive files
- `systemctl`: Manage services


---

## Quick Reference Table

| Task | Command | Example |
| --- | --- | --- |
| Make executable | `chmod +x` | `chmod +x script.sh` |
| Run script | `./` | `./script.sh` |
| Capture output | `$(command)` | `DATE=$(date +%Y%m%d)` |
| Redirect output | `>` or `>>` | `echo "log" >> file.log` |
| Redirect errors | `2>` or `2>&1` | `command 2>/dev/null` |
| Test condition | `[ condition ]` | `[ -f /etc/hosts ]` |
| If statement | `if/then/else/fi` | `if [ -d /tmp ]; then...fi` |
| Loop | `for/while/until` | `for i in {1..5}; do...done` |
| Function | `name() { }` | `backup() { tar czf...; }` |
| Find text | `grep` | `grep "error" /var/log/syslog` |
| Replace text | `sed 's///g'` | `sed 's/old/new/g' file.txt` |
| Process columns | `awk` | `awk -F: '{print $1}'` |
| Archive files | `tar czf` | `tar czf backup.tar.gz folder/` |
| Manage services | `systemctl` | `systemctl start nginx` |
| View logs | `journalctl` | `journalctl -u nginx -xe` |

---

## Conclusion

Bash scripting is the bridge between your intentions and the Linux system's actions. Master:

1. **Variables** to store data dynamically
2. **Command substitution** to use command output as data
3. **Redirection** to control input/output flows
4. **Control flow** to make intelligent decisions
5. **Text processing** to extract and transform data
6. **Functions** to organize reusable code
7. **Error handling** to make scripts production-ready

