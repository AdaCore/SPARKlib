from test_support import no_crash, sparklib_exec_test
import os

os.environ["SPARKLIB_BODY_MODE"] = "On"


if __name__ == "__main__":
    no_crash(sparklib=True, opt=["--no-inlining", "-P", "test.gpr"])
    sparklib_exec_test()
