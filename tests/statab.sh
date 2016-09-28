#! /bin/bash
# Wrapper for Stata batch-mode which:
#  -issues an informative error msg and appropriate (possibly non-zero) return code
# Requirements: set $STATABATCH (e.g. 'stata-mp -b')

# updated from Phil Schumm's version at https://gist.github.com/pschumm/b967dfc7f723507ac4be

args=$#  # number of args

cmd=""
if [ "$1" = "do" ] && [ "$args" -gt 1 ]
then
    log="`basename -s .do "$2"`.log"
    # mimic Stata's behavior (stata-se -b do "foo bar.do" -> foo.log)
    log=${log/% */.log}
else
    # else Stata interprets it as a command and logs to stata.log
    log="stata.log"    
fi

# in batch mode, nothing sent to stdout (is this guaranteed?)
stderr=`$STATABATCH $cmd "$@" 2>&1`

rc=$?
if [ -n "$stderr" ]  # typically usage info
then
    echo "$stderr"
    exit $rc
elif [ $rc != "0" ]
then
    exit $rc
else
    # use --max-count to avoid matching final line ("end of do-file") when
    # do-file terminates with error
    if egrep --before-context=1 --max-count=1 "^r\([0-9]+\);$" "$log"
    then
        exit 1
    fi
fi
