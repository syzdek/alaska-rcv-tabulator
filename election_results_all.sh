#!/bin/sh

if test -z "${1}"; then
   echo "Usage: $(basename "${0}") <CvrExport Directory>" 1>&2
   exit 1;
fi

cd "$(dirname "${0}")" || exit 1;

for CONTEST in $(./election_results.pl "${1}" |grep "^Contest " |cut -d: -f1 |cut -d\  -f2); do
   ./election_results.pl "${1}" $CONTEST;
   echo "";
done

# end of script
