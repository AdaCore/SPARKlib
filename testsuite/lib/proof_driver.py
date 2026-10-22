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
from pathlib import Path
import shutil
import tempfile

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
    "config_dir",
    "replay",
    "session_opt",
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
        if self.env.update_sessions:
            return max(self.jobs, self.env.session_jobs)
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

    def gnatprove_command(self, generate_session=False):
        """Build the gnatprove invocation for this test"""
        config = dict(self.test_env)
        if generate_session:
            options = config.get("session_opt", {})
            unknown = set(options) - {"level", "steps", "switches"}
            if unknown:
                raise ValueError(
                    f"unknown session_opt keys: {', '.join(sorted(unknown))}"
                )
            config.update(options)
            if "steps" in options and "level" not in options:
                config.pop("level", None)
        project = config.get("project", "test.gpr")
        body_mode = config.get("body_mode", True)
        jobs = self.env.session_jobs if generate_session else self.jobs

        cmd = ["gnatprove", "-P", project]
        # SPARKlib itself is proved by its own test, not again by each client.
        cmd += ["--no-subprojects", "-aP", sparklib_project_dir()]
        cmd += body_mode_switch(body_mode)
        config_dir = self.test_env.get("config_dir")
        if config_dir is not None:
            config_dir = os.path.abspath(self.working_dir(config_dir))
            cmd += [f"-XSPARKLIB_CONFIG_DIR={config_dir}"]
        # Keep going after an error, so that one failure does not hide the
        # others, and report failures only.
        cmd += [
            "-k",
            "--quiet",
            "--output=oneline",
            "--report=fail",
            "--warnings=continue",
            "--mode=all",
            f"-j{jobs}",
            f"--memlimit={default_memlimit}",
        ]

        if config.get("replay") and not generate_session:
            cmd += ["--replay"]

        level = config.get("level")
        if level is None:
            steps = config.get("steps", default_steps)
            cmd += [f"--steps={steps}", f"--timeout={default_vc_timeout}"]
        else:
            cmd += [f"--level={level}"]

        cmd += ["--prover=" + ",".join(default_provers)]
        cmd += config.get("switches", [])
        return cmd

    def regenerate_sessions(self):
        """Generate fresh automatic sessions in the test's working copy"""
        if self.test_env.get("replay") != "session":
            raise ValueError("session updates require replay: session")

        from clean_sessions import clean_session_file

        sessions = Path(self.test_env["working_dir"]) / "proof" / "sessions"
        if sessions.exists():
            shutil.rmtree(sessions)
        self.shell(self.gnatprove_command(generate_session=True), analyze_output=False)
        session_files = sorted(sessions.rglob("why3session.xml"))
        if not session_files:
            raise RuntimeError("gnatprove generated no sessions in proof/sessions")
        for path in session_files:
            clean_session_file(str(path))
        for path in sessions.rglob("why3shapes*"):
            path.unlink()

    def save_sessions(self):
        """Replace recorded sessions after both prover invocations complete"""
        from clean_sessions import clean_session_file

        sessions = Path(self.test_env["working_dir"]) / "proof" / "sessions"
        # Replay can add proof attempts to the freshly generated sessions.
        for path in sorted(sessions.rglob("why3session.xml")):
            clean_session_file(str(path))
        target = Path(self.test_env["test_dir"]) / "proof" / "sessions"
        target.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=target.parent) as staging:
            staging = Path(staging)
            shutil.copytree(
                sessions,
                staging / "new",
                ignore=shutil.ignore_patterns("why3shapes*", "*.bak"),
            )
            had_sessions = target.exists()
            if had_sessions:
                target.rename(staging / "old")
            try:
                (staging / "new").rename(target)
            except OSError:
                if had_sessions:
                    (staging / "old").rename(target)
                raise

    def run(self):
        create_sparklib(self.test_env["working_dir"])
        self.copy_sources()
        if self.env.update_sessions:
            self.regenerate_sessions()
        self.shell(self.gnatprove_command())
        if self.env.update_sessions:
            self.save_sessions()
