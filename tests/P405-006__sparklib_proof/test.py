from test_support import prove_all, resolve_sparklib_location
import os
import shutil

# Prove the library from a copy of the install in the source-tree shape, which
# is what SPARKLIB_INSTALLED=False expects: project files at the top level,
# sources in "src", Coq material in "proof". The copy makes the sessions
# committed with the library the ones that get replayed here.

project_dir, root_dir = resolve_sparklib_location()


def copy_project_files():
    for fn in ["sparklib_internal.gpr", "sparklib_common.gpr"]:
        shutil.copyfile(os.path.join(project_dir, fn), fn)


def copy_lemma_files():
    shutil.copytree(os.path.join(root_dir, "include", "spark"), "src")


def copy_proof_files():
    shutil.copytree(os.path.join(project_dir, "proof"), "proof")


copy_project_files()
copy_lemma_files()
copy_proof_files()
os.environ["SPARKLIB_INSTALLED"] = "False"

prove_all(
    replay="session",
    prover=["coq", "cvc5", "z3", "altergo", "colibri"],
    counterexample=False,
    #  We need to remove useless coq warning for Grammar extension
    filter_output=".*Grammar extension",
    filter_sparklib=False,
    sparklib_bodymode=True,
)
