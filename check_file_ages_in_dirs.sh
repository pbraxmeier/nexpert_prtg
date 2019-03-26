#! /usr/bin/env bash
#
# File ages in a directory plugin for Nagios.
# Written by Chad Phillips (chad@apartmentlines.com)
# Last Modified: 2011-02-01

PROGPATH=`dirname $0`

. $PROGPATH/utils.sh

print_usage() {
    echo "
Usage: check_file_ages_in_dirs --dirs | -d <directories> [-w <max_age>] [-c <max_age>] [-W <num_files>] [-C <num_files>] [-t <time_unit>] [-I <files>] [-s] [-V] [--check-dirs] [--base-dir <directory>]
Usage: check_file_ages_in_dirs --help | -h

Description:

This plugin pulls all files in each specified directory, and checks their
created time against the current time.  If the maximum age of any file is
exceeded, a warning/critical message is returned as appropriate.

This is useful for examining backup directories for freshness.

Tested to work on Linux/FreeBSD/OS X.

The following arguments are accepted:

  --dirs | -d     A space separated list of directories to examine.  Each
                  directory will be checked for the age of all files in the
                  directory.

  -w              (Optional) Generate a warning message if any created file is
                  older than this value.  Defaults to 26 hours.

  -c              (Optional) Generate a critical message if any created file is
                  older than this value.  Defaults to 52 hours.

  -W              (Optional) If set, a warning message will be returned if the
                  specified directory doesn't exist, or there are less than the
                  number of specified files in the specified directory.

  -C              (Optional) If set, a critical message will be returned if the
                  specified directory doesn't exist,or there are less than the
                  number of specified files in the specified directory.

  -t              (Optional) The time unit used for the -w and -c values.  Must
                  be one of: seconds, minutes, hours, days.  Defaults to hours.

  -I              (Optional) A space separated list of files to ignore.

  -s              (Optional) Print a summary of OK, Warning and Critical files
                  Cannot be used together with -V (Verbose)

  -V              (Optional) Output verbose information about all checked
                  files.  Default is only to print verbose information for
                  files with non-OK states.
                  Cannot be used together with -s (summary)

  --check-dirs    (Optional) If set, directories inside the specified directory
                  will also be checked for their creation time. Note that this
                  check is not recursive.  Without this option, only real files
                  inside the specified directory will be checked.

  --base-dir      (Optional) If set, this path will be prepended to all
                  checked directories.

  --help | -h     Print this help and exit.

Examples:

Generate a warning if any file in /backups is more than 26 hours old,
and a critical if it's more than 52 hours old...

  check_file_ages_in_dirs -d \"/backups\"

Generate a warning if any file in /var/foo or /var/bar is more than one week
old, a critical if it's more than two weeks old, or a critical if there are
less than 3 files in either directory.

  check_file_ages_in_dirs -d \"/var/foo /var/bar\" -w 7 -c 14 -t days -C 3

Caveats:

Although multiple directories can be specified, only one set of
warning/critical times can be supplied.

Linux doesn't seem to have an easy way to check file/directory creation time,
so file/directory last modification time is used instead.
"
}

print_help() {
  print_usage
  echo "File ages in a directory plugin for Nagios."
  echo ""
}

# Sets the exit status for the plugin.  This is done in such a way that the
# status can only go in one direction: OK -> WARNING -> CRITICAL.
set_exit_status() {
  new_status=$1
  # Nothing needs to be done if the state is already critical, so exclude
  # that case.
  case $exitstatus
  in
    $STATE_WARNING)
      # Only upgrade from warning to critical.
      if [ "$new_status" = "$STATE_CRITICAL" ]; then
        exitstatus=$new_status;
      fi
      ;;
    $STATE_OK)
      # Always update state if current state is OK.
      exitstatus=$new_status;
      ;;
  esac
}

