"""Replay the whole-library proof, including the recorded Coq proofs.

The library is copied into the test's working directory in source-tree form.
Both automatic sessions and manual proofs come from the selected SPARKlib,
and any artifacts produced by replay stay in that working copy.
"""

import time

from e3.testsuite.driver.diff import DiffTestDriver, OutputRefiner, Substitute

from base import InfoFilterRefiner, SparklibDriverMixin, SortLinesRefiner
from sparklib_support import body_mode_switch, resolve_sparklib_location
from sparklib_tree import source_mode

# Keys accepted in the test.yaml of a whole-library replay test
known_yaml_keys = {"driver", "jobs", "timeout"}


class CoqWarningFilterRefiner(OutputRefiner):
    """Drop the Coq grammar-extension warning suppressed by the legacy test"""

    def refine(self, output):
        return "\n".join(
            line for line in output.splitlines() if "Grammar extension" not in line
        )


class LibraryReplayDriver(SparklibDriverMixin, DiffTestDriver):
    """Replay every library unit, retaining warnings and unproved checks"""

    @property
    def jobs(self):
        """How many cores gnatprove may use for this test"""
        return self.test_env.get("jobs", 1)

    @property
    def tokens(self):
        return self.jobs

    @property
    def default_process_timeout(self):
        return self.test_env.get("timeout", 780)

    @property
    def output_refiners(self):
        return super().output_refiners + [
            Substitute(self.test_env["working_dir"], "<working_dir>"),
            InfoFilterRefiner(),
            CoqWarningFilterRefiner(),
            SortLinesRefiner(),
        ]

    def gnatprove_command(self):
        """Replay the library and its manual proofs with the legacy budgets"""
        # The project imports the copied library, which must be analyzed too.
        # In particular, do not use the client driver's --no-subprojects.
        return [
            "gnatprove",
            "-P",
            "test.gpr",
            "-XSPARKLIB_INSTALLED=False",
            *body_mode_switch(True),
            "-k",
            "--quiet",
            "--debug-disable-prover-feedback",
            "--output=oneline",
            "--report=fail",
            "--warnings=continue",
            "--assumptions",
            "--mode=all",
            f"-j{self.jobs}",
            "--memlimit=2000",
            "--steps=200",
            "--timeout=120",
            "--replay",
            "--prover=coq,cvc5,z3,altergo,colibri",
            "--counterexamples=off",
            "--check-counterexamples=on",
            "--debug-no-cache-output",
        ]

    def run(self):
        start_time = time.monotonic()
        _, root = resolve_sparklib_location()
        source_mode(self.test_env["working_dir"], from_tree=root)
        self.shell(self.gnatprove_command())
        self.result.time = time.monotonic() - start_time
