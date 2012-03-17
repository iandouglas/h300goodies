#!/usr/bin/perl
# randomizem3u.pl, writen by Ian Douglas, iandouglas.com
#
# randomize the contents of a playlist

# this is where your jukebox is actually mounted
$MOUNTPATH="/music" ;
# full disk path for a *MOUNTED* H300 for where your playlists will be
$M3UPATH="/playlists" ;

my $playlist = $ARGV[0] ;
my @songs = () ;

$filename = $playlist ;
if ($filename !~ /m3u/) {
	$filename .= ".m3u" ;
}
open (PLAYLIST, "</$MOUNTPATH/$M3UPATH/$filename") or die ("Could not open /$MOUNTPATH/$M3UPATH/$filename for reading: $!") ;
while (<PLAYLIST>) {
	push (@songs, $_) ;
}
close (PLAYLIST) ;
fisher_yates_shuffle(\@songs) ;
open (PLAYLIST, ">/$MOUNTPATH/$M3UPATH/$filename") or die ("Could not open /$MOUNTPATH/$M3UPATH/$filename for writing: $!") ;
foreach my $song (@songs) {
	print PLAYLIST "$song" ;
}
close (PLAYLIST) ;
exit ;

sub fisher_yates_shuffle {
	my $array = shift;
	my $i;
	for ($i = @$array; --$i; ) {
		my $j = int rand ($i+1);
		next if $i == $j;
		@$array[$i,$j] = @$array[$j,$i];
	}
}

