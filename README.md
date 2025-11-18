# 1. Introduction

This repository contains the source code for the SPARKlib project. SPARKlib
is meant to provide users of [SPARK](https://github.com/AdaCore/spark2014)
libraries to use in SPARK code. SPARKlib contains various libraries, such as
a wide range of containers, as well as lemmas to use directly in user code.

# 2. Community

News about SPARK project and SPARKlib are shared primarily on [AdaCore's
blog](https://blog.adacore.com/).

# 3. Documentation

Documentation about what is provided in the SPARKlib and how to use it can be
found in the [SPARK User's Guide](https://docs.adacore.com/spark2014-docs/html/ug/en/source/spark_libraries.html#spark-library).

# 4. Testing

Some units or subprograms are in `SPARK_Mode => Off` for regular use, but
`SPARK_Mode` should be enabled for specific tests. For this use case, these
tests use sparklib in a special body mode. In this mode, the marked subprograms
are moved to `SPARK_Mode => On` via a script. The following patterns are
recognized:
```
   pragma SPARK_Mode (Off); --  #BODYMODE
```
and

```
  with SPARK_Mode => Off --  #BODYMODE
```
