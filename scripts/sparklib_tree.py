#!/usr/bin/env python3

"""Build and inspect SPARKlib trees.

This helper script establishes an "installed-tree" layout for SPARKlib,
including possible preprocessing. It can be called directly or used as a
library.

The three shapes are:

  source tree      the SPARKlib repository itself: project files at the root,
                   sources in "src", Coq material in "proof". Used with
                   SPARKLIB_INSTALLED=False.

  installed tree   what a SPARK install exposes:
                     <root>/lib/gnat/{*.gpr,*.gpr.templ,proof}
                     <root>/include/spark/{*.ad?,full,light}
                   Used with SPARKLIB_INSTALLED=True, which is the default.

  body-mode tree   an installed tree whose sources have been preprocessed to
                   enable SPARK_Mode on the library bodies, and whose "spark.ads"
                   has been replaced by the variant suitable for execution.

Run with --help for the list of subcommands.
"""

import argparse
import os
import re
import shutil
import sys
import tempfile
from pathlib import Path

# The name of the project file that identifies a directory as the one holding
# the SPARKlib projects, in any of the three shapes.
ANCHOR_PROJECT = "sparklib_internal.gpr"

# Location of the SPARKlib sources inside an installed tree, relative to its
# root. Kept as a constant because several transformations need to name it.
INSTALLED_SOURCE_DIR = os.path.join("include", "spark")

# Location of the SPARKlib project files inside an installed tree, relative to
# its root.
INSTALLED_PROJECT_DIR = os.path.join("lib", "gnat")

# Subdirectories of the sources that hold the variant-specific units.
SOURCE_VARIANTS = ("full", "light")

# The source file that replaces "spark.ads" in every variant when building a
# body-mode tree.
EXEC_UNIT = "spark__exec.ads"


def source_root(path=None):
    """Return the root of the SPARKlib source tree.

    Defaults to the repository containing this script, which is the common
    case: the script is invoked from a SPARKlib checkout to act on that
    checkout.
    """
    if path is not None:
        return Path(path).resolve()
    return Path(__file__).resolve().parent.parent


def check_source_tree(root):
    """Raise unless `root` looks like a SPARKlib source tree"""
    if not (root / ANCHOR_PROJECT).is_file():
        raise RuntimeError(f"Not a SPARKlib source tree (no {ANCHOR_PROJECT}): {root}")
    if not (root / "src").is_dir():
        raise RuntimeError(f"Not a SPARKlib source tree (no src): {root}")


def check_installed_tree(root):
    """Raise unless `root` looks like a SPARKlib installed tree.

    This is the layout contract that consumers rely on; keeping it in one place
    means a change to the layout is a change to this file.
    """
    root = Path(root)
    project_dir = root / INSTALLED_PROJECT_DIR
    if not (project_dir / ANCHOR_PROJECT).is_file():
        raise RuntimeError(
            f"SPARKlib installed-tree layout expected, but {project_dir} does "
            f"not contain {ANCHOR_PROJECT}"
        )
    if not (root / INSTALLED_SOURCE_DIR).is_dir():
        raise RuntimeError(
            f"SPARKlib installed-tree layout expected, but {root} does not "
            f"contain {INSTALLED_SOURCE_DIR}"
        )
    return project_dir


def remove_path(path):
    """Remove `path`, whatever it is, if it exists.

    A symlink is removed as a link; it is never followed, so that a tree of
    links into a checkout can be discarded without touching the checkout.
    """
    path = Path(path)
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.is_dir():
        shutil.rmtree(str(path))


def check_disjoint(src, dst):
    """Raise unless `src` and `dst` are outside one another.

    Transfers and tree builds start by removing their destination, so an
    overlap between the two would destroy the very thing being transferred.

    A destination that is itself a link is compared as the link, not as what
    it points at, mirroring the removal: rebuilding a tree of links into a
    checkout in copy mode is the normal way to switch modes, not an overlap.
    """
    src = Path(src).resolve()
    dst = Path(dst)
    dst = dst.parent.resolve() / dst.name
    if dst == src or dst in src.parents or src in dst.parents:
        raise RuntimeError(f"Refusing to use {dst} for {src}: the two overlap")


def check_removable(target, root):
    """Raise if removing `target` would take the source tree `root` with it.

    A destination inside the checkout is a normal arrangement, and the one CI
    uses; a destination that holds the checkout is not, since the installation
    subtrees are wiped before they are populated.
    """
    root = Path(root).resolve()
    target = Path(target)
    target = target.parent.resolve() / target.name
    if target == root or target in root.parents:
        raise RuntimeError(
            f"Refusing to build in {target}: it holds the source tree {root}"
        )


