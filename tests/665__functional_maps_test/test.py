from subprocess import call
from test_support import no_crash
import os

contains_manual_proof = False
os.environ["SPARKLIB_BODY_MODE"] = "On"


if __name__ == "__main__":
    no_crash(sparklib=True, opt=["--no-inlining", "-P", "test.gpr"])

    call(["gprbuild", "-q", "-P", "test.gpr"])
    call(["./obj/test"])
