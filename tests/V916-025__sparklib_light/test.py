from test_support import prove_all
from subprocess import call
import os

prove_all(steps=600, opt=["-U"])
call(["gprbuild", "-q", "-P", "test.gpr"])
