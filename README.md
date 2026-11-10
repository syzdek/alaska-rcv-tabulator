Alaska Rank Choice Voting Tabulator
===================================

Alaska Rank Choice Voting Tabulator  
Copyright (C) 2026 David M. Syzdek <david@syzdek.net>.  
All rights reserved.  

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

   * Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.
   * Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in the
     documentation and/or other materials provided with the distribution.
   * Neither the name of David M. Syzdek nor the
     names of its contributors may be used to endorse or promote products
     derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL DAVID M SYZDEK BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.


Alaska elections use Rank Choice Voting.  In this system, voters rank
candidates in order of their favorite candidate to least favorite candidate.
The tabulation of votes is completed in one or more rounds of counting.
During the first round, all of the voters' first choice is counted. The
candidate with the least amount of votes is eleminated.  For the second
round of counting, the second choice of the voters who had seleted the
elminated candidate as their first choice, is added to the remaining
candidates tally.  This continues until a candidate exceeds 50% of the tally.


The Alaska Division of Elections releases a summary of the Alaska voters'
first choice candidates, and a digital copy of the 'Cast Vote Record'. The
Cast Vote Record contains the metadata of the digitally scanned ballots for
each of the election contests. The Cast Vote Record is released as a
collection of JSON files.  This script parses the records, tabulates the
ballots, and displays the results of each round of a contest.

The script was specifically written against the file format of the Cast Vote
Record from the 2026 midterm elections.

The Cast Vote Record can be downloaded from the Alaska Division of Elections:

   * https://www.elections.alaska.gov/election-results/

To use this script, download the CVR zip file, unpack the archive, and run
the script:

    wget https://www.elections.alaska.gov/enr/26GENR/results/CVR_Export.zip
    mkdir CVR_Export
    (cd CVR_Export && unzip ../CVR_Export.zip)
    ./election_results.pl CVR_Export all


