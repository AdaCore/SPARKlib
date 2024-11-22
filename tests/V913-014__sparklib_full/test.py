from test_support import prove_all, gprbuild

prove_all(sparklib=True, opt=["-U"])
gprbuild(opt=["-P", "test.gpr"])
