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
my @rank;


if ( (@ARGV < 3) || (@ARGV > 4) )
{  printf STDERR ("Usage: election_results.pl <ContestManifest.json> <CandidateManifest.json> <CvrExport> [ <ContestId> ]\n\n");
   exit(1);
}


# check argument syntax (path to ContestManifest.json)
if ($ARGV[0] =~ /^([-.\/\w]+)$/)
{   $contest_file = $1;
} else
{  printf STDERR ("invalid characters in ContestManifest filename\n");
   exit(1);
};
if (!(-f $contest_file))
{  printf STDERR ("unable to open ContestManifest file\n");
   exit(1);
};


# check argument syntax (path to CandidateManifest.json)
if ($ARGV[1] =~ /^([-.\/\w]+)$/)
{   $condidate_file = $1;
} else
{  printf STDERR ("invalid characters in CandidateManifest filename\n");
   exit(1);
};
if (!(-f $condidate_file))
{  printf STDERR ("unable to open CandidateManifest file\n");
   exit(1);
};


# check argument syntax (path to directory containing CvrExport files)
if ($ARGV[2] =~ /^([-.\/\w]+)$/)
{   $cvr_dir = $1;
} else
{  printf STDERR ("invalid characters in CvrExport directory name\n");
   exit(1);
};
if (!(-d $cvr_dir))
{  printf STDERR ("unable to open cvr_dir directory\n");
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
if (@ARGV < 4)
{  foreach $key (sort({$a <=> $b} keys(%{$contests})))
   {  printf(" %4i  %s\n", $key, $contests->{$key}->{'desc'});
      foreach $rec (sort({$a <=> $b} keys(%{$contests->{$key}->{'options'}})))
      {  printf(" %4s %4i  %s\n", '', $rec, $contests->{$key}->{'options'}->{$rec}->{'desc'});
      };
      printf("\n");
   };
   exit(0);
};
$id = $ARGV[3];


$recs    = [];
$options = $contests->{$id}->{'options'};


# open directory
printf("processing records ...\n");
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


printf("\n\n");
printf("%s\n", $contests->{$id}->{'desc'});
for($round = 1; ($round < 5); $round++)
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
   printf("Round %i:\n", $round);
   $lcandidate = 0;
   $lcount     = 0;
   foreach $key (sort(keys(%{$options})))
   {  $perc = ($options->{$key}->{'count'} / $total) * 100;
      printf("   %8s  %6.2f%%  %s\n", $options->{$key}->{'count'}, $perc, $options->{$key}->{'desc'});
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
   printf("\n\n");
};


# end of script
