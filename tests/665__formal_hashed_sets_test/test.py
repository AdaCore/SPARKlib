from test_support import prove_all, sparklib_exec_test
import os

contains_manual_proof = False
os.environ["SPARKLIB_BODY_MODE"] = "On"


if __name__ == "__main__":
    prove_all(counterexample=False, sparklib=True)
    sparklib_exec_test()
