--
--  Copyright (C) 2022-2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This file replaces spark.ads for testing in "body mode"

pragma Assertion_Level (SPARKlib_Defensive);
pragma Assertion_Level (SPARKlib_Logic);
pragma Assertion_Level (SPARKlib_Full, Depends => SPARKlib_Logic);
--  Allow execution of SPARKlib_Logic and SPARKlib_Full here for all runtimes

package SPARK
  with SPARK_Mode, Pure
is

end SPARK;