def transfer(src, dst, link):
    """Copy `src` to `dst`, or symlink it when `link` is set.

    An existing destination is replaced rather than merged into, so that a
    tree is exactly what its source says it is. In particular, building over
    a previous install drops the artifacts that a Coq run leaves next to the
    proof files, and the generated files of context files that have since
    been removed.
    """
    src = Path(src)
    dst = Path(dst)
    check_disjoint(src, dst)
    dst.parent.mkdir(parents=True, exist_ok=True)
    remove_path(dst)
    if link:
        dst.symlink_to(src)
    elif src.is_dir():
        shutil.copytree(str(src), str(dst))
    else:
        shutil.copy2(str(src), str(dst))


def install_tree(dest, source=None, link=False):
    """Materialize an installed tree under `dest`, and return its project dir"""
    root = source_root(source)
    check_source_tree(root)
    dest = Path(dest).resolve()

    project_dir = dest / INSTALLED_PROJECT_DIR
    src_dir = dest / INSTALLED_SOURCE_DIR

    # The subtrees below are wiped before being populated. Make sure that
    # wiping them can reach neither the source tree itself nor the directories
    # about to be read from it. A destination inside the checkout is a normal
    # arrangement, and the one CI uses; a destination on top of the sources is
    # not.
    for target in (project_dir, src_dir):
        check_removable(target, root)
        for origin in (root / "src", root / "proof"):
            check_disjoint(origin, target)

    # Start from empty installation subtrees, so that the result holds nothing
    # but what the source currently provides. This also makes building over a
    # tree of links safe: were the previous links left in place, populating the
    # destination would write through them into the checkout they point to.
    remove_path(project_dir)
    remove_path(src_dir)
    project_dir.mkdir(parents=True, exist_ok=True)

    if link:
        # Link the whole source directory in one go; it contains exactly the
        # units and the variant subdirectories, so the result is the same tree.
        transfer(root / "src", src_dir, link=True)
    else:
        src_dir.mkdir(parents=True)
        for unit in sorted((root / "src").glob("*.ad?")):
            transfer(unit, src_dir / unit.name, link=False)
        for variant in SOURCE_VARIANTS:
            (src_dir / variant).mkdir(parents=True, exist_ok=True)
            for unit in sorted((root / "src" / variant).glob("*.ad?")):
                transfer(unit, src_dir / variant / unit.name, link=False)

    for pattern in ("*.gpr", "*.gpr.templ"):
        for project in sorted(root.glob(pattern)):
            transfer(project, project_dir / project.name, link=link)
    transfer(root / "proof", project_dir / "proof", link=link)

    return check_installed_tree(dest)


def do_install_tree(args):
    print(install_tree(args.dest, source=args.source, link=args.link))


def do_check_tree(args):
    """Report whether a directory holds a SPARKlib installed tree"""
    print(check_installed_tree(args.root))


# Patterns marking the parts of the library that are only analysed in body
# mode. Both are anchored on the "#BODYMODE" marker comment.

# "... SPARK_Mode => Off --  #BODYMODE" at the end of a line: enable the mode
# while preserving whatever precedes it on the line.
PATTERN_TO_ENABLE = re.compile(
    r"(SPARK_Mode\s*=>\s*)Off(\s*--  #BODYMODE\s*$)", re.IGNORECASE
)

# A line holding nothing but "pragma SPARK_Mode (Off); --  #BODYMODE": drop the
# pragma but keep the line, so that line numbers are preserved.
PATTERN_TO_REMOVE = re.compile(
    r"^\s*pragma\s+SPARK_Mode\s*\(\s*Off\s*\)\s*;\s*--  #BODYMODE\s*$",
    re.IGNORECASE,
)


def preprocess_file(filepath):
    """Rewrite the SPARK_Mode markers of one file in place.

    Line numbers are preserved, so that diagnostics and committed sessions
    still refer to the right places.
    """
    fd, temp_path = tempfile.mkstemp()
    try:
        with os.fdopen(fd, "w", newline="") as newfile:
            with open(filepath, "r", newline="") as oldfile:
                for line in oldfile:
                    new_line, count = PATTERN_TO_ENABLE.subn(r"\1On\2", line)
                    if count > 0:
                        newfile.write(new_line)
                        continue

                    if PATTERN_TO_REMOVE.match(line):
                        # Keep the line ending, drop the pragma. The last line
                        # of a file may have no line ending at all.
                        if line.endswith("\r\n"):
                            newfile.write("\r\n")
                        elif line.endswith("\n"):
                            newfile.write("\n")
                        continue

                    newfile.write(line)
        # The temporary file is private to its creator, whereas the file
        # being rewritten keeps whatever access the installation gave it.
        shutil.copymode(filepath, temp_path)
        shutil.move(temp_path, filepath)
    except Exception:
        if os.path.exists(temp_path):
            os.unlink(temp_path)
        raise


def do_preprocess(args):
    """Rewrite the SPARK_Mode markers of the given files in place"""
    for filepath in args.files:
        preprocess_file(filepath)


