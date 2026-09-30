from test_support import prove_all, sparklib_exec_test


if __name__ == "__main__":
    prove_all(
        sparklib=True,
        steps=8000,
        opt=["-u", "inst.ads", "test.adb", "--no-inlining"],
        sparklib_bodymode=True,
    )
    sparklib_exec_test(sparklib_bodymode=True)
