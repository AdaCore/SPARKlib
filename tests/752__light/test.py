from e3.os.process import Run
from test_support import do_flow, gprbuild

do_flow()
gprbuild(opt=["-P", "test.gpr"])
print(Run(["./main"]).out)
