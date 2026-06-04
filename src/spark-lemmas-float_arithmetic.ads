--
--  Copyright (C) 2017-2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma SPARK_Mode;
with SPARK.Conversions.Float_Conversions;
use SPARK.Conversions.Float_Conversions;
with SPARK.Lemmas.Floating_Point_Arithmetic;

pragma Elaborate_All (SPARK.Lemmas.Floating_Point_Arithmetic);

package SPARK.Lemmas.Float_Arithmetic is new
  SPARK.Lemmas.Floating_Point_Arithmetic
    (Fl           => Float,
     Int          => Integer,
     Fl_Last_Sqrt => 2.0 ** 63,
     Max_Int      => Float_Max_Int,
     Epsilon      => Float_Epsilon,
     Eta          => Float_Eta,
     Real         => To_Big_Real);
