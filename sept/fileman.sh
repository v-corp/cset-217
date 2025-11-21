#!/bin/bash

if [ $# -lt 2 ]; then
    echo "enter cammands lil bro"
    exit 1
fi

case "$1" in
    "adddir")
        if [ -z "$3" ]; then
            echo "error"
            exit 1
        fi
        mkdir -p "$2/$3"
        echo "dir created: $2/$3"
        ;;
    "deletedir")
        if [ -z "$3" ]; then
            echo "error directory name required"
            exit 1
        fi
        if [ -d "$2/$3" ]; then
            rm -rf "$2/$3"
            echo "directory deleted: $2/$3"
        else
            echo "directory not found"
        fi
        ;;
    "deletefile")
        if [ -z "$3" ]; then
            echo "error: file name required"
            exit 1
        fi
        if [ -f "$2/$3" ]; then
            rm "$2/$3"
            echo "file deleted: $2/$3"
        else
            echo "file not found"
        fi
        ;;
    "listfiles")
        if [ -d "$2" ]; then
            ls "$2" | grep -v "/$"
        else
            echo "directory not found"
        fi
        ;;
    "listdirs")
        if [ -d "$2" ]; then
            ls -d "$2"/*/ | sed 's|.*/||; s|/$||'
        else
            echo "no directories found"
        fi
        ;;
    "listall")
        if [ -d "$2" ]; then
            ls "$2"
        else
            echo "directory not found"
        fi
        ;;
    *)
        echo "usage: $0 {adddir|deletedir|deletefile|listfiles|listdirs|listall} <path> [name]"
        exit 1
        ;;
esac
