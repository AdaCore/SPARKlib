from test_support import prove_all, sparklib_exec_test

if __name__ == "__main__":
    prove_all(sparklib=True, steps=1000, opt=["--no-inlining"], sparklib_bodymode=True)
    sparklib_exec_test("test.gpr", "./obj/test_string")
