from test_support import prove_all, sparklib_exec_test


if __name__ == "__main__":
    prove_all(sparklib=True, opt=["--no-inlining"], counterexample=False)
    sparklib_exec_test(sparklib_bodymode=True)
