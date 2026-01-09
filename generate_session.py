#!/usr/bin/env python

import difflib
import glob
import os
from pathlib import Path
import re
import shutil
import sys
import tempfile


def run(cmd):
    print("")
    print("run: " + cmd)
    os.system(cmd)


projectfile = "sparklib_gen.gpr"


def run_manual(check_to_prove, option=""):
    cmd = (
        f"gnatprove -j0 -P {projectfile} -U --output=oneline"
        "--prover=coq --report=provers"
    )
    if ":" not in check_to_prove:
        run(cmd + " " + option + check_to_prove)
    else:
        run(cmd + " " + option + "--limit-line=" + check_to_prove)


def run_automatic(prover, level=4, timeout=None):
    cmd = (
        f"gnatprove -P {projectfile} --counterexamples=off --output=oneline -j0"
        + f" --prover={prover} --level={level}"
    )
    if timeout is not None:
        cmd += f" --timeout={timeout}"
    run(cmd)


def run_options(opt):
    cmd = f"gnatprove -P {projectfile} --counterexamples=off -j0 {opt}"
    run(cmd)


def copy_file(f_ctx, f_v):
    # This creates a new file which is the new .ctx file.
    # Behavior: Before the intros tactic we append only f_v; after the intros
    # or '#' character, we append only f_ctx.
    temp = f_ctx + "___tmp.tmp"
    b = False
    with open(temp, "w") as new_temp:
        with open(f_v) as file_v:
            for line in file_v:
                if line[:6] == "intros":
                    break
                else:
                    new_temp.write(line)
        with open(f_ctx) as file_ctx:
            for line in file_ctx:
                if line[:6] == "intros" or line[:1] == "#":
                    b = True
                if b:
                    new_temp.write(line)
    #   Replace context file with the temp file
    os.remove(f_ctx)
    shutil.move(temp, f_ctx)


def diff_file(f_ctx, g_v):
    # This function makes a diff without spaces between files f and g. If there
    # is a line which is in the first file and not in the second one, create a
    # temp diff file of same name in folder temp, otherwise do not create temp
    # file.
    # We assume f ends with .ctx and g ends with .v. Basically, don't use this
    # function anywhere else.
    diff_seen = False
    with open(f_ctx, "r") as file1:
        with open(g_v, "r") as file2:
            # Removing spaces because cpp introduce extra spaces as diff.
            lines1 = list(
                map(
                    lambda y: str(filter(lambda x: x not in " \t", y)),
                    file1.readlines(),
                )
            )
            lines2 = list(
                map(
                    lambda y: str(filter(lambda x: x not in " \t", y)),
                    file2.readlines(),
                )
            )
            diff = difflib.unified_diff(lines1, lines2, fromfile=f_ctx, tofile=g_v, n=1)
            for line in diff:
                if not line[0] == "-":
                    diff_seen = True
                    break
    if diff_seen:
        temp_file = os.path.basename(f_ctx)[:-4] + ".diff"
        temp_path = os.path.join("./temp", temp_file)
        with open(temp_path, "a") as new:
            for line in diff:
                new.write(line)


def diff_all(gen_ctx):
    # If files have changed due to changes in spark/why3 generates files,
    # diff will be printed in temp.
    # For technical reasons, diff are printed without spaces
    # Do not use this function in an other context. It is used only once
    # with gen_ctx to False meaning files are not erased and replaced with
    # new ones. To replace them, pass True.
    for root, _dirs, files in os.walk("./proof"):
        for name in files:
            if name.endswith(".v"):
                ctx_file = os.path.join(root, name[:-2] + ".ctx")
                v_file = os.path.join(root, name)
                diff_file(ctx_file, v_file)
                if gen_ctx:
                    copy_file(ctx_file, v_file)


