# clockin

terminal utility to record events during your day and show their durations:

    $ clockin ls
    Thu 12/07/23 PM 11:00 | Sleep                 (+8h58m)
    Fri 12/08/23 AM 07:58 | Breakfast             (+0h31m)
    Fri 12/08/23 AM 08:30 | Work                  (+3h00m)
    Fri 12/08/23 PM 12:00 | Outside (home depot)  (+1h00m)
    Fri 12/08/23 PM 01:00 | Work                  (+10h00m)
    Fri 12/08/23 PM 11:00 | Sleep                 (+8h25m)
    Sat 12/09/23 AM 07:25 | Breakfast             (+39h34m)
    Sun 12/10/23 PM 11:00 | Sleep                 (+7h30m)
    Mon 12/11/23 AM 06:30 | Breakfast

## `--help`

    USAGE:
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

      Specify a path with envvar $CLOCKIN_DB_FILE or override with --db-file.


