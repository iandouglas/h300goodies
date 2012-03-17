#!/usr/bin/perl
# mkm3u.pl written by Ian Douglas, iandouglas.com
# don't forget to read the mkm3u.readme file!

# this is where your jukebox is actually mounted
$MOUNTPATH="/music" ;
# full disk path for a *MOUNTED* H300 for where your playlists will be
$M3UPATH="/playlists" ;
# full disk path for where your base music folder is
$MUSICPATH="music" ;
# where to store temporary files
$TMPPATH="/tmp" ;
# what utility do you use to convert linefeeds?
$DOS2UNIX="unix2dos" ; # I use this on Ubuntu
#$DOS2UNIX="crlf -v -d" ; # I use this on gentoo
# flag to skip the first parameter which is your .m3u file
$M3UFILE=$ARGV[0] ;

# shouldn't need to change anything beyond this point in the file

### LIBRARIES
use File::Glob ;
use Getopt::Long ;

### GLOBALS
my (
		%moo, 
		@myfiles,
		$USESTDIN,
		$VERBOSE,
		$OVERWRITE,
		@infiles,
	 ) ;

%moo = () ;
@myfiles = () ;
@infiles = () ;

# get cmdline options and print usage
GetOptions ("help:s"=>\$moo{'help'},"quiet:s"=>\$moo{'quietmode'},"playlist=s"=>\$moo{'playlist'},"stdin:s"=>\$moo{'stdin'},"overwrite:s"=>\$moo{'overwrite'},"verbose:s"=>\$moo{'verbose'},"random:s"=>\$moo{'randomize'}) ;

if (defined($moo{'help'})) {
	Usage() ;
	exit ;
}

$USESTDIN = defined($moo{'stdin'}) ;
$VERBOSE = defined($moo{'verbose'}) ;
$QUIET = defined($moo{'quietmode'}) ;
$OVERWRITE = (defined($moo{'overwrite'}) ? "Y" : "N") ;
$RANDOMIZE = defined($moo{'randomize'}) ;

print "Overwrite Mode: $OVERWRITE\n" if ($VERBOSE) ;

if (defined($moo{'quietmode'}) && defined($moo{'verbose'})) {
	print "Cannot supply both verbose mode AND quiet mode, choose one or the other\n" ;
	Usage() ;
	exit ;
}
if (!$USESTDIN && !$ARGV[0]) {
	print "Must specify --stdin or supply a list of files\n\n" ;
	Usage() ;
	exit ;
}
if (!$moo{'playlist'}) {
	print "Missing playlist\n\n" ;
	Usage() ;
	exit ;
}
if ($USESTDIN && $ARGV[0]) {
	print "Cannot use both --stdin and supply files!\n\n" ;
	Usage() ;
	exit ;
}

# check if the playlist name supplied has a file extension or not
$m3ufile = "$MOUNTPATH$M3UPATH/".$moo{'playlist'} ;
if (substr($moo{'playlist'},-3,3) ne "m3u") {
	$m3ufile = "$MOUNTPATH$M3UPATH/".$moo{'playlist'}.".m3u" ;
}
print "Playlist will be $m3ufile\n" if (!$QUIET);

@myfiles = () ;

if ($OVERWRITE eq "N") {
	my @infiles = () ;
	open (M3U,"<$m3ufile") ;
	while (<M3U>) {
		my $filename = $_ ;
		$filename =~ s/\n// ;
		$filename =~ s/\r// ;
		if ($filename) {
			$filename = cleanfilename($filename,"linux") ;
			push (@infiles,$filename) ;
		}
	}
	close (M3U) ;
	print "importing:\n".join("\n",@infiles)."\n\n" if ($VERBOSE) ;
	foreach my $file (@infiles) {
		push (@myfiles,$file) ;
	}
}

# read files from STDIN or from ARGV
if ($ARGV[0]) {
	foreach my $filename (@ARGV) {
# strip any carriage returns
		$filename =~ s/\n// ;
		$filename =~ s/\r// ;
		if ($filename) {
			$filename = cleanfilename($filename,"linux") ;
#			print "$m3ufile << $filename\n" if ($VERBOSE) ;
			push (@myfiles, $filename) ;
		}
	}
} elsif ($USESTDIN) {
	my @infiles = <STDIN> ;
	foreach my $filename (sort @infiles) {
		$filename =~ s/\n// ;
		$filename =~ s/\r// ;
		$filename = cleanfilename($filename,"linux") ;
#		print "$m3ufile << $filename\n" if ($VERBOSE) ;
		push (@myfiles, $filename) ;
	}
}


