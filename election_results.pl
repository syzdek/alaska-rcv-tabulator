#!/opt/local/bin/perl -Tw

use strict;
use warnings;
use JSON;
use Data::Dumper;


$Data::Dumper::Indent   = 1;
$Data::Dumper::Sortkeys = 1;


my $contest_file;
my $condidate_file;
my $cvr_dir;
my $file;
my $str;
my $tmp;
my $contests;
my $rec;
my $recs;
my $sess;
my $contest;
my $key;
my $entry;
my $id;
my $mark;
my $marks;
my $options;
my $lcandidate;
my $lcount;
my $round;
my $total;
my $perc;
my $winner;
my @rank;


if ( (@ARGV < 1) || (@ARGV > 2) )
{  printf STDERR ("Usage: election_results.pl <CvrExport Directory> [ <ContestId> ]\n\n");
   exit(1);
}


# check argument syntax (path to directory containing CvrExport files)
if ($ARGV[0] =~ /^([-.\/\w]+)$/)
{   $cvr_dir = $1;
} else
{  printf STDERR ("invalid characters in CvrExport directory name\n");
   exit(1);
};


$contest_file   = $cvr_dir . '/ContestManifest.json';
$condidate_file = $cvr_dir . '/CandidateManifest.json';


# verify that directory and key files exist
if (!(-d $cvr_dir))
{  printf STDERR ("unable to find CvrExport directory\n");
   exit(1);
};
if (!(-f $contest_file))
{  printf STDERR ("unable to find ContestManifest.json file\n");
   exit(1);
};
if (!(-f $condidate_file))
{  printf STDERR ("unable to find CandidateManifest.json file\n");
   exit(1);
};


# parse ContestManifest
if (!(open( FILE, '<', $contest_file )))
{  printf STDERR ("unable to read ContestManifest file\n");
   exit(1);
};
$tmp = decode_json(<FILE>);
close(FILE);
$contests = {};
foreach $rec (@{$tmp->{'List'}})
{   $contests->{$rec->{'Id'}}              = {};
    $contests->{$rec->{'Id'}}->{'id'}      = $rec->{'Id'};
    $contests->{$rec->{'Id'}}->{'options'} = {};
    $contests->{$rec->{'Id'}}->{'desc'}    = $rec->{'Description'};
    $contests->{$rec->{'Id'}}->{'ranks'}   = (($rec->{'NumOfRanks'}))
                                           ? $rec->{'NumOfRanks'}
                                           : 1;;
};


# parse CandidateManifest and add to contest hash
if (!(open( FILE, '<', $condidate_file )))
{  printf STDERR ("unable to read CandidateManifest file\n");
   exit(1);
};
$tmp = decode_json(<FILE>);
close(FILE);
foreach $rec (@{$tmp->{'List'}})
{  $contests->{$rec->{'ContestId'}}->{'options'}->{$rec->{'Id'}}            = {};
   $contests->{$rec->{'ContestId'}}->{'options'}->{$rec->{'Id'}}->{'desc'}  = $rec->{'Description'};
   $contests->{$rec->{'ContestId'}}->{'options'}->{$rec->{'Id'}}->{'count'} = 0;
};


# prints list of contests, if contests were not specified
if (@ARGV < 2)
{  foreach $key (sort({$a <=> $b} keys(%{$contests})))
   {  $str = sprintf("Contest %i:", $key);
      printf("%-13s %s\n", $str, $contests->{$key}->{'desc'});
      foreach $rec (sort({$a <=> $b} keys(%{$contests->{$key}->{'options'}})))
      {  printf("              %s\n", $contests->{$key}->{'options'}->{$rec}->{'desc'});
      };
      printf("\n");
   };
   exit(0);
};
$id = $ARGV[1];
if (!(defined($contests->{$id}->{'options'})))
{  printf STDERR ("unknown contest id\n");
   exit(1);
};


$recs    = [];
$options = $contests->{$id}->{'options'};


# open directory
if (!(opendir(DIR, $cvr_dir)))
{  printf STDERR ("unable to read CvrExport file\n");
   exit(1);
};
while (readdir(DIR))
{  $file = $_;

   # skip the metadata files
   next if ($file !~ /CvrExport_[\d]+\.json$/i);
   if ($file =~ /^([-.\/\w]+)$/)
   {   $file = $cvr_dir . '/' . $file;
   } else
   {  printf STDERR ("unknown filename %s/%s\n", $cvr_dir, $file);
      exit(1);
   };

   # read file into memory and parse JSON
   if (!(open( FILE, '<', $file )))
   {  printf STDERR ("unable to read %s\n", $file);
      closedir(DIR);
      exit(1);
   };
   $tmp = decode_json(<FILE>);
   close(FILE);

   # loop through records
   foreach $sess (@{$tmp->{'Sessions'}})
   {  foreach $contest (@{$sess->{'Original'}->{'Cards'}->[0]->{'Contests'}})
      {  next if ($contest->{'Id'} ne $id);
         @rank = ( 0, 0, 0, 0, 0, 0, 0 );
         foreach $mark (@{$contest->{'Marks'}})
         { # skip marks that ranked two candidates the same
           if (($rank[$mark->{'Rank'}]))
           {  $rank[$mark->{'Rank'}] = -1;
              next;
           };
           $rank[$mark->{'Rank'}] = $mark->{'CandidateId'};
         };
         $rec              = {};
         $rec->{'marks'}   = [ $rank[1], $rank[2], $rank[3], $rank[4], $rank[5], $rank[6] ];
         $rec->{'counted'} = {};
         $recs->[@{$recs}] = $rec;
      };
   };
};
closedir(DIR);


printf("%s\n", $contests->{$id}->{'desc'});
print "-" x length($contests->{$id}->{'desc'});
printf("\n");
$winner = 0;
for($round = 1; ( ($round < $contests->{$id}->{'ranks'}) && (!($winner)) ); $round++)
{
   $total = 0;
   foreach $rec (@{$recs})
   {  $marks = $rec->{'marks'};
      while ( (@{$marks} > 0) && (!(defined($options->{$marks->[0]}))) )
      { shift @{$marks};
      };
      next if (@{$marks} == 0);
      $total++;
      $options->{$marks->[0]}->{'count'}++;
   };
   printf("   Round %i:\n", $round);
   $lcandidate = 0;
   $lcount     = 0;
   foreach $key (sort(keys(%{$options})))
   {  $perc   = ($options->{$key}->{'count'} / $total) * 100;
      $winner = 1 if ($perc > 50.00);
      printf("      %8s  %6.2f%%  %s\n", $options->{$key}->{'count'}, $perc, $options->{$key}->{'desc'});
      if ($lcandidate == 0)
      {  $lcandidate = $key;
         $lcount     = $options->{$key}->{'count'};
      };
      if ($lcount > $options->{$key}->{'count'})
      {  $lcandidate = $key;
         $lcount     = $options->{$key}->{'count'};
      };
      $options->{$key}->{'count'} = 0;
   };
   delete($options->{$lcandidate});
   printf("\n");
};


# end of script
