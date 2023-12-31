#!/bin/bash

HELP="USAGE:
  clockin     [OPTIONS...] _event_  - Log an event
  clockin end [OPTIONS...]          - End the current event
  clockin ls  [OPTIONS...]          - List events
  clockin vi  [OPTIONS...]          - Open DB_FILE in editor

OPTIONS:
  --db-file _file_  - Specify plaintext database file
  --time _time_     - Specify time in GNU date format
  --count _num_     - List this many events
  --help            - Print this message

DB_FILE:
  This is the file that contains the data. It can be manually edited. Empty
  lines and lines beginning with '#' are ignored.

  Specify a path with envvar \$CLOCKIN_DB_FILE or override with --db-file."

err() {
    echo "$1" ; exit 1
}

db_file () {
    grep -Ev '^(#.*|\s*$)' "$DB_FILE"
}

IFS=$'\n'

DB_FILE="$CLOCKIN_DB_FILE"
LIST_COUNT=10 # no of events to display
TIME=""
EVENT=""
COMMAND="clockin"
DATE_FMT="+%a %D %p %I:%M"

LAST_EVENT_TIME=$(db_file | tail -n1 | cut -d">" -f1)
LAST_EVENT_TIME=${LAST_EVENT_TIME:-0}
LAST_EVENT_NAME="$(db_file | tail -n1 | cut -d">" -f2 | cut -c 2-)"
CURRENT_TIME=$(date "+%s")
EDITOR="${EDITOR:-vi}"

# 1. Command
if [[ "$1" ]] ; then
    for C in "end" "ls" "vi" ; do
        if [[ "$1" == "$C" ]] ; then
            COMMAND="$C"
            shift
            break
        fi
    done
fi

# 2. Options
while [[ "${1:0:1}" == "-" ]] ; do
    case "$1" in
        "--db-file")
            DB_FILE="$2"
            shift
        ;;
        "--time")
            if [[ -z "$2" ]] ; then
                err "option (--time) takes an argument"
            fi
            TIME=$(date --date="$2" "+%s")
            if [[ $? -ne 0 ]] ; then
                err "option (--time) badly formed"
            fi
            if [[ "$TIME" -gt "$CURRENT_TIME" ]] ; then
                err "option (--time) cannot be in the future"
            fi
            if [[ "$TIME" -lt "$LAST_EVENT_TIME" ]] ; then
                err "option (--time) cannot be before last event"
            fi
            shift
        ;;
        "--count")
            if [[ -z "$2" ]] ; then
                err "option (--count) takes an argument"
            fi
            if [[ "$2" -ne "$2" ]] ; then
                err "option (--count) must be a positive integer"
            fi
            LIST_COUNT="$2"
            shift
        ;;
        "--help")
            echo "$HELP" ; exit 0
        ;;
        *)
            err "unknown option \"$1\""
        ;;
    esac
    shift
done

if [[ -z "$DB_FILE" ]] ; then
    err "DB_FILE must be given"
fi

if [[ -z "$TIME" ]] ; then
    TIME="$CURRENT_TIME"
fi

# 3. Command argument
case "$COMMAND" in
    "clockin")
        if [[ -z "$1" ]] ; then
            err "command (clockin/default) takes an argument"
        fi
        EVENT="$1"
        shift
    ;;
    "end")
        if [[ "$1" ]] ; then
            err "command (end) does not take an argument"
        fi
    ;;
    "ls")
        if [[ "$1" ]] ; then
            err "command (ls) does not take an argument"
        fi
    ;;
    "vi")
        if [[ "$1" ]] ; then
            err "command (vi) does not take an argument"
        fi
    ;;
esac

# 4. Execute
case "$COMMAND" in
    "clockin")
        echo "$TIME> $EVENT" >> "$DB_FILE"
        echo "Logged \"$EVENT\" at $(date --date="@$TIME" "$DATE_FMT")."
    ;;
    "end")
        echo "$TIME>" >> "$DB_FILE"
        if [[ $LAST_EVENT_NAME ]] ; then
            echo "Ended \"$LAST_EVENT_NAME\" at $(date --date="@$TIME" "$DATE_FMT")."
        fi
    ;;
    "ls")
        EVENT_LINES="$(db_file | tail -n$LIST_COUNT)"
        MAX_LEN_NAME=$(echo "$EVENT_LINES" | cut -d">" -f2 | cut -c 2- | wc -L)

        LAST_TIME=""
        for LINE in $EVENT_LINES ; do
            EVENT_TIME="$(echo "$LINE" | cut -d">" -f1)"
            EVENT_NAME="$(echo "$LINE" | cut -d">" -f2 | cut -c 2-)"

            if [[ "$LAST_TIME" ]] ; then
                TIME_DIFF=$(expr $EVENT_TIME - $LAST_TIME)
                TIME_DIFF_H=$(expr $TIME_DIFF / 3600)
                TIME_DIFF_M=$(expr \( $TIME_DIFF % 3600 \) / 60)
                printf "  (+%dh%02dm)\n" $TIME_DIFF_H $TIME_DIFF_M
            fi

            if [[ "$EVENT_NAME" ]] ; then
                printf "$(date --date="@$EVENT_TIME" "$DATE_FMT")"
                printf " | %-${MAX_LEN_NAME}s" "$EVENT_NAME"
            fi
            LAST_TIME=$EVENT_TIME
        done
        echo
    ;;
    "vi")
        $EDITOR "$DB_FILE"
    ;;
esac

