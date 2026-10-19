"""Driver for the SPARKlib proof tests.

A proof test runs gnatprove on a SPARKlib client or component proof and
compares the reported warnings and failures against a baseline. The tool
reports failures only (`--report=fail`), omitting messages about proved
checks. Those messages made the old baselines large and sensitive to changes
in how gnatprove reports successful checks.

A test that proves entirely has no baseline file at all; its expected output
is empty.
"""

import os.path

from e3.testsuite.driver.diff import DiffTestDriver, Substitute

from base import InfoFilterRefiner, SparklibDriverMixin, SortLinesRefiner
from sparklib_support import (
    body_mode_switch,
    create_sparklib,
    sparklib_project_dir,
)

# Keys accepted in the test.yaml of a proof test
known_yaml_keys = {
    "body_mode",
    "driver",
    "jobs",
    "large",
    "level",
    "project",
    "replay",
    "sources",
    "steps",
    "switches",
    "timeout",
}

# The provers to try, and how much each check may consume. These are the
# values the tests were tuned with, and the limit is deliberately expressed in
# steps rather than in time, so that a result does not depend on the machine.
default_provers = ["cvc5", "altergo", "z3", "colibri"]
default_steps = 200
default_vc_timeout = 120
default_memlimit = 2000


class ProofTestDriver(SparklibDriverMixin, DiffTestDriver):
    """Prove a SPARKlib client or component and compare the reported failures"""

    @property
    def jobs(self):
        """How many cores gnatprove may use for this test"""
        return self.test_env.get("jobs", 1)

    @property
    def tokens(self):
        return self.jobs

    @property
    def output_refiners(self):
        return super().output_refiners + [
            Substitute(self.test_env["working_dir"], "<working_dir>"),
            InfoFilterRefiner(),
            SortLinesRefiner(),
        ]

    @property
    def baseline(self):
        # A client that proves entirely files no baseline, rather than an
        # empty file that would look like an oversight.
        filename, is_regexp = self.baseline_file
        filename = self.test_dir(filename)
        if not os.path.isfile(filename):
            return (filename, "", is_regexp)
        return super().baseline

    def gnatprove_command(self):
        """Build the gnatprove invocation for this test"""
        project = self.test_env.get("project", "test.gpr")
        body_mode = self.test_env.get("body_mode", True)

        cmd = ["gnatprove", "-P", project]
        # SPARKlib itself is proved by its own test, not again by each client.
        cmd += ["--no-subprojects", "-aP", sparklib_project_dir()]
        cmd += body_mode_switch(body_mode)
        # Keep going after an error, so that one failure does not hide the
        # others, and report failures only.
        cmd += [
            "-k",
            "--quiet",
            "--output=oneline",
            "--report=fail",
            "--warnings=continue",
            "--mode=all",
            f"-j{self.jobs}",
            f"--memlimit={default_memlimit}",
        ]

        if self.test_env.get("replay"):
            cmd += ["--replay"]

        level = self.test_env.get("level")
        if level is None:
            steps = self.test_env.get("steps", default_steps)
            cmd += [f"--steps={steps}", f"--timeout={default_vc_timeout}"]
        else:
            cmd += [f"--level={level}"]

        cmd += ["--prover=" + ",".join(default_provers)]
        cmd += self.test_env.get("switches", [])
        return cmd

    def run(self):
        create_sparklib(self.test_env["working_dir"])
        self.copy_sources()
        self.shell(self.gnatprove_command())
