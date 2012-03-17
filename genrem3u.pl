#!/usr/bin/perl
# genrem3u.pl, written by Ian Douglas, iandouglas.com
# builds m3u playlists based on ID3 'genre' tag in MP3/OGG files
# that are found in the defined library
#
# don't forget to read the genrem3u.readme file!!

use File::Glob ;
use Getopt::Long ;

# this is where your jukebox is actually mounted
$MOUNTPATH="/music" ;
# full disk path for a *MOUNTED* H300 for where your playlists will be
$M3UPATH="/playlists" ;
# full disk path for where your base music folder is, to where the H300
# player would find the music ... typically this is called '/music' just
# like your microphone/line-in recordings are in a folder called '/recording/'
# and so on.
$MUSICPATH="/music" ;
# where to store temporary files
$TMPPATH="/tmp" ;
# what utility do you use to convert linefeeds?
$DOS2UNIX="unix2dos" ; # I use this on Ubuntu
#$DOS2UNIX="crlf -v -d" ; # I use this on gentoo

# shouldn't need to change anything beyond this point in the file

### LIBRARIES

### GLOBALS
my (
		%moo,
		$VERBOSE,
		$OVERWRITE,
		@infiles,
		@myfiles,
		%ALLFILES,
	 ) ;
%moo = () ;
@infiles = () ;
@myfiles = () ;


# get cmdline options and print usage
GetOptions ("help:s"=>\$moo{'help'},"overwrite:s"=>\$moo{'overwrite'},"verbose:s"=>\$moo{'verbose'},"genre=s"=>\$moo{'genre'},"random:s"=>\$moo{'random'}) ;
if (defined($moo{'help'})) {
	Usage() ;
	exit ;
}
$RANDOMIZE = (defined($moo{'random'}) ? 1 : 0) ;
$ONEGENRE = $moo{'genre'} ;
$VERBOSE = 1 ;
#$VERBOSE = defined($moo{'verbose'}) ;
$OVERWRITE = (defined($moo{'overwrite'}) ? "Y" : "N") ;
#]]]

print "Overwrite Mode: $OVERWRITE\n" if ($VERBOSE) ;

@infiles = @ARGV ;

if (!$ARGV[0]) {
	push (@infiles, "$MOUNTPATH$MUSICPATH") ;
}
print "scanning ".join(",",@infiles)."\n\n" ;

foreach my $mydir (@infiles) {
	scanfiles($mydir) ;
}
print "done scanning\n" ;
foreach my $genre (sort keys %ALLFILES) {
	print "Genre: $genre\n" ;
	$m3ufile = "$MOUNTPATH$M3UPATH/".$genre.".m3u" ;
	print "Playlist will be $m3ufile\n" if ($VERBOSE) ;
	if ($OVERWRITE eq "N" && (-f $m3ufile)) { #[[[
		open (M3U,"<$m3ufile") ;
		while (<M3U>) {
			my $filename = $_ ;
			$filename =~ s/\n// ;
			$filename =~ s/\r// ;
			if ($filename) {
				$filename = cleanfilename($filename,"linux") ;
				my $genre = getgenre("$MOUNTPATH/$filename") ;
#				print "$genre ?? $filename\n" ;
				if ($genre) {
#					print "(allfiles{$genre} << $filename\n" ;
					push(@{$ALLFILES{$genre}}, $filename) ;
				}
			}
		}
		close (M3U) ;
	} #]]]

	my @tmparr = @{$ALLFILES{$genre}} ;
	my @m3ufiles = () ;
	foreach my $file (@tmparr) {
		$file = cleanfilename($file,"linux") ;
#		$file = cleanfilename($file,"dos") ;
#		print ">>> $file\n" ;
		push (@m3ufiles, $file) ;
	}
	$cmd = "$MOUNTPATH/perl/mkm3u.pl -v " ;
	$cmd .= " -r" if ($RANDOMIZE) ;
	$cmd .= " -o" if ($OVERWRITE) ;
	$cmd .= " -p $genre" ;
	my $go = 0 ;
	foreach my $file (@m3ufiles) {
		$go = 1 ;
		$cmd .= " \"$file\"" ;
	}
	if ($go) {
		print "executing >> $cmd\n" ;
		`$cmd` ;
	}
}
print "all done\n\n" ;
exit ;
# and we're done

