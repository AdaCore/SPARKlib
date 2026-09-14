"""Support code shared by the SPARKlib testsuite scripts.

Deciding which SPARKlib is tested is testsuite policy, and lives here. The
shape of the trees this looks for is not: that is SPARKlib product mechanics,
owned by the sparklib_tree script and shared with the CI jobs.
"""

import os
import os.path
import sys
from pathlib import Path
from shutil import which

sys.path.append(
    os.path.join(
        os.path.dirname(os.path.abspath(__file__)), os.pardir, os.pardir, "scripts"
    )
)

from sparklib_tree import (  # noqa: E402
    ANCHOR_PROJECT,
    check_installed_tree,
    test_project,
)

# Environment variable naming the SPARKlib to test. It is read by the drivers
# of both testsuites, so setting it also directs the tests that have not been
# migrated yet.
sparklib_project_path_env = "SPARKLIB_PROJECT_PATH"

# External of the SPARKlib projects selecting body mode, the configuration in
# which the library bodies are analysed instead of being hidden from analysis.
sparklib_body_mode_var = "SPARKLIB_BODY_MODE"


def spark_install_path():
    """Return the location of the SPARK install providing gnatprove"""
    exec_loc = which("gnatprove")
    if exec_loc is None:
        raise RuntimeError("cannot find gnatprove on the PATH")
    return os.path.dirname(os.path.dirname(exec_loc))


def resolve_sparklib_location(path=None):
    """Resolve the SPARKlib to test, from an override path or the install.

    Returns a tuple `(project_dir, root_dir)`, where `project_dir` holds the
    SPARKlib projects and `root_dir` is the root of the installed tree they
    belong to. Both shapes an override may take are accepted: the root of an
    installed tree, or the project directory inside it.
    """
    if path is None:
        path = os.environ.get(sparklib_project_path_env)

    if path is None:
        root = Path(spark_install_path())
    else:
        candidate = Path(path).resolve()
        # A project directory names the tree it belongs to two levels up.
        if (candidate / ANCHOR_PROJECT).is_file():
            root = candidate.parent.parent
        else:
            root = candidate

    return str(check_installed_tree(root)), str(root)


def sparklib_project_dir():
    """Return the directory holding the SPARKlib projects.

    Callers add it to the project path with "-aP" on the command line rather
    than mutating GPR_PROJECT_PATH, which concurrent tests share.
    """
    project_dir, _ = resolve_sparklib_location()
    return project_dir


def body_mode_switch(enabled):
    """Return the switches selecting the SPARKlib body mode, if enabled.

    Body mode is the configuration in which the library bodies, and the private
    parts they rely on, are analysed instead of being hidden from analysis. It
    is an external of the SPARKlib projects, passed on the command line rather
    than through the environment, which concurrent tests share.
    """
    return [f"-X{sparklib_body_mode_var}=On"] if enabled else []


def create_sparklib(cwd):
    """Write the sparklib.gpr a test builds the library with, in `cwd`"""
    test_project(cwd)


def coverage_mode():
    """Whether the testsuite runs with coverage instrumentation enabled"""
    return os.environ.get("coverage") == "true"
