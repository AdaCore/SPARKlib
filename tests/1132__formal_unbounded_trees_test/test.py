from test_support import prove_all, sparklib_exec_test

contains_manual_proof = False


def replay():
    prove_all(sparklib=True, level=2, procs=0, sparklib_bodymode=True)


if __name__ == "__main__":
    prove_all(replay="session", sparklib=True, sparklib_bodymode=True)
    sparklib_exec_test(sparklib_bodymode=True)
