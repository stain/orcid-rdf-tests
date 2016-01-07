#!/bin/bash

# Exit on first error
set -e

# Uncomment to debug every line
#set -v

# Start from directory containing us (assuming no symlinks)
cd `dirname "$0"`


#
error() {
  local parent_lineno="$1"
  local message="$2"
  local code="${3:-1}"
  if [[ -n "$message" ]] ; then
    echo "Error on or near "$0" line ${parent_lineno}: ${message}; exiting with status ${code}"
  else
    echo "Error on or near "$0" line ${parent_lineno}; exiting with status ${code}"
  fi
  exit "${code}"
}
trap 'error ${LINENO}' ERR
## Charles Duffy
## http://stackoverflow.com/a/185900

ORCID=http://qa.orcid.org/0000-0002-5196-1587
# Needed as pub.qa.orcid.org has an invalid SSL certificate
INSECURE=--insecure

# Latest version from http://jena.apache.org/download/index.cgi?Preferred=http%3A%2F%2Fwww.eu.apache.org%2Fdist%2F
JENA_VERSION=3.0.1


# Checking that required tools are installed
java -version >/dev/null
curl --version >/dev/null
sha1sum --version >/dev/null
if [ ! -d jena ] ; then
  echo "Downloading Apache Jena $JENA_VERSION"
  rm -rf jena.tmp
  mkdir jena.tmp
  pushd jena.tmp

  curl -f -o jena.tar.gz -L http://archive.apache.org/dist/jena/binaries/apache-jena-$JENA_VERSION.tar.gz
  echo `curl https://archive.apache.org/dist/jena/binaries/apache-jena-3.0.1.tar.gz.sha1` jena.tar.gz > jena.tar.gz.sha1
  sha1sum -c jena.tar.gz.sha1
  tar zxfv jena.tar.gz

  rm jena.tar.gz*
  popd
  mv jena.tmp/*jena*/ jena
  rm -rf jena.tmp
fi
PATH=$(pwd)/jena/bin:$PATH
export PATH
riot --version >/dev/null


## OK, let's test some ORCID RDF

rm -rf rdf
mkdir rdf
pushd rdf

curl -f -o albert.rdf    --dump-header albert.rdf.headers    -H "Accept: application/rdf+xml" -L $INSECURE $ORCID
curl -f -o albert.ttl    --dump-header albert.ttl.headers    -H "Accept: text/turtle" -L $INSECURE $ORCID
curl -f -o albert.nt     --dump-header albert.nt.headers     -H "Accept: application/n-triples" -L $INSECURE $ORCID
# FIXME: application/ld+json is broken, gives 406 Not Acceptable
#curl -v -f -o albert.jsonld --dump-header albert.jsonld.headers -H "Accept: application/ld+json" -L $INSECURE $ORCID

# Checking expected Content-Type
grep Content-Type albert.rdf.headers | grep -q application/rdf+xml
grep Content-Type albert.ttl.headers | grep -q text/turtle
# FIXME: Seems to return text/html instead!
#grep Content-Type albert.nt.headers | grep -q application/n-triples
# FIXME: jsonld not downloaded
#grep Content-Type albert.jsonld.headers | grep -q application/ld+json


#FIXME: Also: nt jsonld
#extensions="rdf ttl nt jsonld"
extensions="rdf ttl"
for ext in $extensions ; do
  f=albert.$ext
  echo "Checking $f"
  nt=$f.nt
  riot $f | sort > $nt

  # Check the person info
  echo " Checking person $ORCID"
  person=$f.person
  grep "^<$ORCID>" $nt > $person
  grep "http://www.w3.org/1999/02/22-rdf-syntax-ns#type" $person | grep -q "http://www.w3.org/ns/prov#Person"
  grep "http://www.w3.org/1999/02/22-rdf-syntax-ns#type" $person | grep -q "http://xmlns.com/foaf/0.1/Person"
  grep -q "http://www.w3.org/2000/01/rdf-schema#label" $person
  grep -q "http://xmlns.com/foaf/0.1/name" $person
  # Note: These additional properties might not exist for
  # sparsely described accounts:
  # http://xmlns.com/foaf/0.1/familyName
  # http://xmlns.com/foaf/0.1/givenName
  # http://xmlns.com/foaf/0.1/based_near
  # http://xmlns.com/foaf/0.1/page


  # The orcid *account* should be described separately, e.g.
  # http://qa.orcid.org/0000-0002-5196-1587#orcid-id
  id="$ORCID#orcid-id"
  echo " Checking account info $id"
  grep "http://xmlns.com/foaf/0.1/account" $person | grep -q $id
  # ..which should also be described as a foaf:OnlineAccount
  grep "^<$id>" $nt | grep -q "http://xmlns.com/foaf/0.1/OnlineAccount"



  # Find out where we were redirected to
  rdf_location=`grep Location $f.headers | tail -n1 | awk '{print $2}'`
  # This should be used as the subject of metadata about the
  # foaf:PersonalProfileDocument
  echo " Checking metadata for $rdf_location"
  meta=$f.meta
  grep "^<$rdf_location>" $nt > $meta
  grep -q http://xmlns.com/foaf/0.1/PersonalProfileDocument $meta
  # should be about the ORCID
  grep http://xmlns.com/foaf/0.1/primaryTopic $meta | grep -q $ORCID
  # .and have some provenance stuff
  grep -q http://purl.org/pav/createdOn $meta
done
echo OK
