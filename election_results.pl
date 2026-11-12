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
my $party_file;
my $cvr_dir;
my $file;
my $str;
my $strlen;
my $tmp;
my $contests;
my $parties;
my $rec;
my $recs;
my $sess;
my $contest;
my $key;
my $entry;
my $id;
my $exhausted;
my $mark;
my $marks;
my $options;
my $lcandidate;
my $lcount;
my $round;
my $rounds;
my $total;
my $perc;
my $rank;
my $card;
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
$party_file     = $cvr_dir . '/PartyManifest.json';


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


# parse PartyManifest
if (!(open( FILE, '<', $party_file )))
{  printf STDERR ("unable to read PartyManifest file\n");
   exit(1);
};
$tmp = decode_json(<FILE>);
close(FILE);
$parties = {};
foreach $rec (@{$tmp->{'List'}})
{   $rec->{'Description'}                 =~ s/^Registered //g;
    $parties->{$rec->{'Id'}}              = {};
    $parties->{$rec->{'Id'}}->{'id'}      = $rec->{'Id'};
    $parties->{$rec->{'Id'}}->{'desc'}    = $rec->{'Description'};
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
    $contests->{$rec->{'Id'}}->{'ballots'} = 0;
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
{  $rec->{'Party'} = '';
   if ( ((defined($rec->{'Affiliations'}->[0]))) && ((defined($parties->{$rec->{'Affiliations'}->[0]}))) )
   {  $rec->{'Party'} = $parties->{$rec->{'Affiliations'}->[0]}->{'desc'};
   };
   $contests->{$rec->{'ContestId'}}->{'options'}->{$rec->{'Id'}}            = {};
   $contests->{$rec->{'ContestId'}}->{'options'}->{$rec->{'Id'}}->{'desc'}  = $rec->{'Description'};
   $contests->{$rec->{'ContestId'}}->{'options'}->{$rec->{'Id'}}->{'party'} = $rec->{'Party'};
   $contests->{$rec->{'ContestId'}}->{'options'}->{$rec->{'Id'}}->{'count'} = 0;
};


# generates display names
foreach $key (keys(%{$contests}))
{  $strlen = 0;
   foreach $rec (values(%{$contests->{$key}->{'options'}}))
   {  $strlen = length($rec->{'desc'}) if ($strlen < length($rec->{'desc'}));
   };
   foreach $rec (values(%{$contests->{$key}->{'options'}}))
   {  if ($rec->{'party'} eq '')
      {  $rec->{'display'} = $rec->{'desc'};
      } else
      {  $rec->{'display'} = sprintf("%-*s  (%s)", $strlen, $rec->{'desc'}, $rec->{'party'});
      };
   };
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
   {  foreach $card (@{$sess->{'Original'}->{'Cards'}})
      {  foreach $contest (@{$card->{'Contests'}})
         {  next if ( ($contest->{'Id'} ne $id) && ($id ne 'all') );
            @ranks = ( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );
            foreach $mark (@{$contest->{'Marks'}})
            { $mark->{'Rank'}--;

              # skip marks that ranked two candidates the same
              if (($ranks[$mark->{'Rank'}]))
              {  $ranks[$mark->{'Rank'}] = -1;
                 next;
              };

              # save rank
              $ranks[$mark->{'Rank'}] = $mark->{'CandidateId'};
            };

            # check for more than 1 consecutive skipped ranks
            $exhausted = 0;
            for($rank = 0; ($rank < 9); $rank++)
            {  $exhausted    = 1 if   ($ranks[$rank] == -1);
               $exhausted    = 1 if ( ($ranks[$rank] ==  0) && ($ranks[$rank+1] < 1) );
               $ranks[$rank] = 0 if (($exhausted));
            };

            # record entry
            $rec              = {};
            $rec->{'marks'}   = [ @ranks ];
            $rec->{'counted'} = {};
            $contest_recs->{$contest->{'Id'}}->[@{$contest_recs->{$contest->{'Id'}}}] = $rec;
            $contests->{$contest->{'Id'}}->{'ballots'}++;
         };
      };
   };
};
closedir(DIR);

foreach $id (sort({$a <=> $b} @ids))
{
   $str = sprintf("%s (%i ballots)", $contests->{$id}->{'desc'}, $contests->{$id}->{'ballots'});
   printf("%s\n", $str);
   print "-" x length($str);
   printf("\n");
   $winner   = '';
   $recs     = $contest_recs->{$id};
   $options  = $contests->{$id}->{'options'};
   $rounds   = ($contests->{$id}->{'ranks'} > 0)
             ? $contests->{$id}->{'ranks'} + 1
             : 2;
   for($round = 1; ( ($round < $rounds) && ($winner eq '') ); $round++)
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
         $winner = $options->{$key}->{'display'} if ($perc > 50.00);

         printf("      %8s  %6.2f%%  %s\n", $options->{$key}->{'count'}, $perc, $options->{$key}->{'display'});

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

   printf("   Winner:               %s\n\n", $winner) if ($winner ne '');
   printf("\n");
};


# end of script
