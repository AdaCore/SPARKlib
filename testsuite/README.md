# SPARKlib testsuite

`run-tests` is the entry point for the SPARKlib tests, which live in
`../tests`. It is an [e3-testsuite](https://github.com/AdaCore/e3-testsuite)
driver, so the usual options apply:

```sh
./run-tests                     # run everything
./run-tests 665__c_strings_test # run one test
./run-tests -j8 --disc=large
./run-tests <test> -d temp      # keep the working directory for inspection
```

## Which SPARKlib is tested

By default the tests use the SPARKlib of the SPARK installation that provides
`gnatprove`. To test the sources of a checkout instead:

```sh
./run-tests --sparklib-source          # this checkout
./run-tests --sparklib-source=<dir>    # another one
```

This builds an installed-tree layout out of the sources with
`scripts/sparklib_tree.py` and exports `SPARKLIB_PROJECT_PATH`, which is the
same mechanism the CI jobs use.

## Migration in progress

The tests are being migrated from the gnatprove testsuite to this one, one
test at a time. A migrated test carries a `driver` key in its `test.yaml` and
is run by a driver of this testsuite; every other test is still run by the
gnatprove testsuite's drivers, which this entry point loads from the spark2014
sources. They are found next to this testsuite (`../lib/python`, where nightly
runs put them) or in the spark2014 checkout containing this one; otherwise set
`SPARK2014_TESTSUITE_LIB`.

Each test is claimed by exactly one of the two finders, so a test runs once
whether or not it has been migrated. When the last test has moved, the second
finder and the spark2014 dependency go away.
