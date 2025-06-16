--
--  Copyright (C) 2017-2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma SPARK_Mode;
with SPARK.Conversions.Long_Float_Conversions;
use SPARK.Conversions.Long_Float_Conversions;
with SPARK.Lemmas.Floating_Point_Arithmetic;

pragma Elaborate_All (SPARK.Lemmas.Floating_Point_Arithmetic);
package SPARK.Lemmas.Long_Float_Arithmetic is new
  SPARK.Lemmas.Floating_Point_Arithmetic
    (Fl           => Long_Float,
     Int          => Long_Integer,
     Fl_Last_Sqrt => 2.0 ** 511,
     Max_Int      => Long_Float_Max_Int,
     Epsilon      => Long_Float_Epsilon,
     Eta          => Long_Float_Eta,
     Real         => To_Big_Real);
