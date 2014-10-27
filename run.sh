#!/bin/sh

set -x

topdir=/media/ephemeral1/s3logs
s3bucket=puremagic-logs

# fetch all new logs from s3
~/bin/download-s3-logs $topdir/new $s3bucket "" ""
echo

cd $topdir/new
for logdir in *; do
    # skip cf based logdirs for now.. different file name structure
    if [ $logdir == "cf-downloads.dlang.org" ]; then continue; fi

    echo "Making daily log files for $logdir..."
    cd $topdir/new/$logdir
        for date in `ls -1 | cut -b1-10 | sort -u | head -n-1`; do
            echo "  $date"
            cat $date-* >> $topdir/merged.new/$logdir/$date
            rm $date-*
        done
    echo
done

cd $topdir/merged.new
for logdir in *; do
    echo "Making monthly archives files for $logdir..."
    cd $topdir/merged.new/$logdir
        for date in `ls -1 | cut -b1-7 | sort -u | head -n-1`; do
            echo "  $date"
            tar zcvf $topdir/merged/$logdir/$date.tar.gz $date-*
            rm $date-*
        done
    echo
done

