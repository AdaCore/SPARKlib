"""Common behavior of the SPARKlib test drivers.

A SPARKlib test builds, runs or proves a client of the library. What the
drivers share is how a test is enabled, how it gets the sources it works on,
and how much of the machine it is allowed to take.
"""

import os
import os.path
import shutil

from e3.testsuite.control import AdaCoreLegacyTestControlCreator, TestControl
from e3.testsuite.driver.diff import OutputRefiner

# Files that describe a test rather than belonging to the program it builds.
# They are never taken from the test named by the "sources" key, as the test
# doing the copying has its own.
CONTROL_FILES = ("test.yaml", "test.opt", "test.out", "test.py")


class SparklibControlCreator(AdaCoreLegacyTestControlCreator):
    """Decide whether a test runs, and whether it is expected to fail.

    This is the standard "test.opt" mechanism, plus the "large" key of the
    test.yaml file: a large test runs only when the "large" discriminant is
    active.
    """

    def __init__(self, system_tags, test_env):
        super().__init__(system_tags)
        self.test_env = test_env

    def create(self, driver) -> TestControl:
        if self.test_env.get("large") and "large" not in self.system_tags:
            return TestControl("large test", skip=True, xfail=False)
        return super().create(driver)


class SortLinesRefiner(OutputRefiner):
    """Sort the lines of an output.

    The tools are free to report in any order, all the more so when they run
    on several cores, so what a test compares is the set of lines.
    """

    def refine(self, output):
        return "\n".join(sorted(output.splitlines()))


class InfoFilterRefiner(OutputRefiner):
    """Drop the information messages from an output.

    An information message is not a result: it says that a call was analyzed
    in context, or that a loop was unrolled. Keeping such messages in a
    baseline is what made the old ones large, and made them change with every
    change of how gnatprove phrases them.
    """

    def refine(self, output):
        return "\n".join(line for line in output.splitlines() if ": info: " not in line)


class SparklibDriverMixin:
    """Behavior shared by the SPARKlib test drivers.

    It is mixed into the e3-testsuite driver each one builds on: a plain one
    for the execution tests, the baseline-comparing one for proof and profile
    tests.
    """

    copy_test_directory = True

    @property
    def test_control_creator(self):
        assert isinstance(self.env.discs, list)
        return SparklibControlCreator(self.env.discs, self.test_env)

    @property
    def tokens(self):
        """How many of the testsuite's parallel slots this test takes.

        A test that asks the tools for several cores has to account for them,
        or a testsuite run wide enough to keep the machine busy with cheap
        tests would multiply that number by as many expensive tests as it runs
        at once.
        """
        return 1

    def copy_sources(self):
        """Copy in the sources of the test named by the "sources" key, if any.

        This is how an execution test and a proof test share one copy of the
        program they work on: the sources live in one of the two directories,
        and the other names it. Files the copying test provides itself win, so
        that it can build the same sources with its own project file.
        """
        relpath = self.test_env.get("sources")
        if relpath is None:
            return

        source_dir = os.path.normpath(os.path.join(self.test_env["test_dir"], relpath))
        if not os.path.isdir(source_dir):
            raise RuntimeError(f"no such test to take sources from: {relpath}")

        working_dir = self.test_env["working_dir"]
        for name in sorted(os.listdir(source_dir)):
            if name in CONTROL_FILES:
                continue
            dest = os.path.join(working_dir, name)
            if os.path.exists(dest):
                continue
            source = os.path.join(source_dir, name)
            if os.path.isdir(source):
                shutil.copytree(source, dest)
            else:
                shutil.copy2(source, dest)
