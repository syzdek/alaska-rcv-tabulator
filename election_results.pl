#!/opt/local/bin/perl -Tw
#
#   Alaska Rank Choice Voting Tabulator
#   Copyright (C) 2026 David M. Syzdek <david@syzdek.net>.
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are
#   met:
#
#      * Redistributions of source code must retain the above copyright
#        notice, this list of conditions and the following disclaimer.
#      * Redistributions in binary form must reproduce the above copyright
#        notice, this list of conditions and the following disclaimer in the
#        documentation and/or other materials provided with the distribution.
#      * Neither the name of David M. Syzdek nor the
#        names of its contributors may be used to endorse or promote products
#        derived from this software without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
#   IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
#   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
#   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL DAVID M SYZDEK BE LIABLE FOR
#   ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
#   DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
#   SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
#   CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
#   LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
#   OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
#   SUCH DAMAGE.
#

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
my $rounds;
my $total;
my $perc;
my $winner;
my $contest_recs;
my @ranks;
my @ids;


if ( (@ARGV < 1) || (@ARGV > 2) )
{  printf STDERR ("Usage: election_results.pl <CvrExport Directory>\n");
   printf STDERR ("       election_results.pl <CvrExport Directory> all\n");
   printf STDERR ("       election_results.pl <CvrExport Directory> <ContestId>\n");
   printf STDERR ("\n");
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
{   $ids[@ids]                             = $rec->{'Id'};
    $contests->{$rec->{'Id'}}              = {};
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
if ( (!(defined($contests->{$id}->{'options'}))) && ($id ne 'all') )
{  printf STDERR ("unknown contest id\n");
   exit(1);
};


$contest_recs        = {};
$contest_recs->{$_}  = [] foreach (@ids);
@ids                 = ( $id ) if ($id ne 'all');


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
      {  next if ( ($contest->{'Id'} ne $id) && ($id ne 'all') );
         @ranks = ( 0, 0, 0, 0, 0, 0, 0 );
         foreach $mark (@{$contest->{'Marks'}})
         { # skip marks that ranked two candidates the same
           if (($ranks[$mark->{'Rank'}]))
           {  $ranks[$mark->{'Rank'}] = -1;
              next;
           };
           $ranks[$mark->{'Rank'}] = $mark->{'CandidateId'};
         };
         $rec              = {};
         $rec->{'marks'}   = [ $ranks[1], $ranks[2], $ranks[3], $ranks[4], $ranks[5], $ranks[6] ];
         $rec->{'counted'} = {};
         $contest_recs->{$contest->{'Id'}}->[@{$contest_recs->{$contest->{'Id'}}}] = $rec;
      };
   };
};
closedir(DIR);

foreach $id (sort({$a <=> $b} @ids))
{
   printf("%s\n", $contests->{$id}->{'desc'});
   print "-" x length($contests->{$id}->{'desc'});
   printf("\n");
   $winner   = 0;
   $recs     = $contest_recs->{$id};
   $options  = $contests->{$id}->{'options'};
   $rounds   = ($contests->{$id}->{'ranks'} > 0)
             ? $contests->{$id}->{'ranks'} + 1
             : 2;
   for($round = 1; ( ($round < $rounds) && (!($winner)) ); $round++)
   {
      $total      = 0;
      $lcandidate = 0;
      $lcount     = 0;

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
      foreach $key (sort(keys(%{$options})))
      {  $perc   = '0.00';
         $perc   = ($options->{$key}->{'count'} / $total) * 100 if ($total > 0);
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
      delete($options->{$lcandidate}) if ((defined($options->{$lcandidate})));
      printf("\n");
   };
};


# end of script
