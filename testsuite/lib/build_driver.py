"""Driver for the SPARKlib build and assertion-profile tests.

Each profile runs a lightweight analysis, builds, and executes its program.
Together these phases check what the profile's assertion policy exposes to
analysis and execution. The baseline records both diagnostics and intentional
program output, including known unproved checks.
"""

import re
import time

from e3.testsuite.driver.diff import DiffTestDriver, Substitute

from base import SparklibDriverMixin
from sparklib_support import sparklib_project_dir

# Keys accepted in the test.yaml of a build/profile test
known_yaml_keys = {"binary", "driver", "jobs", "large", "project", "timeout"}


def diagnostic_key(line):
    """Sort diagnostics by filename, then numeric line and column"""
    match = re.match(r"(.*?):(\d+):(\d+):(.*)", line)
    if match:
        filename, line_number, column, message = match.groups()
        return filename, int(line_number), int(column), message
    return "zzzzz", 0, 0, line


class BuildTestDriver(SparklibDriverMixin, DiffTestDriver):
    """Analyze, build, and run one assertion profile, retaining its baseline"""

    # The legacy driver ignored whitespace, including the extra newline from
    # printing the program output. Keep that comparison policy initially.
    diff_ignore_white_chars = True

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
        ]

    def analysis_command(self):
        """Preserve the legacy do_flow analysis with one CVC5 step"""
        return [
            "gnatprove",
            "-P",
            self.test_env.get("project", "test.gpr"),
            "-aP",
            sparklib_project_dir(),
            "-k",
            "--info",
            "--debug-disable-prover-feedback",
            "--output=oneline",
            "--warnings=continue",
            "--assumptions",
            "--quiet",
            "--steps=1",
            "--memlimit=2000",
            "--timeout=120",
            "--mode=all",
            f"-j{self.jobs}",
            "--prover=cvc5",
            "--counterexamples=off",
            "--check-counterexamples=on",
            "--debug-no-cache-output",
            "--report=provers",
        ]

    def run(self):
        start_time = time.monotonic()
        # Keep the test's own sparklib.gpr and configuration pragmas. Neither
        # generating a project nor forcing body mode preserves these profiles.
        analysis = self.shell(self.analysis_command(), analyze_output=False)
        # The old analysis helper hid informational messages from SPARKlib
        # units, but retained client diagnostics and library warnings/failures.
        lines = [
            line
            for line in analysis.out.splitlines()
            if not re.match(r"spark-.*\.ad[bs]:\d+:\d+: info: .*", line)
        ]
        self.output += "".join(
            line + "\n" for line in sorted(lines, key=diagnostic_key)
        )

        build = self.shell(
            [
                "gprbuild",
                "-q",
                "-j1",
                "-aP",
                sparklib_project_dir(),
                "-P",
                self.test_env.get("project", "test.gpr"),
            ],
            analyze_output=False,
        )
        self.output += "".join(
            line + "\n" for line in sorted(build.out.splitlines(), key=diagnostic_key)
        )
        # Program output is meaningful and keeps its original order. shell
        # checks all three exit statuses independently of baseline matching.
        self.shell([self.working_dir(self.test_env.get("binary", "main"))])
        self.result.time = time.monotonic() - start_time
