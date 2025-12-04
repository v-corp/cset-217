

## Overview
This is a **multi-function bash script** that handles Linux system administration tasks:
1. Bulk user creation
2. Project directory setup
3. System reporting
4. Process management

Each function teaches core concepts you need for the exam.

---

## Part 1: The Script Entry Point

### The `case` Statement (Multiplexer)

```bash
#!/bin/bash

case "$1" in
    "add_users")
        # Function 1: Handle user creation
        ;;
    "setup_projects")
        # Function 2: Setup project directories
        ;;
    "sys_report")
        # Function 3: Generate system report
        ;;
    "process_manage")
        # Function 4: Manage processes
        ;;
    "help"|*)
        # Default: Show help
        ;;
esac
```

**What's happening:**
- `"$1"` = First argument passed to the script
- `case` checks which argument was passed
- Each `;;` ends that branch and jumps to the end of `case`
- `"help"|*)` = If you pass "help" OR anything else not matched, show help

**How to use:**
```bash
./script.sh add_users userlist.txt           # Runs add_users branch
./script.sh setup_projects alice 5           # Runs setup_projects branch
./script.sh sys_report output.txt            # Runs sys_report branch
./script.sh help                             # Shows help
./script.sh anything                         # Also shows help (default)
```

---

## Part 2: The `add_users` Function - User Bulk Creation

### Understanding the Full Flow

```bash
"add_users")
    # Step 1: Check if root
    if [ "$EUID" -ne 0 ]; then
        echo -e "gib me root bruh${NC}"
        exit 1
    fi
    
    # Step 2: Validate file
    file="$2"
    if [ ! -f "$file" ]; then
        echo -e "you sure you passed the correct file??? $file${NC}"
        exit 1
    fi
    
    # Step 3: Initialize counters
    created=0
    exists=0
    
    # Step 4: Loop through file line by line
    while read username; do
        # Step 5: Skip empty lines
        if [ -z "$username" ]; then
            continue
        fi
        
        # Step 6: Check if user already exists
        if id "$username" >/dev/null 2>&1; then
            echo -e "$username already exists${NC}"
            ((exists++))
        else
            # Step 7: Create user if doesn't exist
            useradd -m "$username"
            if [ $? -eq 0 ]; then
                echo -e "$created $username${NC}"
                ((created++))
            else
                echo -e "$uh oh, that didnt work out to create $username${NC}"
            fi
        fi
    done < "$file"
    
    # Step 8: Print summary
    echo ""
    echo "created these new users: $created"
    echo "these users already existed: $exists"
    ;;
```

### Concept 1: Root Check (`$EUID`)

```bash
if [ "$EUID" -ne 0 ]; then
    echo -e "gib me root bruh${NC}"
    exit 1
fi
```

**What:**
- `$EUID` = Effective User ID (a bash variable)
- Root always has EUID = 0
- Non-root users have EUID >= 1000

**Why:**
- You can't create users without root privileges
- Script fails fast if non-root tries to run it

**Analogy:** Like asking "Do you have admin privileges?" before granting access.

### Concept 2: File Validation

```bash
file="$2"
if [ ! -f "$file" ]; then
    echo -e "you sure you passed the correct file??? $file${NC}"
    exit 1
fi
```

**Breaking down `[ ! -f "$file" ]`:**
- `[ ... ]` = Test command
- `!` = NOT operator (inverts result)
- `-f` = "file exists and is a regular file"
- `"$file"` = The filename to test

**Logic:**
- If file exists: `-f` returns 0 (true), `!` inverts to 1 (false), if block SKIPPED
- If file doesn't exist: `-f` returns 1 (false), `!` inverts to 0 (true), if block RUNS

**Example:**
```bash
# Scenario 1: File exists
[ ! -f "users.txt" ]     # -f returns 0 (exists), ! makes it 1 (false), skip if block

# Scenario 2: File missing
[ ! -f "missing.txt" ]   # -f returns 1 (doesn't exist), ! makes it 0 (true), run if block
```

### Concept 3: Counter Variables and Increment

```bash
created=0
exists=0

# ... later in loop ...
((created++))
((exists++))
```

**What:**
- `created=0` = Initialize counter to 0
- `((created++))` = Arithmetic operation that increments by 1

