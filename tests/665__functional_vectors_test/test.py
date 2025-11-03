from test_support import prove_all, sparklib_exec_test
import os

os.environ["SPARKLIB_BODY_MODE"] = "On"


if __name__ == "__main__":
    prove_all(sparklib=True, opt=["--no-inlining"])
    sparklib_exec_test()