#[[[ sub Usage
sub Usage
{
	print "Usage: $0 [options] /path/to/starting/directory/\n" ;
	print "\n" ;
	print "Options:\n" ;
	print "--help - shows usage information\n" ;
	print "--overwrite - tells mkm3u to overwrite existing playlists if found\n" ;
	print "--verbose - plenty of debug output\n" ;
	print "--genre - if you want a specific genre only, it will build just that\n" ;
	print "          genre, used like --genre=Rock\n" ;
	print "--random - randomize the files in the playlist, instead of in the\n" ;
	print "          order they are found on the disk\n" ;
} #]]]
#[[[ sub cleanfilename
sub cleanfilename
{
	my ($filename,$mode) = @_ ;
	$filename =~ s/\n//g ;
	$filename =~ s/\r//g ;
	while ($filename =~ /^\./) {
		$filename =~ s/^\.//g ;
	}
	if ($filename) {
		if ($mode eq "linux") {
			$filename =~ s/^$MOUNTPATH\/// ;
			$filename =~ s/^$MUSICPATH\/// ;
			$filename =~ s/\\/\//g ;
			$filename =~ s/\/\//\//g ;
		} elsif ($mode == "dos") {
			$filename =~ s/\//\\/g ;
			$filename =~ s/\\\\/\\/g ;
		}
	}
	return $filename ;
} #]]]
#[[[ sub scanfiles
sub scanfiles
{
	my $mydir = shift ;
	print "." if ($VERBOSE) ; 
	opendir(DH,"$mydir") ;
	my @files = readdir(DH) ;
	closedir(DH) ;
	foreach my $filename (sort @files) {
		if (substr($filename,0,1) ne '.') {
			my $myfile = "$mydir/$filename" ;
			if ( -f "$myfile" ) {
				$filecount++ ;
				$genre = getgenre($myfile) ;
				if (!$ONEGENRE) {
					if ($genre && length($genre) > 1) {
						push (@{$ALLFILES{"$genre"}},$myfile) ;
					}
				} else {
					if ($genre eq $ONEGENRE) {
						push (@{$ALLFILES{"$genre"}},$myfile) ;
					}
				}
				if (($ONEGENRE eq "Acoustic" && $filename =~ /\(Acoustic\)/i) || (!$ONEGENRE && $filename =~ /\(Acoustic\)/i)) {
					push (@{$ALLFILES{"Acoustic"}},$myfile) ;
				} elsif (($ONEGENRE eq "Live" && $filename =~ /\(Live\)/i) || (!$ONEGENRE && $filename =~ /\(Live\)/i)) {
					push (@{$ALLFILES{"Live"}},$myfile) ;
				}
			} elsif ( -d "$myfile" ) {
				$dircount++ ;
				scanfiles ("$myfile") ;
			} else {
				print "ERROR: can't scan $myfile\n" ;
			}
			undef($myfile) ;
		}
	}
} #]]]
#[[[ sub getgenre
sub getgenre
{
	$filename = shift ;
	my (
			$genre,
			$junk,
		 ) ;
	$genre = '' ;

	if ($filename =~ /\.ogg$/i || $filename =~ /\.mp3$/i) {
		my $response = `audiotag -l "$filename" | grep GENRE` ;
		($junk, $genre) = split (/GENRE: /, $response) ;
		chomp($genre) ;
	} else {
		print stderr "$filename is not mp3 or ogg, skipping ...\n" ;
	}
	$genre =~ s/\///g ;
	$genre =~ s/ //g ;
	return $genre ;
} #]]]

# eof
