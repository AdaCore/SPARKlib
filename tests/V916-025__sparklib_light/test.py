from test_support import prove_all
from subprocess import call
import os

prove_all(opt=["-U"])
call(["gprbuild", "-q", "-P", "test.gpr"])
