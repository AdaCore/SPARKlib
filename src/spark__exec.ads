--
--  Copyright (C) 2022-2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This unit is meant to replace SPARK for internal testing only

pragma Assertion_Level (SPARKlib_Defensive);
pragma Assertion_Level (SPARKlib_Logic);
pragma Assertion_Level (SPARKlib_Full, Depends => SPARKlib_Logic);
--  Allow execution of SPARKlib_Logic and SPARKlib_Full here for all runtimes

package SPARK with SPARK_Mode, Pure is

end SPARK;
