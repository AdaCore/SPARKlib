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

Some units or subprograms are hidden from analysis for regular use, but
`SPARK_Mode` should be enabled for specific tests. For this use case, these
tests use sparklib in a special body mode. The affected pragmas and aspects
name the static Boolean constant `SPARK.Body_Mode.Enabled` instead of `On` or
`Off`:
```
   pragma SPARK_Mode (SPARK.Body_Mode.Enabled);
```
and

```
  with SPARK_Mode => SPARK.Body_Mode.Enabled
```

Two variants of `SPARK.Body_Mode` exist, one for each value of the constant.
The library project files select between them, and between the two variants of
the root `SPARK` unit, through the `SPARKLIB_BODY_MODE` external, whose value
is `On` or `Off` (the default). Neither variant follows the Ada naming scheme,
so only the one named by the projects' `Naming` package is ever a source of the
library.
