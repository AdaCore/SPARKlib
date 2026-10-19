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

# 4. Configuration and testing

`SPARKlib_Config` contains the static Boolean constants used by the library's
`SPARK_Mode` pragmas and aspects. By default, `Body_Mode` is `False` and
`Reachability_Body_Mode` follows `Body_Mode`, so both are disabled. Body mode
exposes library bodies and the private parts they rely on for analysis.
Reachability body mode controls only `SPARK.Higher_Order.Reachability`;
`SPARK.Pointers.Abstract_Reachability` follows the general body mode.

To customize these switches, write a file named `sparklib_config.ads`:

```ada
package SPARKlib_Config
  with SPARK_Mode, Pure
is
   Body_Mode : constant Boolean := True;
   Reachability_Body_Mode : constant Boolean := False;
end SPARKlib_Config;
```

Pass its directory to both build and proof commands, for example:

```
gnatprove -P client.gpr -XSPARKLIB_BODY_MODE=On -XSPARKLIB_CONFIG_DIR=/absolute/path/to/config
```

The directory becomes a source directory of the SPARKlib project. Dedicate it
to this configuration package, and define every constant from the supplied
configuration. When upgrading SPARKlib, add any newly introduced constants to
custom configurations. The installed library need not be modified. The supplied
variants have nonstandard file names, so only the selected configuration is a
library source. Client projects should inherit the library's source directories,
as shown in `sparklib.gpr.templ`.

`SPARKLIB_BODY_MODE=On` selects a supplied configuration with both switches
enabled when no custom directory is given. It also selects the root `SPARK`
variant allowing execution of all assertion levels; `Off` (the default) retains
the regular assertion levels. A custom configuration replaces the Boolean
settings only, so use `SPARKLIB_BODY_MODE=On` as well when testing executable
contracts. There is no separate scenario variable for reachability.