# Make sure the correct number of command line
# arguments have been supplied
if [ $# -lt 1 ]; then
  print_usage
  exit $STATE_UNKNOWN
fi

# Defaults.
exitstatus=$STATE_OK
warning=26
critical=52
time_unit=hours
verbose=
summary=
num_warning=0
num_critical=0
ignore_files=
check_dirs=
base_dir=

# Grab the command line arguments.
while test -n "$1"; do
  case "$1" in
    --help)
      print_help
      exit $STATE_OK
      ;;
    -h)
      print_help
      exit $STATE_OK
      ;;
    --dirs)
      dirs=$2
      shift
      ;;
    -d)
      dirs=$2
      shift
      ;;
    -w)
      warning=$2
      shift
      ;;
    -c)
      critical=$2
      shift
      ;;
    -W)
      num_warning=$2
      shift
      ;;
    -C)
      num_critical=$2
      shift
      ;;
    -t)
      time_unit=$2
      shift
      ;;
    -I)
      ignore_files=$2
      shift
      ;;
    -s)
      summary=1
      ;;
    -V)
      verbose=1
      ;;
    --check-dirs)
      check_dirs=1
      ;;
    --base-dir)
      base_dir=$2
      shift
      ;;
    -x)
      exitstatus=$2
      shift
      ;;
    --exitstatus)
      exitstatus=$2
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      print_usage
      exit $STATE_UNKNOWN
      ;;
  esac
  shift
done

if [ ! "$dirs" ]; then
  echo "No directories provided."
  exit $STATE_UNKNOWN
fi

if [ `echo "$warning" | grep [^0-9]` ] || [ ! "$warning" ]; then
  echo "Warning value must be a number."
  exit $STATE_UNKNOWN
fi

#if [ `echo "$critical" | grep [^0-9]` ] || [ ! "$critical" ]; then
#  echo "Critical value must be a number."
#  exit $STATE_UNKNOWN
#fi

if [ "$num_warning" != "0" ] && [ `echo "$num_warning" | grep [^0-9]` ]; then
  echo "Warning value for number of files must be a number."
  exit $STATE_UNKNOWN
fi

#if [ "$num_critical" != "0" ] && [ `echo "$num_critical" | grep [^0-9]` ]; then
#  echo "Critical value for number of files must be a number."
#  exit $STATE_UNKNOWN
#fi

if [ ! `echo "$time_unit" | grep "seconds\|minutes\|hours\|days"` ]; then
  echo "Time unit must be one of: seconds, minutes, hours, days."
  exit $STATE_UNKNOWN
fi

#if [ "$warning" -ge "$critical" ]; then
#  echo "Critical time must be greater than warning time."
#  exit $STATE_UNKNOWN
#fi

#if [ "$num_critical" -ge "$num_warning" ] && [ "$num_critical" != "0" ]; then
#  echo "Critical number of files must be less than warning number of files."
#  exit $STATE_UNKNOWN
#fi

if [ "$verbose" != "" ] && [ "$summary" != "" ]; then
  echo "VERBOSE (-V) and SUMMARY (-s) can't be used together."
  exit $STATE_UNKNOWN
fi

case $time_unit
in
  days)
    multiplier=86400;
    abbreviation="days";
    ;;
  hours)
    multiplier=3600;
    abbreviation="hrs";
    ;;
  minutes)
    multiplier=60;
    abbreviation="mins";
    ;;
  *)
    multiplier=1
    abbreviation="secs";
    ;;
esac

# Starting values.
DIR_COUNT=0
OUTPUT=
CURRENT_TIME=`date +%s`
OS_DISTRO=`uname -s`

# Build type list.
file_types="-type f"
if [ -n "$check_dirs" ]; then
  file_types="( -type f -or -type d )"
fi

# Build ignore list.
ignore=""
for file in $ignore_files
do
  ignore="$ignore ! -name $file"
done


