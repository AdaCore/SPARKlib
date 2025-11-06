from test_support import no_crash, sparklib_exec_test


if __name__ == "__main__":
    no_crash(
        sparklib=True, opt=["--no-inlining", "-P", "test.gpr"], sparklib_bodymode=True
    )
    sparklib_exec_test()
