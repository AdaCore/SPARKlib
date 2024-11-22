from test_support import prove_all, sparklib_exec_test
import os

contains_manual_proof = False
os.environ["SPARKLIB_BODY_MODE"] = "On"


if __name__ == "__main__":
    prove_all(
        counterexample=False,
        sparklib=True,
        opt=["-u", "inst.ads", "test.adb", "test_resize.adb"],
    )
    sparklib_exec_test()
    sparklib_exec_test("test_resize.gpr", "./r_obj/test_resize")
