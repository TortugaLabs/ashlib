#!/usr/bin/atf-sh
#$
#$ Based on
#$ [A Job Queue in BASH](https://hackthology.com/a-job-queue-in-bash.html)
#$ by Tim Henderson (February 2017)
#$

job_worker() {
  # This is the worker thread function

  local id="$1" ; shift

  # first open the file and locks for reading...
  exec 3<$fifo
  exec 4<$fifo_lock
  exec 5<$start_lock

  # notify parent that worker is ready...
  flock 5		# obtains tart lock
  echo $id >> $start	# put my worker id in start file
  flock -u 5		# release lock
  exec 5<&-		# close lock file
  $verbose worker $id ready

  while true
  do
    # read queue
    flock 4				# obtain fifo lock
    read -su 3 work_id work_item	# read work-id and item...
    local read_status=$?		# save the exit status...
    flock -u 4				# release fifo lock

    if [ $read_status -eq 0 ] ; then
      # Valid work item... execute
      $verbose $id got work_id=$work_id work_item=$work_item 1>&2
      # run job in subshell...
      ( "$@" "$work_id" "$work_item" )
    else
      # anything else is EOF
      break
    fi
  done
  # clean-up fds
  exec 3<&-
  exec 4<&-
  $verbose $id "done working" 1>&2
}

job_queue() { #$ run jobs from a queue in parallel
  #$ :usasge <job generator> | job_queue [--workers=n] <job_cmd> [args]
  #$ :param --workers=n: number of worker threads (defaults to 4)
  #$ :param --verbose: output messages
  #$ :param job_cmd: command to execute
  #$ :param args: optional arguments
  #$ :returns: true on succes, false on error
  #$ :input: line containing job ids.  This is use by the <job_cmd> to queue jobs.
  #$
  #$   Each read line is fed to <job_cmd> as command line arguments
  #$   of the form:
  #$
  #$ ```
  #$      <job_cmd> [arguments] <number> <input-line>
  #$ ```
  #$
  #$ Where number is a increasing integer representing the job id.
  #$
  #$ job_queue makes use of fifos and flocks to implement a simple
  #$ job queue.  A fifo is a first in first out UNIX pipe (see man
  #$ fifo). A flock (see man flock) is a "file lock" which lets
  #$ the queue support multiple readers.
  #$
  #$ The <job_cmd> can be a external command or a function that
  #$ will process the given input-lines.
  #$
  #$ A Job Queue is typically a first in first out queue of
  #$ "work items" or "jobs" to be processed. Ideally, a good job queue
  #$ should support multiple workers (also called readers) so
  #$ multiple jobs can be processed at one time. For production
  #$ systems and clusters there are many robust options availble.
  #$ Sometimes you need a job queue for a local system but cannot
  #$ install (or do not want to install) one of the many networked
  #$ job queues. But, if you are running Linux you probably have
  #$ GNU BASH installed which can be used to create a relatively
  #$ simple and robust job queue.
  #$
  #$ [See also](https://hackthology.com/a-job-queue-in-bash.html)
  local workers=4 verbose=:

  while [ $# -gt 0 ]
  do
    case "$1" in
    --workers=*)
      workers=${1#--workers=}
      ;;
    -v|--verbose)
      verbose=echo
      ;;
    *)
      break
      ;;
    esac
    shift
  done
  if [ -z "$workers" ] ; then
    echo "No workers specified" 1>&2
    return 1
  fi
  if [ "$workers" -lt 1 ] ; then
    echo "Must specify at least 1 worker ($workers)" 1>&2
    return 2
  fi
  if [ $# -eq 0 ] ; then
    echo "No job command specified" 1>&2
    return 3
  fi

  # make the IPC files
  local ipcd=$(mktemp -d)
  local start=$ipcd/start ; > $start
  local fifo=$ipcd/fifo ; mkfifo $fifo

  local fifo_lock=$ipcd/fifo.lock ; > $fifo_lock
  local start_lock=$ipcd/start.lock ; > $start_lock

  local rc=0
  (
    local i=0
    while [ $i -lt $workers ]
    do
      $verbose Starting $i 1>&2
      job_worker $i "$@" &
      i=$(expr $i + 1)
    done


    exec 3> $fifo			# Open fifo for writing
    exec 4< $start_lock		# open the start lock for reading

    # Wating for workers to start
    while true
    do
      flock 4
      local started=$(wc -l $start | cut -d ' ' -f 1)
      flock -u 4
      if [ $started -eq $workers ] ; then
	break
      else
	$verbose waiting, $started of $workers
      fi
    done
    exec 4<&- # Close start lock

    # Produce the jobs to run...
    local ln i=0
    while read ln
    do
      i=$(expr $i + 1)
      $verbose sending $i $ln 1>&2
      echo $i $ln 1>&3 ## send item to fd3
    done

    exec 3<&- # close the fifo
    wait # Wait for all the workers
  ) || rc=$?
  rm -rf $ipcd
  return $rc
}


###$_end-include
#
# Unit testing
#
[ -n "${IN_COMMON:-}" ] && return
type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/testlib/common.sh

xt_syntax() {
  : =descr "verify syntax..."

  ( xtf job_queue -v true </dev/null ) || atf_fail "Failed compilation"
}

process() {
  sleep "$1"
  echo "$4" > "$2/$3"
}

xt_check() {
  : =descr "Run compbinations"

  w=$(mktemp -p . -d)
  rc=0
  (
    set -euf -o pipefail
    start=$(date +%s)

    threads=8
    delay=3
    seq 1 $threads | job_queue --workers=$threads -v process $delay $w

    end=$(date +%s)

    if [ $(ls -1 $w | wc -l) -lt $threads ] ; then
      echo "Missing result files" 1>&2
      exit 1
    fi
    if [ $(expr $end - $start) -gt $(expr $delay '*' 2) ] ; then
      echo "Parallelization failed" 1>&2
      exit 2
    fi
  ) || rc=$?
  rm -rf "$w"
  [ $rc -eq 0 ] && return 0
  atf_fail "FAIL"
  return $rc
}

xatf_init


