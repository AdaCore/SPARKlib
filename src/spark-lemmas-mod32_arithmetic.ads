--
--  Copyright (C) 2016-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

pragma SPARK_Mode;
with SPARK.Lemmas.Mod_Arithmetic;
pragma Elaborate_All (SPARK.Lemmas.Mod_Arithmetic);
with Interfaces;
package SPARK.Lemmas.Mod32_Arithmetic is new
  SPARK.Lemmas.Mod_Arithmetic (Interfaces.Unsigned_32);
