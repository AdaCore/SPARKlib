# SPARKlib testsuite

`run-tests` is the entry point for the SPARKlib tests, which live in
`../tests`. It is an [e3-testsuite](https://github.com/AdaCore/e3-testsuite)
driver, so the usual options apply:

```sh
./run-tests                     # run everything
./run-tests coverage_test/c_strings # run one test
./run-tests coverage_proof/functional_trees
./run-tests library_proof/formal_vectors
./run-tests --disc=coq -j4 library_proof/main
./run-tests --disc=large build_test # run the assertion profiles
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
names a driver. Coverage clients live in
`../tests/coverage_test/<name>`, with their proofs in
`../tests/coverage_proof/<name>`. Component proofs of library implementations,
models, and lemmas live in `../tests/library_proof/<name>` and use the same
`proof` driver. Select them using paths relative to
`../tests`, such as `coverage_test/functional_trees`, also in `--testlist`
files. Results use e3-testsuite's canonical names, with `/` replaced by `__`
(for example, `coverage_test__functional_trees`); `--testlist` also accepts
these names.
Build and assertion-profile tests live in `../tests/build_test/<profile>`.
Baselines are kept to a minimum: an execution test has none,
and a proof test files only what gnatprove reports as a failure, never the
messages about checks that are proved. Build/profile tests retain their
existing diagnostic and program-output baselines initially.

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
15 intended unproved checks in `library_proof/higher_order_fold`.

```yaml
driver: proof
sources: ../../coverage_test/formal_vectors # relative to this test directory
jobs: 4                # cores for gnatprove, and slots taken in the run
body_mode: false       # use normal library visibility (default: true)
config_dir: config # hide the higher-order reachability body
level: 2               # or "steps:", which defaults to 200
replay: session        # replay the recorded sessions in proof/sessions
session_opt:           # options for regenerating sessions only
  level: 3             # level, steps, or switches; defaults to the test settings
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

A proof test can set `config_dir` to a directory containing its own
`sparklib_config.ads`, relative to the test working directory. The driver passes
its absolute path through `-XSPARKLIB_CONFIG_DIR`. Without this key, the supplied
configuration follows `body_mode`. The doubly-linked list implementation proof
uses a custom configuration to expose the list implementation while keeping
reachability abstract.

### `driver: library-replay`

Replays the whole-library proof, including Coq, in
`library_proof/main`. This test requires the `coq` discriminant.
This driver works with the library in source mode, copies the sessions
and replays proof, including the Coq proofs. The library is run with
body mode enabled.

```yaml
driver: library-replay
jobs: 4                # cores for gnatprove, and slots taken in the run
timeout: 780           # seconds per process; default
```

The driver only replays existing proofs. It is excluded from `--update-sessions`
and `update-session-test`: its sessions need to be replayed with the
`generate_sessions.py` script.

### Updating recorded sessions

Use `update-session-test` for tests with `driver: proof` and
`replay: session`:

```sh
./update-session-test library_proof/higher_order_fold --sparklib-source
./update-session-test library_proof__higher_order_fold --sparklib-source -j8
./update-session-test library_proof/higher_order_fold --sparklib-source -j0
```

It accepts one or more test paths or canonical names, enables large tests,
and uses the same library selection as `run-tests` (the installed SPARKlib
unless `--sparklib-source` is given). Sessions are generated afresh in the
testsuite's working copy using the test settings plus `session_opt`. This
mapping can override `level`, `steps`, and `switches`; `switches` replaces the
test's list. Regeneration uses all available cores by default (`-j0`), or
the number given by `-j N`. Selected tests run one at a time, each using that
worker budget. The replay keeps the test's normal `jobs` setting, and both
invocations retain its process timeout.

The script uses SPARK 2014's `clean_sessions.py` to remove unsuccessful and
duplicate proof attempts and unused prover declarations. It imports this module
only for session updates: from the enclosing SPARK 2014 checkout, from
`../lib/python` in a nightly installation, or from `SPARK2014_TESTSUITE_LIB`
when explicitly set. Ordinary test runs do not need SPARK 2014's Python support.
For session updates in a standalone SPARKlib checkout:

```sh
export SPARK2014_TESTSUITE_LIB=/path/to/spark2014/testsuite/gnatprove/lib/python
```

Sessions are cleaned before replay and again before copying them back. Shape
files and `*.bak` backups are excluded from the recorded sessions. The script
replays the fresh sessions using the normal test settings. After both
gnatprove invocations complete successfully, it replaces the test's recorded
`proof/sessions`. The replay output is compared with the existing baseline;
an output difference makes the command fail but leaves the regenerated
sessions available for inspection. Baselines are never rewritten. Review the
session changes with `git diff` before committing them.

This supports automatic Why3 sessions only. Manifest replay and manual proofs
are outside its scope.

### `driver: build`

Runs analysis, build, and execution together for one assertion profile. The
analysis preserves the legacy `do_flow()` settings: mode `all`, CVC5 with one
proof step, and informational messages. The driver retains the test's own
`sparklib.gpr` or `sparklib_light.gpr`, project switches, and configuration
pragmas, which select the runtime and assertion policy being tested. It does
not force body mode or enable assertions on behalf of the project.

Each entry declares its analysis workers and scheduler slots with `jobs`,
which defaults to one. Compilation uses one worker. All three processes must
succeed, and their combined output must match `test.out`. Analysis and build
diagnostics are sorted separately; program output keeps its original order.
Known unproved checks and intentional output
such as `SPARKlib_Logic:ON` are part of the baseline.

```yaml
driver: build
jobs: 4                # cores for gnatprove, and slots taken in the run
large: true
project: test.gpr       # default
binary: main            # relative to the working directory; default
timeout: 780            # seconds per process; default
```

The six full-runtime profiles live under `build_test/full*` and the four
light-runtime profiles under `build_test/light*`. All use four analysis workers
each. The full-runtime profiles require `--disc=large`; the light-runtime
profiles run by default. The light runtime's last-chance handler prints the
expected exception message and exits with status zero, so its output is checked
against the baseline along with the analysis and build diagnostics. These
profile tests are outside the runtime coverage manifest.

### `driver: versions`

The `Z999-999__sparklib_always_fail` sentinel is the only test that
uses this driver, and has two purposes:
- It protects against test driver mistakes that would spuriously always
  pass
- It contains tool versions in its output.

The test is marked XFAIL.

## Coverage

`sparklib-coverage.py` runs the tests listed in `../tests/coverage.manifest`
with instrumentation and produces an HTML report of the SPARKlib code they
exercise, in `sparklib-report`. It needs `gnatcov` on the PATH, and reports on
the same SPARKlib the tests ran against, so point it with
`SPARKLIB_PROJECT_PATH` as the CI job does. The report is generated by the
`coverage-report` Makefile target; direct calls also need `COVERAGE_TRACES_DIR`
pointing at the retained test workspaces.