def kill_and_regenerate(check):
    list_of_check = []
    if check:
        list_of_check.append(check)
    else:
        with open("manual_proof.in") as f:
            for i in f:
                list_of_check.append(i)
    print("")
    print("--------------------------")
    print("Cleanup previous artifacts")
    print("--------------------------")
    for d in ["./proof/sessions", "./temp"]:
        if os.path.isdir(d):
            print(f"deleting {d}")
            shutil.rmtree(d)
    os.makedirs("./temp")
    os.system("make clean")
    os.environ["SPARKLIB_INSTALLED"] = "False"
    print("")
    print("----------------------------")
    print("Generate the Coq proof files")
    print("----------------------------")
    #   Force regeneration of coq files where necessary.
    #   This step is used to generate the fake coq files and put the names of
    #   coq files inside the session. This cannot be done in one step because
    #   if coq files are already present, it will create new ones (not
    #   check the present coq files).
    for i in list_of_check:
        run_manual(i)
    #   Make the diff between generated .v and .ctx files. If there are differences
    #   between them not in the proof, you are sure to fail
    diff_all(False)
    print("")
    print("-----------------------------")
    print("Check and register Coq proofs")
    print("-----------------------------")
    #   cleaning and regeneration of *.v
    os.system("make clean")
    os.system("make generate")
    run_automatic("cvc5", level=1)
    #   Do *not* remove this call as it is used to check that coq proofs are
    #   correct after regeneration. And ability to generate session is *necessary*
    #   as there is no way to extend a session in gnatprove.
    for i in list_of_check:
        run_manual(i)
    print("")
    print("---------------------------------------------")
    print("Prove remaining checks with automatic provers")
    print("---------------------------------------------")
    print("")
    run_automatic("cvc5,z3,alt-ergo,colibri", timeout=100)
    print("")
    print("---------------------------")
    print("Summarize all proved checks")
    print("---------------------------")
    run_options(opt="--output-msg-only --report=provers")
    for shape_file in glob.glob("proof/sessions/*/why3shapes*"):
        print("deleting shapes file ", shape_file)
        os.remove(shape_file)
    for bak_file in glob.glob("proof/sessions/*/*.bak"):
        print("deleting temp file ", bak_file)
        os.remove(bak_file)


def choose_mode():
    if len(sys.argv) == 1:
        kill_and_regenerate(None)
    else:
        if len(sys.argv) == 2:
            kill_and_regenerate(sys.argv[1])


def preprocess_sparklib_source_file(filepath):
    """
    Reads a file line by line and replaces specific SPARK_Mode patterns
    in-place, preserving line numbers.

    Args:
        filepath (str): The path to the file to be processed.
    """
    # Pattern 1: Recognizes '... SPARK_Mode => Off --  #BODYMODE' at the end of a line.
    # It's case-insensitive and handles variable whitespace.
    # This will be used with re.sub to replace 'Off' with 'On' while preserving
    # any leading content on the line.
    pattern_to_enable = re.compile(
        r"(SPARK_Mode\s*=>\s*)Off(\s*--  #BODYMODE\s*$)", re.IGNORECASE
    )

    # Pattern 2: Recognizes a line containing only
    # 'pragma SPARK_Mode (Off); -- # #BODYMODE'
    # It's case-insensitive and handles variable whitespace.
    pattern_to_remove = re.compile(
        r"^\s*pragma\s+SPARK_Mode\s*\(\s*Off\s*\)\s*;\s*--  #BODYMODE\s*$",
        re.IGNORECASE,
    )

    fd, temp_path = tempfile.mkstemp()

    try:
        with os.fdopen(fd, "w", newline="") as newfile:
            with open(filepath, "r", newline="") as oldfile:
                for line in oldfile:
                    # Test for the first pattern and replace using re.subn.
                    # re.subn returns a tuple: (new_string, number_of_subs_made).
                    # This handles cases where the pattern is not at the start
                    # of the line.
                    new_line, count = pattern_to_enable.subn(r"\1On\2", line)
                    if count > 0:
                        # If a substitution was made, write the modified line.
                        # new_line already contains the original newline
                        # character.
                        newfile.write(new_line)
                        continue

                    # Test for the second pattern.
                    # This pattern is expected to match the entire line.
                    match_remove = pattern_to_remove.match(line)
                    if match_remove:
                        if line.endswith("\r\n"):
                            # Preserve Windows-style line endings.
                            newfile.write("\r\n")
                        elif line.endswith("\n"):
                            # Preserve Unix-style line endings.
                            newfile.write("\n")
                        else:
                            # EOF case
                            pass
                        continue

                    # If no pattern is matched, write the original line back to
                    # the file.  'line' already contains a newline character.
                    newfile.write(line)

        # Replace the original file with the modified temporary file.
        shutil.move(temp_path, filepath)

    except FileNotFoundError:
        print(f"Error: The file {filepath!r} was not found.", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)
        sys.exit(1)


sparklib_gen_content = """
with "sparklib_common";
project sparklib_gen is
   for Source_Dirs use ("src2", "src2/full");
   for Object_Dir use "obj2";
   package Compiler is
      for Default_Switches ("Ada") use ("-gnat2022", "-gnatygo-u", "-gnata", "-gnatwI");
   end Compiler;
   package Prove is
     for Proof_Dir use "proof";
   end Prove;
end sparklib_gen;
"""


try:
    with open("sparklib_gen.gpr", "w") as f_prj:
        f_prj.write(sparklib_gen_content)
    shutil.copytree("src", "src2")
    for path_obj in Path("src2").rglob("*"):
        if path_obj.is_file():
            preprocess_sparklib_source_file(path_obj)
    choose_mode()
finally:
    if os.path.isfile("sparklib_gen.gpr"):
        os.remove("sparklib_gen.gpr")
    if os.path.isdir("src2"):
        shutil.rmtree("src2")
