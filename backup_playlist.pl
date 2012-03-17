#!/usr/bin/perl
# backup_playlist.pl written by Ian Douglas, iandouglas.com
#
# This script will take an m3u playlist and copy the files to a destination

# where do you mount your H300 player on your system?
$MOUNTPATH = "/music" ;

$filename = $ARGV[0] ;
$dir = $ARGV[1] ;
if ($filename && $dir) {
	open (FILES,"<$filename") ;
	while (<FILES>) {
		my $data = $_ ;
		chomp($data) ;
		print `cp -xai "$MOUNTPATH/$data" $dir` ;
	}
	close (FILES) ;
} else {
	print "$0 playlist.m3u /path/to/destination/\n\n" ;
	print "This script will copy playlist files to a destination folder\n" ;
	print "and prompt the user to overwrite files\n" ;
}
