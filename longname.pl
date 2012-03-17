#!/usr/bin/perl
# longname.pl written by Ian Douglas, iandouglas.com
#
# bash equivalent will find the filenames but strips the pathing:
# find . -print | awk -F'/' '{print $NF}' | egrep ".{52,}"
#
# The H300 series has/had a bug in the firmware that didn't handle
# filenames that were longer than about 52 characters in length, so
# this script will scan a starting directory and report any 
# offending files so you can manually rename them. Just make sure
# your player is set to use ID3 tagging (and make sure your files
# *have* ID3 tags; I recommend easytag) and it won't matter what
# your files are called.

$length = $ARGV[0] ;
$startdir = $ARGV[1] ;
$badfilecount = 0 ;
$filecount = 0 ;
$dircount = 0 ;

# assume 52 character filename length if one wasn't passed
if (!$length) {
	$length = 52 ;
}
# assume the current directory if one wasn't passed
if (!$startdir) {
	$startdir = "." ;
}

scandir($startdir) ;
print "found $badfilecount filenames too long, from a selection of $filecount files and $dircount folders\n" ;
exit ;

sub scandir #[[[
{
	my $mydir = shift ;
	opendir(DH,"$mydir") ;
	my @files = readdir(DH) ;
	closedir(DH) ;
	foreach my $filename (sort @files) {
		if (substr($filename,0,1) ne '.') {
			my $myfile = "$mydir/$filename" ;
			if ( -f "$myfile" ) {
				$filecount++ ;
				if (length($filename) > $length) {
					$badfilecount++ ;
					print "*** filename too long (".length($filename)."): $myfile\n" ;
				}
			} elsif ( -d "$myfile" ) {
				$dircount++ ;
				scandir ("$myfile") ;
			} else {
				print "ERROR: can't scan $myfile\n" ;
			}
			undef($myfile) ;
		}
	}
} #]]]