**Syntax:**
- `(( ... ))` = Arithmetic context (no need for $ prefix)
- `created++` = Post-increment (add 1 to created)
- Alternative: `created=$((created + 1))`

**When to use:**
- Track how many users created
- Track how many failed
- Count iterations in a loop

### Concept 4: The `while read` Loop (Line-by-Line File Reading)

```bash
while read username; do
    # Process $username
done < "$file"
```

**How it works:**
1. `< "$file"` = Redirect file as input
2. `while read username` = Read one line, store it in `$username`
3. Loop runs once per line
4. When file ends, loop exits

**Example:**
```bash
# users.txt contains:
# alice
# bob
# charlie

while read username; do
    echo "Processing: $username"
done < "users.txt"

# Output:
# Processing: alice
# Processing: bob
# Processing: charlie
```

### Concept 5: Skipping Empty Lines

```bash
if [ -z "$username" ]; then
    continue
fi
```

**What:**
- `-z` = "string is empty"
- `continue` = Skip rest of loop, go to next iteration

**Why:** If someone puts a blank line in the file, don't try to create a user with an empty name.

### Concept 6: User Existence Check

```bash
if id "$username" >/dev/null 2>&1; then
    echo -e "$username already exists${NC}"
    ((exists++))
else
    useradd -m "$username"
    # ...
fi
```

**What:**
- `id` = Command that prints user info if user exists, error if doesn't
- `>/dev/null 2>&1` = Silence all output (we only care about exit code)
- If user exists: `id` returns 0 (true), if block runs
- If user doesn't exist: `id` returns 1 (false), else block runs

**Analogy:** "Ask the system 'Do you know this user?' If yes, exit code 0. If no, exit code 1."

### Concept 7: User Creation and Exit Code Checking

```bash
useradd -m "$username"
if [ $? -eq 0 ]; then
    echo -e "$created $username${NC}"
    ((created++))
else
    echo -e "$uh oh, that didnt work out to create $username${NC}"
fi
```

**What:**
- `useradd -m` = Create user with home directory (-m flag)
- `$?` = Exit code of previous command
- `-eq 0` = "equals 0" (success)
- If creation succeeds: `$?` is 0, increment counter
- If creation fails: `$?` is non-zero, print error

**Key insight:** Every command returns an exit code. Bash scripts check these codes to decide what to do next.

---

## Part 3: The `setup_projects` Function - Project Directory Setup

### Full Flow Analysis

```bash
"setup_projects")
    # Step 1: Root check
    if [ "$EUID" -ne 0 ]; then
        echo -e "$root for this${NC}"
        exit 1
    fi
    
    # Step 2: Get arguments
    username="$2"
    num_projects="$3"
    
    # Step 3: Validate user exists
    if ! id "$username" >/dev/null 2>&1; then
        echo -e "$User $username doesn't exist${NC}"
        exit 1
    fi
    
    # Step 4: Create base directory
    base_dir="/home/$username/projects"
    mkdir -p "$base_dir"
    
    # Step 5: Loop and create projects
    for i in $(seq 1 $num_projects); do
        project_dir="$base_dir/project$i"
        mkdir -p "$project_dir"
        
        # Create README with metadata
        echo "project$i" > "$project_dir/README.txt"
        echo "blablabalhuhnaheutnahtnh"  >> "$project_dir/README.txt"
        echo "created: $(date)" >> "$project_dir/README.txt"
        echo "user: $username" >> "$project_dir/README.txt"
        
        # Set permissions
        chown -R "$username:$username" "$project_dir"
        chmod 755 "$project_dir"
        chmod 640 "$project_dir/README.txt"
        
        echo -e "created some $project_dir${NC}"
    done
    
    echo -e "created the  projects for $username${NC}"
    ;;
```

### Concept 1: Multiple Arguments

```bash
username="$2"
num_projects="$3"
```

**What:**
- `$1` = First argument (command name, handled by outer case)
- `$2` = Second argument (username)
- `$3` = Third argument (number of projects)

**Example:**
```bash
./script.sh setup_projects alice 5
# $0 = ./script.sh
# $1 = setup_projects
# $2 = alice
# $3 = 5
```

### Concept 2: The `for` Loop with `seq`

```bash
for i in $(seq 1 $num_projects); do
    # $i takes values: 1, 2, 3, ..., $num_projects
done
```

