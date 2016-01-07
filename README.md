# orcid-rdf-tests
Simple tests of ORCID's RDF

To run you will need Java 1.8 and Linux. (Not tested on Mac OS, but might work).

    ./test-orcid.bash

The first time, the script will download [Apache Jena](http://jena.apache.org/) to the `jena/` subdirectories.

Alternatively you can also run using [Docker](https://www.docker.com/):

  docker build -t orcid-test 
  docker run -it orcid-test

During testing, files will be downloaded to the subdirectory `rdf/`.

The ORCID (and thus the endpoint) to test can be modified by changing the
`ORCID` variable in `test-orcid.bash`.
  
## What is tested

The tests are quite brief, but tests the main point raised in the
[ORCID telcon 2015-12-02](https://gist.github.com/stain/abaf89cf40df2823dde1).

* Retrieval of ORCID in RDF formats RDF/XML, Turtle, N-Triples and JSON-LD
* Parsing of RDF to N-Triples
* Check given `$ORCID` is described, e.g. has a `foaf:name` (it doesn't check WHICH name)
* Check a corresponding `foaf:OnlineAccount` is related to the account
* Check a `foaf:PersonalProfileDocument` is described and is the URL that was redirected to
* Check some brief provenance of the profile document (e.g. the RDF) is incluyded

## Identified issues

Current issues (2016-01-07) using http://qa.orcid.org/0000-0002-5196-1587:

* SSL certificates of https://pub.qa.orcid.org/ is not valid (thus using `--insecure`)
* `Accept: application/n-triples` (N-Triples) wrongly returns the `text/html` rendering
* `Accept: application/ld+json` (JSON-LD) fails with 406 Not Acceptable
* Wrong URL is given for the `foaf:PersonalProfileDocument` - the redirection goes to https://pub.qa.orcid.org/experimental_rdf_v1/0000-0002-5196-1587
  but the description is about non-existing http://pub.qa.orcid.org/orcid-pub-web/experimental_rdf_v1/0000-0002-5196-1587
  
