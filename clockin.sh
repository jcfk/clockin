#!/bin/bash

HELP="USAGE:
  clockin     [OPTIONS...] _event_  - Log an event
  clockin end [OPTIONS...]          - End the current event
  clockin ls  [OPTIONS...]          - List events
  clockin vi  [OPTIONS...]          - Open DB_FILE in editor

OPTIONS:
  --time _time_  - Specify time in GNU date format
  --help         - Print this message"

err() {
    echo "$1" ; exit 1
}

IFS="
"

DB_FILE="$MY_SYNC/corpus/dump/clockin"
LIST_COUNT=10 # no of events to display
TIME=""
EVENT=""
COMMAND="clockin"
DATE_FMT="+%a %D %p %I:%M"

LAST_EVENT_TIME=$(date --date="@$(tail -n1 "$DB_FILE" | cut -d">" -f1)" "+%s")
LAST_EVENT_NAME="$(tail -n1 "$DB_FILE" | cut -d">" -f2 | cut -c 2-)"
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
        "--help")
            echo "$HELP" ; exit 0
        ;;
        *)
            err "unknown option \"$1\""
        ;;
    esac
    shift
done

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
        echo "Ended \"$LAST_EVENT_NAME\" at $(date --date="@$TIME" "$DATE_FMT")."
    ;;
    "ls")
        EVENT_LINES="$(tail -n$LIST_COUNT "$DB_FILE")"
        MAX_LEN_NAME=$(echo "$EVENT_LINES" | cut -d">" -f2 | cut -c 2- | wc -L)

        LAST_TIME=""
        for LINE in $EVENT_LINES ; do
            EVENT_TIME="$(echo "$LINE" | cut -d">" -f1)"
            EVENT_NAME="$(echo "$LINE" | cut -d">" -f2 | cut -c 2-)"

            if [[ "$LAST_TIME" ]] ; then
                TIME_DIFF=$(expr $EVENT_TIME - $LAST_TIME)
                TIME_DIFF_H=$(expr $TIME_DIFF / 3600)
                TIME_DIFF_M=$(expr \( $TIME_DIFF % 3600 \) / 60)
                printf " (+%dh%02dm)\n" $TIME_DIFF_H $TIME_DIFF_M
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


