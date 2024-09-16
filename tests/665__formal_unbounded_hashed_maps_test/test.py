from subprocess import call
from test_support import prove_all
import os

contains_manual_proof = False
os.environ["SPARKLIB_BODY_MODE"] = "On"


if __name__ == "__main__":
    prove_all(
        counterexample=False,
        sparklib=True,
        opt=["-u", "inst.ads", "test.adb", "test_resize.adb"],
    )

    call(["gprbuild", "-q", "-P", "test.gpr"])
    call(["./obj/test"])

    call(["gprbuild", "-q", "-P", "test_resize.gpr"])
    call(["./r_obj/test_resize"])
