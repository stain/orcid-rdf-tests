FROM java:8
RUN mkdir /orcid-test
WORKDIR /orcid-test
ADD . /orcid-test

RUN chmod 755 *.bash
RUN ./check-tools.bash
CMD ["/orcid-test/test-orcid.bash"]
