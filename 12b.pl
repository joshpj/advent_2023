#!/usr/bin/perl

use warnings;
use strict;

my $filename = shift // 'input.txt';
open my $fh, '<', $filename or die "Can't find input file $filename: $!";

my @input;
while(my $line = <$fh>)
{
	my ($condition, $groups) = split ' ', $line;
	my @grparr = split ',', $groups;
	my $unfolded_cond = join '?', (( $condition ) x 5);
	my @unfolded_grp = ( @grparr ) x 5;
	push @input, {
		'cond' => $unfolded_cond,	# eg '...###???'
		'grps' => \@unfolded_grp,	# eg [3]
	};
}

sub prune_cond
{
	# Condense input by removing unhelpful '.' positions:
	my $cond = shift;
	$cond =~ s/^\.+//; # leading
	$cond =~ s/\.+$//; # trailing
	$cond =~ s/\.+/./g; # consecutive
	return $cond;
}

sub sum
{
	my $sum = 0;
	foreach(@_){ $sum += $_ }
	return $sum;
}

sub bmask
{
	my $cond = shift;
	$cond =~ tr/#?./100/;
	return $cond;
}
sub wmask
{
	my $cond = shift;
	$cond =~ tr/#?./110/;
	return $cond;
}

my %cache;

sub count_options;
sub count_options
{
	my $freedom = shift;
	my $bmask = shift;
	my $wmask = shift;
	my @grps = @{ shift // [] };
	my $grpct = scalar(@grps);
	my $count = 0;

	my $key = "$bmask $wmask @grps";
	if(defined($cache{$key})){ return $cache{$key};}

	if($grpct <= 0){return 1;}
	elsif($grpct == 1)
	{
		for (my $i=0; $i<=$freedom; $i++)
		{
			my $option = ('0' x $i) . ('1' x $grps[0]) . ('0' x ($freedom - $i));
			my $opl = length($option);
			my $bsubmask = substr($bmask, 0, $opl);
			my $wsubmask = substr($wmask, 0, $opl);
			#print " ~ $freedom: $option & $wsubmask | $bsubmask ".(''.$option | ''.$bsubmask)." =? $option\n";
			if( (''.$option & ''.$wsubmask | ''.$bsubmask) eq $option )
			{
				$count++;
			}
		}
	}
	else
	{
		my $grp1 = shift @grps;
		for (my $i=0; $i<=$freedom; $i++)
		{
			my $option = ('0' x $i) . ('1' x $grp1) . '0'; # Final 0 is for the . element(s) that must exist
			my $opl = length($option);
			my $bsubmask = substr($bmask, 0, $opl);
			my $wsubmask = substr($wmask, 0, $opl);
			#print "$freedom: $option & $wsubmask | $bsubmask ".(''.$option | ''.$bsubmask)." =? $option\n";
			if( (''.$option & ''.$wsubmask | ''.$bsubmask) eq $option )
			{
				$count += count_options($freedom-$i, substr($bmask, $opl), substr($wmask, $opl),\@grps);
			}
		}
		$cache{$key} = $count;
	}
	return $count;
}

my $total = 0;
foreach my $row (@input)
{
	my $cond = prune_cond($row->{'cond'});
	my @grps = @{ $row->{'grps'} // []};

	my $space = length($cond);
	my $used = sum(@grps) + scalar(@grps) - 1;
	my $freedom = $space - $used;

	my $bmask = bmask($cond);
	my $wmask = wmask($cond);

	#print "[$cond - $bmask - $wmask] (@grps)\n";

	my $count = count_options($freedom, $bmask, $wmask, \@grps);

	print "$count\n";
	$total += $count;
}

print "\n\n====================\n\n";
print $total;
print "\n\n====================\n\n";

