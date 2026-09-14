"""Driver for the SPARKlib execution tests.

An execution test builds a client of SPARKlib against the body-mode library,
with assertions enabled, and runs it. The library contracts are then checked
at run time, so the contract of the test is simply that the build and the
program succeed, and that the program prints nothing.

The proof of these clients is a separate test; see the proof driver.
"""

import os.path

from e3.testsuite.driver.classic import ClassicTestDriver

from base import SparklibDriverMixin
from sparklib_support import (
    body_mode_switch,
    coverage_mode,
    create_sparklib,
    sparklib_project_dir,
)

# Keys accepted in the test.yaml of an execution test
known_yaml_keys = {"driver", "large", "runs", "timeout"}

# What to build and run when the test does not say otherwise
default_runs = [{"project": "test.gpr", "binary": "obj/test"}]


class ExecTestDriver(SparklibDriverMixin, ClassicTestDriver):
    """Build and run a SPARKlib client program, expecting silent success"""

    @property
    def runs(self):
        """The (project, binary) pairs to build and run for this test"""
        return self.test_env.get("runs", default_runs)

    def run(self):
        cwd = self.test_env["working_dir"]
        create_sparklib(cwd)
        coverage = coverage_mode()

        for entry in self.runs:
            project = entry["project"]
            binary = entry["binary"]

            build_opt = [
                "-aP",
                sparklib_project_dir(),
                "-P",
                project,
            ] + body_mode_switch(True)
            if coverage:
                self.shell(
                    ["gnatcov", "instrument", "-P", project, "--level=stmt"]
                    + body_mode_switch(True),
                    analyze_output=False,
                )
                build_opt += [
                    "--src-subdirs=gnatcov-instr",
                    "--implicit-with=gnatcov_rts.gpr",
                ]

            # Only what the test program prints is analyzed. Build diagnostics
            # go to the test log, and a failed build is caught by its exit
            # status.
            self.shell(["gprbuild", "-q"] + build_opt, analyze_output=False)
            self.shell([os.path.join(cwd, binary)])

    def compute_failures(self):
        # A non-zero exit status has already aborted the test at this point, so
        # the only thing left to check is that the test program printed
        # nothing.
        if str(self.output).strip():
            return ["unexpected output"]
        return []
