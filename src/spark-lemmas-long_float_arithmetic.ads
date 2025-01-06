--
--  Copyright (C) 2017-2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma SPARK_Mode;
with SPARK.Big_Integers;
use  SPARK.Big_Integers;
with SPARK.Big_Reals;
use  SPARK.Big_Reals;
with SPARK.Conversions.Long_Float_Conversions;
use SPARK.Conversions.Long_Float_Conversions;
with SPARK.Lemmas.Floating_Point_Arithmetic;

pragma Elaborate_All (SPARK.Lemmas.Floating_Point_Arithmetic);
package SPARK.Lemmas.Long_Float_Arithmetic is new
  SPARK.Lemmas.Floating_Point_Arithmetic
    (Fl           => Long_Float,
     Int          => Long_Integer,
     Fl_Last_Sqrt => 2.0 ** 511,
     Max_Int      => 2 ** 53,
     Epsilon      => 2.0 ** (-53),
     Eta          => 2.0 ** (-1075),
     Real         => To_Big_Real);
