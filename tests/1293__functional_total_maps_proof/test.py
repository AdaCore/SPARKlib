from test_support import prove_all

if __name__ == "__main__":
    prove_all(
        sparklib=True, filter_sparklib=False, sparklib_bodymode=True, no_fail=True
    )
