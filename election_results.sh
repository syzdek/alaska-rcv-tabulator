#!/bin/sh

PROG_NAME="$(basename "${0}")"

keyword_expand()
{
   sed \
      -e "s/@GEN_DATE@/${GEN_DATE}/g" \
      -e "s/@CVR_DATE@/${CVR_DATE}/g" \
      -e "s/@CVR_DATE_SHORT@/${CVR_DATE_SHORT}/g" \
      -e "s/@GIT_VERSION@/${GIT_VERSION}/g"
}

cd "$(dirname "${0}")" || exit 1;

if test ${#} != 1; then
   echo "Usage: ${PROG_NAME} <CVR export directory>"
   exit 1;
fi
if test ! -d "${1}"; then
   echo "${PROG_NAME}: ${1}: unable to find CVR export directory" 1>&2
   exit 1;
fi

GIT_VERSION="$(git describe --long |sed -e 's/-/./g')"
CVR_DATE="$(date -r "${1}/Configuration.json")"
CVR_DATE_SHORT="$(date -r "${1}/Configuration.json" "+%B %d, %Y")"
GEN_DATE="$(date)"
OUTPUT="results/$(date -r "${1}/Configuration.json" "+%Y-%m-%d-%H%M%S")-${GIT_VERSION}.txt"

echo "GIT_VERSION:  ${GIT_VERSION}"
echo "CVR_DATE:     ${CVR_DATE}"
echo "OUTPUT:       ${OUTPUT}"

cat << EOF |keyword_expand > "${OUTPUT}"
Generated:   @GEN_DATE@
CVR Export:  @CVR_DATE@
Script:      @GIT_VERSION@

These results were generated from an archive of the Cast Vote Record downloaded
from the Alaska Division of Elections on @CVR_DATE_SHORT@.  The SHA-512 hashes
of the files used to generate these results are included at the end of this
file.

These results are not the official results of the Alaska electtion and these
results do not account for the hand counted ballots or the write-in entries.


EOF

./election_results.pl "${1}" all >> "${OUTPUT}"
( cd "${1}" && sha512sum ./*)    >> "${OUTPUT}"

cat "${OUTPUT}"


# end of script
