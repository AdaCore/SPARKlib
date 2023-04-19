--
--  Copyright (C) 2016-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma SPARK_Mode;

with SPARK.Big_Integers;
use SPARK.Big_Integers;

with SPARK.Lemmas.Arithmetic;
pragma Elaborate_All (SPARK.Lemmas.Arithmetic);

package SPARK.Lemmas.Integer_Arithmetic is new
  SPARK.Lemmas.Arithmetic (Integer, To_Big_Integer);
