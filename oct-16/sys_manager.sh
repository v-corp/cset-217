#!/bin/bash

case "$1" in
    "add_users")
        if [ "$EUID" -ne 0 ]; then
            echo -e "gib me root bruh${NC}"
            exit 1
        fi

        file="$2"
        if [ ! -f "$file" ]; then
            echo -e "you sure you passed the correct file??? $file${NC}"
            exit 1
        fi

        created=0
        exists=0

        while read username; do
            if [ -z "$username" ]; then
                continue
            fi

            if id "$username" >/dev/null 2>&1; then
                echo -e "$username already exists${NC}"
                ((exists++))
            else
                useradd -m "$username"
                if [ $? -eq 0 ]; then
                    echo -e "$created $username${NC}"
                    ((created++))
                else
                    echo -e "$uh oh, that didnt work out to create $username${NC}"
                fi
            fi
        done < "$file"

        echo ""
        echo "created these new users: $created"
        echo "these users already existed: $exists"
        ;;

    "setup_projects")
        if [ "$EUID" -ne 0 ]; then
            echo -e "$root for this${NC}"
            exit 1
        fi

        username="$2"
        num_projects="$3"

        if ! id "$username" >/dev/null 2>&1; then
            echo -e "$User $username doesn't exist${NC}"
            exit 1
        fi

        base_dir="/home/$username/projects"
        mkdir -p "$base_dir"

        for i in $(seq 1 $num_projects); do
            project_dir="$base_dir/project$i"
            mkdir -p "$project_dir"

            echo "project$i" > "$project_dir/README.txt"
            echo "blablabalhuhnaheutnahtnh"  >> "$project_dir/README.txt"
            echo "created: $(date)" >> "$project_dir/README.txt"
            echo "user: $username" >> "$project_dir/README.txt"

            chown -R "$username:$username" "$project_dir"
            chmod 755 "$project_dir"
            chmod 640 "$project_dir/README.txt"

            echo -e "created some $project_dir${NC}"
        done

        echo -e "created the  projects for $username${NC}"
        ;;

    "sys_report")
        file="$2"
        if [ -z "$file" ]; then
            echo "need a file name bruh"
            exit 1
        fi

        echo "system report" > $file
        echo "time: $(date)" >> $file
        echo "" >> $file
        echo "disk stuff:" >> $file
        df -h >> $file
        echo "" >> $file
        echo "mem stuff:" >> $file
        free -h >> $file
        echo "" >> $file
        echo "cpu stuff:" >> $file
        grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | sed 's/^ *//' >> $file
        nproc >> $file
        top -bn1 | grep "cpu" >> $file
        echo "" >> $file
        echo "big mem hogs:" >> $file
        ps aux --sort=-%mem | head -6 | awk '{print $1 " " $3 " " $4 " " $11}' >> $file
        echo "" >> $file
        echo "big cpu hogs:" >> $file
        ps aux --sort=-%cpu | head -6 | awk '{print $1 " " $3 " " $4 " " $11}' >> $file

        echo "aded this in the give file:  $file"
        ;;

    "process_manage")
        action="$2"

        if [ -z "$action" ]; then
            echo "Usage: $0 process_manage <action>"
            echo "Actions: kill_stopped"
            exit 1
        fi

        case "$action" in
            "kill_stopped")
                echo "killin stopped procs..."
                stopped_pids=$(ps aux | awk '$8 ~ /^T/ {print $2}')

                if [ -z "$stopped_pids" ]; then
                    echo "no stopped procs found"
                else
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
esac
