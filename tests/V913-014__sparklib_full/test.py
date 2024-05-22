from test_support import prove_all
from subprocess import call

prove_all(sparklib=True, opt=["-U"])
call(["gprbuild", "-q", "-P", "test.gpr"])
