from test_support import prove_all, gprbuild

prove_all(steps=600, opt=["-U"])
gprbuild(opt=["-P", "test.gpr"])