# Loop through each provided directory.
for dir in $dirs
do
  FILE_COUNT=0
  FILES_OK=0
  FILES_WARN=0
  FILES_CRITICAL=0
  DIR_COUNT=$(($DIR_COUNT + 1))

  # Check if dir exists.
  full_path=${base_dir}${dir}
  if [ -d "$full_path" ]; then
    file_list=`find $full_path -mindepth 1 -maxdepth 1 $file_types $ignore | sort`
    # Cycle through files, looking for checkable files.
    for next_filepath in $file_list
    do
      next_file=`basename $next_filepath`
      # stat doesn't work the same on Linux and FreeBSD/Darwin, so
      # make adjustments here.
      if [ "$OS_DISTRO" = "Linux" ]; then
        st_ctime=`stat -c%Y ${next_filepath}`
      else
        eval $(stat -s ${next_filepath})
      fi
      FILE_COUNT=$(($FILE_COUNT + 1))
      FILE_AGE=$(($CURRENT_TIME - $st_ctime))
      FILE_AGE_UNITS=$(($FILE_AGE / $multiplier))
      MAX_WARN_AGE=$(($warning * $multiplier))
      MAX_CRIT_AGE=$(($critical * $multiplier))
      if [ $FILE_AGE -gt $MAX_CRIT_AGE ]; then
        FILES_CRITICAL=$(($FILES_CRITICAL + 1))
        OUTPUT="$OUTPUT ${dir}/${next_file}: ${FILE_AGE_UNITS}${abbreviation}"
        set_exit_status $STATE_CRITICAL
      elif [ $FILE_AGE -gt $MAX_WARN_AGE ]; then
        FILES_WARN=$(($FILES_WARN + 1))
        OUTPUT="$OUTPUT ${dir}/${next_file}: ${FILE_AGE_UNITS}${abbreviation}"
        set_exit_status $STATE_WARNING
      else
        FILES_OK=$(($FILES_OK + 1))
        if [ "$verbose" == "1" ]; then
          OUTPUT="$OUTPUT ${dir}/${next_file}: ${FILE_AGE_UNITS}${abbreviation}"
        fi
      fi
    done
    if [ "$summary" == "1" ] ; then
      OUTPUT="OK: $FILES_OK file(s);"
      OUTPUT="$OUTPUT WARN: $FILES_WARN file(s);"
      OUTPUT="$OUTPUT CRITICAL: $FILES_CRITICAL file(s);"
    fi
    # Check here to see if enough files got tested in the directory.
    if [ "$FILE_COUNT" -lt "$num_critical" ]; then
      set_exit_status $STATE_CRITICAL
      OUTPUT="$OUTPUT ${dir}: Less than $num_critical files"
    elif [ "$FILE_COUNT" -lt "$num_warning" ]; then
      set_exit_status $STATE_WARNING
      OUTPUT="$OUTPUT ${dir}: Less than $num_warning files"
    else
      OUTPUT="$OUTPUT ${dir}: $FILE_COUNT files"
    fi
  else
    if [ "$num_critical" ]; then
      set_exit_status $STATE_CRITICAL
    elif [ "$num_warning" ]; then
      set_exit_status $STATE_WARNING
    fi
    OUTPUT="$OUTPUT ${dir}: Does not exist"
  fi
done

case $exitstatus
in
  $STATE_CRITICAL)
    exit_message="1:$FILE_COUNT";
    ;;
  $STATE_WARNING)
    exit_message="1:$FILE_COUNT";
    ;;
  $STATE_OK)
    exit_message="0:$FILE_COUNT";
    ;;
  *)
    exitstatus=$STATE_UNKNOWN;
    exit_message="1:$FILE_COUNT:UNKNOWN";
    ;;
esac

exit_message="${exit_message}: ${DIR_COUNT} dir(s)"

if [ "$OUTPUT" ]; then
  exit_message="${exit_message} -- ${OUTPUT}"
fi

echo "$exit_message"
exit $exitstatus

