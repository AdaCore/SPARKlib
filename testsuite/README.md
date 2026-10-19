# SPARKlib testsuite

`run-tests` is the entry point for the SPARKlib tests, which live in
`../tests`. It is an [e3-testsuite](https://github.com/AdaCore/e3-testsuite)
driver, so the usual options apply:

```sh
./run-tests                     # run everything
./run-tests coverage_test/c_strings # run one test
./run-tests coverage_proof/functional_trees
./run-tests library_proof/formal_vectors
./run-tests coverage_test       # run the execution group
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

## Tests of this testsuite

A test of this testsuite is a directory under `../tests` whose `test.yaml`
names a driver. Migrated coverage clients live in
`../tests/coverage_test/<name>`, with their proofs in
`../tests/coverage_proof/<name>`. Component proofs of library implementations,
models, and lemmas live in `../tests/library_proof/<name>` and use the same
`proof` driver. Select them using paths relative to
`../tests`, such as `coverage_test/functional_trees`, also in `--testlist`
files. Results use e3-testsuite's canonical names, with `/` replaced by `__`
(for example, `coverage_test__functional_trees`); `--testlist` also accepts
these names. Unmigrated tests keep their existing names.
Baselines are kept to a minimum: an execution test has none,
and a proof test files only what gnatprove reports as a failure, never the
messages about checks that are proved.

### `driver: exec`

Builds a client of SPARKlib against the body-mode library, with assertions
enabled, and runs it. The library contracts are checked at run time, so the
test passes when the build and the program succeed and the program prints
nothing.

```yaml
driver: exec
large: true            # run only with the "large" discriminant
timeout: 1500          # seconds, for each process the test runs
runs:                  # what to build and run; the default is the entry below
  - project: test.gpr
    binary: obj/test
```

### `driver: proof`

Runs gnatprove on a client or component proof of SPARKlib and compares what it
reports against `test.out`. With `--report=fail`, the baseline contains warnings
and unproved checks. A test that proves entirely files no baseline at all.
Lines are compared as a set, since
proving on several cores reports in no particular order, and `--rewrite`
refreshes a baseline from a run.

Tests in `library_proof` keep their proof harnesses and recorded sessions in
their own directory. Generic instantiations make the library bodies part of
the analysis, including implementation generics exposed by test-only children.
Their baselines record known unproved obligations explicitly, including the
15 intended unproved checks in `library_proof/higher_order_fold`. The
whole-library replay, including Coq, remains a legacy test.

```yaml
driver: proof
sources: ../../coverage_test/formal_vectors # relative to this test directory
jobs: 4                # cores for gnatprove, and slots taken in the run
body_mode: false       # use normal library visibility (default: true)
level: 2               # or "steps:", which defaults to 200
replay: session        # replay the recorded sessions in proof/sessions
switches: ["--no-inlining"]
project: test.gpr      # the project to prove, if not test.gpr
large: true
timeout: 3000
```

The execution and the proof of one client are two tests so that each gets its
own timeout, its own result, and its own share of the machine; `sources` is
what keeps the program itself in a single place. A proof test declares how
many cores it takes with `jobs`, and the run schedules it against that weight,
so that `-j16` means sixteen cores rather than sixteen tests.

## Coverage

`sparklib-coverage.py` runs the tests listed in `../tests/coverage.manifest`
with instrumentation and produces an HTML report of the SPARKlib code they
exercise, in `sparklib-report`. It needs `gnatcov` on the PATH, and reports on
the same SPARKlib the tests ran against, so point it with
`SPARKLIB_PROJECT_PATH` as the CI job does.

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
