from subprocess import call
from test_support import prove_all
import os

contains_manual_proof = False
os.environ["SPARKLIB_BODY_MODE"] = "On"


if __name__ == "__main__":
    prove_all(sparklib=True)

    call(["gprbuild", "-q", "-P", "test.gpr"])
    call(["./obj/test"])
