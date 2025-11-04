from test_support import prove_all, create_sparklib
import os

import shutil

# first copy preprocessed sparklib to local folder
create_sparklib(sparklib_bodymode=True)

# then arrange folders so that SPARKLIB_INSTALLED works


def copy_project_file():
    lib_gnat = os.path.join("lib", "gnat")
    for fn in ["sparklib_internal.gpr", "sparklib_common.gpr"]:
        shutil.copyfile(os.path.join(lib_gnat, fn), fn)


def copy_lemma_files():
    shutil.copytree(os.path.join("include", "spark"), "src")


def copy_proof_files():
    proof_dir = os.path.join("lib", "gnat", "proof")
    shutil.copytree(proof_dir, "proof")


copy_project_file()
copy_lemma_files()
copy_proof_files()
os.environ["SPARKLIB_INSTALLED"] = "False"

prove_all(
    replay=True,
    prover=["coq", "cvc5", "z3", "altergo", "colibri"],
    counterexample=False,
    #  We need to remove useless coq warning for Grammar extension
    filter_output=".*Grammar extension",
    filter_sparklib=False,
)
