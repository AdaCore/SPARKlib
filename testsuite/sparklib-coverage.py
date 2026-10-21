#! /usr/bin/env python

import os.path
import subprocess
import shutil
import sys
import tempfile

testsuite_dir = os.path.dirname(os.path.abspath(__file__))
sparklib_dir = os.path.dirname(testsuite_dir)
sys.path.append(os.path.join(testsuite_dir, "lib"))

import sparklib_support  # noqa: E402


def run_command(args):
    subprocess.run(args, check=True)


def setup_coverage():
    tmpdir = tempfile.mkdtemp(prefix="sparkcov")
    run_command(["gnatcov", "setup", f"--prefix={tmpdir}"])
    project_path = os.path.join(tmpdir, "share", "gpr")
    os.environ["GPR_PROJECT_PATH"] = (
        os.environ.get("GPR_PROJECT_PATH", "") + f":{project_path}"
    ).lstrip(":")
    return tmpdir


def run_testsuite(tempdir):
    """Run the tests of the coverage manifest, instrumented.

    The tests build and run clients of SPARKlib, so their traces say which
    parts of the library they exercise. Which SPARKlib that is comes from the
    environment, as the report below is computed against the same one.
    """
    manifest = os.path.join(testsuite_dir, os.pardir, "tests", "coverage.manifest")
    subprocess.run(
        [
            os.path.join(testsuite_dir, "run-tests"),
            f"--testlist={manifest}",
            "--coverage",
            "--disc=large",
            "-d",
            tempdir,
        ],
        check=True,
    )


def produce_report(covlibdir, covtempdir):
    shutil.rmtree(covlibdir)
    _, root_dir = sparklib_support.resolve_sparklib_location()
    os.environ["SPARKLIB_PROJECT_PATH"] = root_dir
    os.environ["COVERAGE_TRACES_DIR"] = covtempdir
    run_command(["make", "-C", sparklib_dir, "coverage-report"])
    print("Find the coverage report in sparklib-report/html")


def main():
    covlibdir = setup_coverage()
    covtempdir = os.path.abspath("covtemp")
    try:
        os.rmdir(covtempdir)
    except OSError:
        pass
    run_testsuite(covtempdir)
    produce_report(covlibdir, covtempdir)


if __name__ == "__main__":
    main()
