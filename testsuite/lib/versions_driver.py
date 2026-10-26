"""Collect tool versions in an intentional XFAIL for the nightly reports."""

import time

from e3.testsuite.driver.diff import DiffTestDriver

from base import SparklibDriverMixin

# Keys accepted in the test.yaml of the tool-version sentinel
known_yaml_keys = {"driver", "timeout"}


class VersionsDriver(SparklibDriverMixin, DiffTestDriver):
    """Compare compiler and GNATprove versions against an empty baseline"""

    @property
    def baseline(self):
        # Nonempty output must fail through the ordinary diff machinery.
        # There is no baseline file to maintain for this intentional XFAIL.
        return (None, "", False)

    def run(self):
        start_time = time.monotonic()
        # Collect both outputs even if one command fails. This sentinel records
        # the tools in use rather than checking their behavior.
        self.shell(["gcc", "-c", "-gnatv", "always_fail.adb"], catch_error=False)
        self.output += "--\n"
        self.shell(["gnatprove", "--version"], catch_error=False)
        self.result.time = time.monotonic() - start_time