**What:**
- `seq 1 $num_projects` = Generate sequence of numbers
- `$(...)` = Command substitution (run seq, capture output)
- `for i in` = Loop over each output line
- `$i` = Current number in iteration

**Example:**
```bash
num_projects=3
for i in $(seq 1 $num_projects); do
    echo "Loop iteration $i"
done

# Output:
# Loop iteration 1
# Loop iteration 2
# Loop iteration 3
```

### Concept 3: Variable Interpolation in Paths

```bash
base_dir="/home/$username/projects"
mkdir -p "$base_dir"

project_dir="$base_dir/project$i"
```

**What:**
- When you put `$variable` inside double quotes, bash substitutes the value
- `"$username"` → actual username value
- `"$i"` → current loop counter

**Example:**
```bash
username="alice"
i=1
project_dir="/home/$username/projects/project$i"
# Result: /home/alice/projects/project1
```

### Concept 4: File Creation with Multiple `echo` Statements

```bash
echo "project$i" > "$project_dir/README.txt"              # Overwrite (>)
echo "blablabalhuhnaheutnahtnh"  >> "$project_dir/README.txt"  # Append (>>)
echo "created: $(date)" >> "$project_dir/README.txt"      # Append
echo "user: $username" >> "$project_dir/README.txt"       # Append
```

**Flow:**
1. First `echo` with `>` creates file and writes first line
2. Subsequent `echo` with `>>` append lines to existing file
3. `$(date)` captures current date/time during execution

**Result file (README.txt):**
```
project1
blablabalhuhnaheutnahtnh
created: Thu Dec 04 11:18:00 IST 2025
user: alice
```

### Concept 5: Permission Management (`chown` and `chmod`)

```bash
chown -R "$username:$username" "$project_dir"  # Change ownership
chmod 755 "$project_dir"                       # Directory permissions
chmod 640 "$project_dir/README.txt"            # File permissions
```

**What:**
- `chown` = Change owner
  - `-R` = Recursive (apply to directory and contents)
  - `$username:$username` = New owner:group (both set to username)
