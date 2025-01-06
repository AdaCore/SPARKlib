--
--  Copyright (C) 2016-2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma SPARK_Mode;
with SPARK.Lemmas.Mod_Arithmetic;
pragma Elaborate_All (SPARK.Lemmas.Mod_Arithmetic);
with Interfaces;
package SPARK.Lemmas.Mod64_Arithmetic is new
  SPARK.Lemmas.Mod_Arithmetic (Interfaces.Unsigned_64);
