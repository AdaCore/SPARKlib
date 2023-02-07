--
--  Copyright (C) 2017-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

pragma SPARK_Mode;
with SPARK.Big_Integers;
use  SPARK.Big_Integers;
with SPARK.Big_Reals;
use  SPARK.Big_Reals;
with SPARK.Conversions.Float_Conversions;
use SPARK.Conversions.Float_Conversions;
with SPARK.Lemmas.Floating_Point_Arithmetic;

pragma Elaborate_All (SPARK.Lemmas.Floating_Point_Arithmetic);
package SPARK.Lemmas.Float_Arithmetic is new
  SPARK.Lemmas.Floating_Point_Arithmetic
    (Fl           => Float,
     Int          => Integer,
     Fl_Last_Sqrt => 2.0 ** 63,
     Max_Int      => 2 ** 24,
     Epsilon      => 2.0 ** (-24),
     Eta          => 2.0 ** (-150),
     Real         => To_Big_Real);