- `chmod` = Change mode (permissions)
  - `755` = rwxr-xr-x (owner can do everything, others can read/execute)
  - `640` = rw-r----- (owner can read/write, group can read, others can't)

**Why:**
- User `alice` owns `/home/alice/projects/project1`
- User `alice` can read/write everything in it
- Other users can't modify alice's projects

---

## Part 4: The `sys_report` Function - System Reporting

### Full Flow Analysis

```bash
"sys_report")
    # Step 1: Validate output file argument
    file="$2"
    if [ -z "$file" ]; then
        echo "need a file name bruh"
        exit 1
    fi
    
    # Step 2: Initialize report file
    echo "system report" > $file
    echo "time: $(date)" >> $file
    echo "" >> $file
    
    # Step 3: Disk information
    echo "disk stuff:" >> $file
    df -h >> $file
    echo "" >> $file
    
    # Step 4: Memory information
    echo "mem stuff:" >> $file
    free -h >> $file
    echo "" >> $file
    
    # Step 5: CPU information
    echo "cpu stuff:" >> $file
    grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | sed 's/^ *//' >> $file
    nproc >> $file
    top -bn1 | grep "cpu" >> $file
    echo "" >> $file
    
    # Step 6: Memory hogs (top consumers)
    echo "big mem hogs:" >> $file
    ps aux --sort=-%mem | head -6 | awk '{print $1 " " $3 " " $4 " " $11}' >> $file
    echo "" >> $file
    
    # Step 7: CPU hogs
    echo "big cpu hogs:" >> $file
    ps aux --sort=-%cpu | head -6 | awk '{print $1 " " $3 " " $4 " " $11}' >> $file
    
    echo "aded this in the give file:  $file"
    ;;
```

### Concept 1: Empty String Check

```bash
if [ -z "$file" ]; then
    echo "need a file name bruh"
    exit 1
fi
```

**What:**
- `-z` = "string is zero length" (empty)
- If user doesn't pass an output filename, fail

### Concept 2: Text File Building with Append

```bash
echo "system report" > $file          # Create and write header
echo "time: $(date)" >> $file         # Append timestamp
echo "" >> $file                       # Append blank line
```

**Pattern:**
- First `echo` with `>` creates the file
- All subsequent `echo` with `>>` append to it
- Building a report line by line

### Concept 3: Command Output Redirection to File

```bash
df -h >> $file              # Append disk free output
free -h >> $file            # Append memory output
top -bn1 | grep "cpu" >> $file  # Append CPU info
```

**What:**
- `df -h` = Show disk space in human format
- `free -h` = Show memory in human format
- `top -bn1` = Non-interactive top output
- `| grep "cpu"` = Filter only CPU lines
- `>> $file` = Append all output to report file

### Concept 4: Text Processing Pipeline (grep, head, cut, sed)

```bash
grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | sed 's/^ *//' >> $file
```

**Breaking down step-by-step:**

1. **`grep "model name" /proc/cpuinfo`**
   - Find lines containing "model name" in /proc/cpuinfo
   - Output (example): `model name      : Intel(R) Core(TM) i7-9700K CPU @ 3.60GHz`

2. **`| head -1`**
   - Take only the first line (in case of multiple CPUs)
   - Output: `model name      : Intel(R) Core(TM) i7-9700K CPU @ 3.60GHz`

3. **`| cut -d':' -f2`**
   - Cut (split) the line by delimiter `:` and take field 2
   - `-d':'` = use colon as delimiter
   - `-f2` = take field 2 (second part)
   - Output: `      Intel(R) Core(TM) i7-9700K CPU @ 3.60GHz` (with leading spaces)

4. **`| sed 's/^ *//'`**
   - Substitute (s) leading spaces (^ *) with nothing (//)
   - Removes leading whitespace
   - Output: `Intel(R) Core(TM) i7-9700K CPU @ 3.60GHz`

5. **`>> $file`**
   - Append clean output to report file

**Why this matters:** This is how you **extract specific data** from complex system outputs. Essential for parsing logs and configs.

### Concept 5: Process Sorting and Filtering

```bash
ps aux --sort=-%mem | head -6 | awk '{print $1 " " $3 " " $4 " " $11}'
```

**Breaking down:**

1. **`ps aux`**
   - Show all processes with detailed info
   - Output: Multiple columns (USER, PID, %CPU, %MEM, VSZ, RSS, STAT, START, TIME, COMMAND)

2. **`--sort=-%mem`**
   - Sort by memory usage, highest first (% means percentage, - means reverse/descending)
   - Most memory-hungry processes appear first

3. **`| head -6`**
   - Take first 6 lines (5 processes + 1 header)

4. **`| awk '{print $1 " " $3 " " $4 " " $11}'`**
   - Print columns: $1=USER, $3=%CPU, $4=%MEM, $11=COMMAND
   - Example output: `alice 12.5 45.2 python`

**Why:** Find which programs are consuming most resources.

---

## Part 5: The `process_manage` Function - Nested Case Statement

### Full Flow Analysis

```bash
"process_manage")
    # Step 1: Get action argument
    action="$2"
    
    # Step 2: Validate action provided
    if [ -z "$action" ]; then
        echo "Usage: $0 process_manage <action>"
        echo "Actions: kill_stopped"
        exit 1
    fi
    
    # Step 3: Nested case for action
    case "$action" in
        "kill_stopped")
            echo "killin stopped procs..."
            
            # Get PIDs of stopped processes
            stopped_pids=$(ps aux | awk '$8 ~ /^T/ {print $2}')
            
            # If no stopped processes, inform user
            if [ -z "$stopped_pids" ]; then
                echo "no stopped procs found"
            else
                # Kill each stopped process
                for pid in $stopped_pids; do
                    kill -9 "$pid" 2>/dev/null && echo "killed pid $pid"
                done
            fi
            ;;
        *)
            echo "dunno that action: $action"
            exit 1
            ;;
    esac
    ;;
```

### Concept 1: Nested Case Statements

**Outer case** (in main case statement):
```bash
case "$1" in
    "process_manage")
        # Handle process_manage command
        ;;
esac
```

**Inner case** (inside process_manage block):
```bash
case "$action" in
    "kill_stopped")
        # Handle kill_stopped action
        ;;
esac
```

**Flow:**
```
User passes: ./script.sh process_manage kill_stopped
↓
Outer case: "$1" matches "process_manage"
↓
Set action="$2" (kill_stopped)
↓
Inner case: "$action" matches "kill_stopped"
↓
Run kill_stopped logic
```

### Concept 2: Process State Filtering with awk

```bash
stopped_pids=$(ps aux | awk '$8 ~ /^T/ {print $2}')
```

**Breaking down:**
- `ps aux` = Show all processes
- Column layout: USER PID %CPU %MEM VSZ RSS STAT START TIME COMMAND
- Column 8 = STAT (process state)
- `$8 ~ /^T/` = "If column 8 matches regex starting with T"
  - `~` = regex match operator
  - `/^T/` = starts with T (Stopped/Traced)
- `{print $2}` = Print column 2 (PID)

**Example:**
```
# ps aux output:
USER PID %CPU %MEM VSZ RSS STAT START TIME COMMAND
root 1   0.1  0.5  1000 500 S    10:00 0:01 /init
alice 2  2.5  5.0  5000 2500 T   10:05 0:10 sleep 1000
bob   3  1.2  3.0  3000 1500 S   10:06 0:05 bash

# After filtering:
# $8=STAT matches /^T/:
# alice 2 (PID=2 is stopped)

stopped_pids="2"
```

### Concept 3: Kill Processes Loop

```bash
for pid in $stopped_pids; do
    kill -9 "$pid" 2>/dev/null && echo "killed pid $pid"
done
```

**What:**
- `for pid in $stopped_pids` = Loop through each PID
- `kill -9 "$pid"` = Force kill (signal 9)
- `2>/dev/null` = Suppress error messages
- `&&` = If kill succeeds, then echo confirmation

**Signals:**
- Signal 15 (SIGTERM) = Graceful shutdown (default)
- Signal 9 (SIGKILL) = Force kill (can't be ignored)

**Example:**
```bash
kill -9 2345        # Force kill process 2345
# If successful (exit 0):
#   && runs next command
#   echo "killed pid 2345"
```

---

## Part 6: Help Text and Default Case

```bash
"help"|*)
    echo "Usage:"
    echo "  $0 add_users <file>"
    echo "  $0 setup_projects <username> <number>"
    echo "  $0 sys_report <output_file>"
    echo "  $0 process_manage <username> <action>"
    echo ""
    echo ""
    echo "  $0 help"
    ;;
```

**What:**
- `"help"|*` = Match if first argument is "help" OR anything else (*)
- Print usage instructions
- Shows all available commands and their arguments

---

## Full Script Execution Examples

### Example 1: Add Users

```bash
# Create file with usernames
cat > users.txt << EOF
alice
bob
charlie
EOF

# Run script
sudo ./script.sh add_users users.txt

# Output:
# 0 alice
# 1 bob
# 2 charlie
#
# created these new users: 3
# these users already existed: 0
```

### Example 2: Setup Projects

```bash
sudo ./script.sh setup_projects alice 3

# Creates:
# /home/alice/projects/project1/README.txt
# /home/alice/projects/project2/README.txt
# /home/alice/projects/project3/README.txt
# Each with metadata (creation time, username, etc.)
```

### Example 3: Generate System Report

```bash
./script.sh sys_report report.txt

# Creates report.txt with:
# system report
# time: Thu Dec 04 11:18:00 IST 2025
# disk stuff:
# Filesystem      Size  Used Avail Use% Mounted on
# /dev/sda1       100G   50G   50G  50% /
# ... memory info ...
# ... cpu info ...
# ... process info ...
```

### Example 4: Kill Stopped Processes

```bash
sudo ./script.sh process_manage kill_stopped

# Output:
# killin stopped procs...
# killed pid 2345
# killed pid 2346
```

---

## Key Concepts Summary

| Concept | Location | Why It Matters |
| --- | --- | --- |
| `case` statement | Main multiplexer | Route to different functions based on argument |
| `$EUID` check | User creation/project setup | Ensure script runs as root |
| File validation | `add_users` | Prevent errors from missing files |
| `while read` loop | `add_users` | Process files line by line |
| Exit code checking | Throughout | Determine if commands succeeded |
| Command substitution | `setup_projects`, `sys_report` | Capture output for use in variables |
| For loops | `setup_projects`, `process_manage` | Iterate over sequences and lists |
| Text processing pipes | `sys_report` | Extract specific data from system output |
| `awk` filtering | `sys_report`, `process_manage` | Extract columns and filter rows |
| Permission management | `setup_projects` | Set correct ownership and access rights |
| Nested case statements | `process_manage` | Handle multi-level command routing |

---


