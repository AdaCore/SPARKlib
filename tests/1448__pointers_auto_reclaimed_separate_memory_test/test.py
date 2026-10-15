from test_support import prove_all, sparklib_exec_test


if __name__ == "__main__":
    prove_all(
        opt=["--no-inlining", "-u", "test.adb", "inst.adb"],
        sparklib=True,
        counterexample=False,
    )
    sparklib_exec_test(sparklib_bodymode=True)
    sparklib_exec_test(binary="./obj/test_reclamation", sparklib_bodymode=True)