def body_mode(dest, from_tree=None, source=None):
    """Materialize a body-mode tree under `dest`, and return its project dir.

    The sources are rewritten in place, so the tree is always a private copy;
    pointing this at a tree of symlinks into a checkout would corrupt the
    checkout.
    """
    dest = Path(dest).resolve()

    if from_tree is not None:
        root = Path(from_tree).resolve()
        check_installed_tree(root)
        if root == dest:
            raise RuntimeError("--from-tree and --dest must differ")
        for rel in ("lib", "include"):
            target = dest / rel
            remove_path(target)
            shutil.copytree(str(root / rel), str(target), symlinks=False)
    else:
        for rel in ("lib", "include"):
            remove_path(dest / rel)
        install_tree(dest, source=source, link=False)

    src_dir = dest / INSTALLED_SOURCE_DIR
    for variant in SOURCE_VARIANTS:
        shutil.copy(str(src_dir / EXEC_UNIT), str(src_dir / variant / "spark.ads"))

    for path in (dest / "include").rglob("*"):
        if path.is_file():
            preprocess_file(str(path))

    return check_installed_tree(dest)


def do_body_mode(args):
    print(body_mode(args.dest, from_tree=args.from_tree, source=args.source))


def source_mode(dest, from_tree):
    """Flatten an installed or body-mode tree into the source-tree shape.

    This is what SPARKLIB_INSTALLED=False expects: project files at the root,
    sources in "src", Coq material in "proof". Returns the populated directory.

    Unlike an installed tree, the destination is not emptied first: it is a
    plain directory that may legitimately hold unrelated projects. Only the
    entries this function writes are refreshed, so project files left by an
    earlier run from a different source survive. Pass a fresh directory when
    the result must hold nothing but what the source currently provides.
    """
    root = Path(from_tree).resolve()
    project_dir = check_installed_tree(root)
    dest = Path(dest).resolve()
    dest.mkdir(parents=True, exist_ok=True)

    # Take every project file, so that the result serves the light library and
    # the templates as well as the full one.
    for pattern in ("*.gpr", "*.gpr.templ"):
        for project in sorted(project_dir.glob(pattern)):
            transfer(project, dest / project.name, link=False)
    transfer(root / INSTALLED_SOURCE_DIR, dest / "src", link=False)
    transfer(project_dir / "proof", dest / "proof", link=False)
    return dest


def do_source_mode(args):
    print(source_mode(args.dest, args.from_tree))


def test_project(dest, object_dir="sparklib_obj"):
    """Write the project file a SPARKlib client uses to build the library.

    The library location is not named here; callers pass it to the tools with
    "-aP" so that concurrent runs cannot pick up each other's SPARKlib.
    """
    dest = Path(dest).resolve()
    dest.mkdir(parents=True, exist_ok=True)
    project_file = dest / "sparklib.gpr"
    with open(project_file, "w") as f_prj:
        f_prj.write('project SPARKlib extends "sparklib_internal" is\n')
        f_prj.write('   for Object_Dir use "' + str(object_dir) + '";\n')
        f_prj.write("   for Source_Dirs use SPARKlib_Internal'Source_Dirs;\n")
        f_prj.write(
            "   for Excluded_Source_Files use "
            + "SPARKlib_Internal'Excluded_Source_Files;\n"
        )
        f_prj.write("end SPARKlib;\n")
    return project_file


def do_test_project(args):
    print(test_project(args.dest, object_dir=args.object_dir))


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("install-tree", help="build an installed tree")
    p.add_argument("--dest", required=True, help="root of the tree to build")
    p.add_argument("--source", help="SPARKlib source tree (default: this repo)")
    p.add_argument("--link", action="store_true", help="symlink instead of copying")
    p.set_defaults(func=do_install_tree)

    p = sub.add_parser("body-mode", help="build a preprocessed body-mode tree")
    p.add_argument("--dest", required=True, help="root of the tree to build")
    # Either an installed tree is derived from, or one is built from sources;
    # naming a source tree in the first case would say nothing.
    origin = p.add_mutually_exclusive_group()
    origin.add_argument("--from-tree", help="installed tree to derive it from")
    origin.add_argument("--source", help="SPARKlib source tree (default: this repo)")
    p.set_defaults(func=do_body_mode)

    p = sub.add_parser("source-mode", help="flatten a tree to the source shape")
    p.add_argument("--dest", required=True, help="directory to populate")
    p.add_argument("--from-tree", required=True, help="tree to flatten")
    p.set_defaults(func=do_source_mode)

    p = sub.add_parser("check-tree", help="validate an installed-tree layout")
    p.add_argument("root", help="root of the tree to check")
    p.set_defaults(func=do_check_tree)

    p = sub.add_parser("preprocess", help="rewrite SPARK_Mode markers in place")
    p.add_argument("files", nargs="+")
    p.set_defaults(func=do_preprocess)

    p = sub.add_parser("test-project", help="write a client sparklib.gpr")
    p.add_argument("--dest", required=True, help="directory to write it in")
    p.add_argument("--object-dir", default="sparklib_obj")
    p.set_defaults(func=do_test_project)

    args = parser.parse_args(argv)
    try:
        args.func(args)
    except RuntimeError as e:
        print(f"sparklib_tree: {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