my @lastfiles = () ;
foreach my $filename (@myfiles) {
	$filename = cleanfilename($filename,"linux") ;
	print "clean: $filename\n" if ($VERBOSE) ;
	if ( -f "$MOUNTPATH/$MUSICPATH/$filename") { # $filename is a file
		push (@lastfiles,$filename) ;
	} elsif ( -d "$MOUNTPATH/$MUSICPATH/$filename") { # $filename is a directory
		print "$filename is a directory... traversing\n" if ($VERBOSE) ;
		opendir(DH, "$MOUNTPATH/$MUSICPATH/$filename") or die ("couldn't opendir $MOUNTPATH/$MUSICPATH/$filename: $!") ;
		my @dirfiles = readdir(DH) ;
		closedir(DH) ;
		foreach my $dirfile (@dirfiles) {
			if (substr($dirfile,0,1) ne ".") {
				push (@lastfiles,"$filename/$dirfile") ;
			}
		}
	} else {
		print "*************************************\nskip: $filename\n**********************************\n" if ($VERBOSE) ;
	}
}
@myfiles = () ;
foreach $filename (sort @lastfiles) {
	$filename = cleanfilename($filename,"linux") ;
	push (@myfiles, "/$MUSICPATH/$filename") ;
}
print "new list\n".join("\n",@myfiles)."\n\n" if ($VERBOSE) ;

$index = 0 ;
$lastfile = '' ;
open (M3U,">$m3ufile") ;
foreach $filename (sort @myfiles) {
	if ($filename) {
		$lastfile = cleanfilename($lastfile,"linux") ;
		$filename = cleanfilename($filename,"linux") ;
		if ($filename ne $lastfile) {
			my $newline = "/$MUSICPATH/$filename" ;
#$newline =~ s/\//\\/g ;
#$newline =~ s/\\\\/\\/g ;
			$newline = cleanfilename($newline,"dos") ;
			print "$m3ufile << $newline\n" if ($VERBOSE) ;
			print M3U "$newline\r\n" ;
		} else {
		}
		$lastfile = $filename ;
	}
}
close (M3U) ;

$NUMFILES = `wc -l $m3ufile | cut -d" " -f1` ;
chomp($NUMFILES) ;
print "$m3ufile contains a total of $NUMFILES songs\n\n" if (!$QUIET) ;

if ($RANDOMIZE) {
	my @songs = () ;
	open (PLAYLIST, "<$m3ufile") or die ("Could not open $m3ufile: $!") ;
	while (<PLAYLIST>) {
		push (@songs, $_) ;
	}
	close (PLAYLIST) ;
	fisher_yates_shuffle(\@songs) ;
	open (PLAYLIST, ">$m3ufile") or die ("Could not open $m3ufile: $!") ;
	foreach my $song (@songs) {
		print PLAYLIST "$song" ;
	}
	close (PLAYLIST) ;
}
exit ;

# and we're done

sub cleanfilename #[[[
{
	my ($filename,$mode) = @_ ;
	$filename =~ s/\n//g ;
	$filename =~ s/\r//g ;

	if ($filename) {
		if ($mode eq "linux") {
			$filename =~ s/$MUSICPATH//g ;
			$filename =~ s/$MOUNTPATH//g ;
			while ($filename =~ /\\/) {
				$filename =~ s/\\/\//g ;
			}
			while ($filename =~ /\/\//) {
				$filename =~ s/\/\//\//g ;
		}
		} elsif ($mode == "dos") {
			while ($filename =~ /\//) {
				$filename =~ s/\//\\/g ;
		}
		while ($filename =~ /\\\\/) {
			$filename =~ s/\\\\/\\/g ;
		}
		$filename =~ s/\\.\\/\\/g ;
		}
	}
	return $filename ;
} #]]]
sub Usage #[[[
{
	print "Usage: $0 --playlist=MyFile [other options] (--stdin or file/dir list)\n" ;
	print "(generates MyFile.m3u)\n\n" ;
	print "--help - draws this help usage\n" ;
	print "--playlist=MyPlayList - mandatory field, can include .m3u extension or not\n" ;
	print "--quietmode - supresses all output except errors\n" ;
	print "--verbose - outputs a LOT of debug information as it works\n" ;
	print "--overwrite - tells mkm3u to overwrite playlists with the same name if\n" ;
	print "              if they already exist\n" ;
	print "--randomize - randomly sorts the list of files passed when building the\n" ;
	print "              playlist file; without it, the playlist is built with the\n" ;
	print "              exact order of the files passed\n" ;
	print "--stdin - required if no file/directory list is given\n" ;
	print "file list and/or directory list is mandatory if --stdin is not used\n" ;
	print "\nexample:\n" ;
	print "$0 --playlist=Canadian.m3u Amanda\\ Marshall/* Avril\\ Lavigne/*\n" ;
	print "\nexample:\n" ;
	print "(some process that generates a list of filenames) | \\\n" ;
	print "$0 --playlist=MyPlayList --stdin\n\n" ;
	print "example:\n" ;
	print "$0 --playlist=Rock.m3u --randomize RockSongs/*.mp3\n\n" ;
} #]]]
sub fisher_yates_shuffle { #[[[
	my $array = shift;
	my $i;
	for ($i = @$array; --$i; ) {
		my $j = int rand ($i+1);
		next if $i == $j;
		@$array[$i,$j] = @$array[$j,$i];
	}
}#]]]

# eof
