from subprocess import call
from test_support import do_flow, gprbuild

do_flow()
gprbuild(opt=["-P", "test.gpr"])
call("./main")
