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


# Latest version from http://jena.apache.org/download/index.cgi?Preferred=http%3A%2F%2Fwww.eu.apache.org%2Fdist%2F
JENA_VERSION=3.0.1


# Checking that required tools are installed
java -version 2>&1 | grep -q 1.8 && echo java 1.8
curl --version >/dev/null && echo curl
sha1sum --version >/dev/null && echo sha1sum
echo Hello | grep -q Hello && echo grep
echo Hello there | awk '{print $2}' | grep -q there && echo awk

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
riot --version >/dev/null && echo riot
echo Tools OK
