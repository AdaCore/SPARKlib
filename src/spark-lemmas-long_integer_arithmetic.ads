--
--  Copyright (C) 2016-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

pragma SPARK_Mode;

with SPARK.Conversions.Long_Integer_Conversions;
use SPARK.Conversions.Long_Integer_Conversions;

with SPARK.Lemmas.Arithmetic;
pragma Elaborate_All (SPARK.Lemmas.Arithmetic);

package SPARK.Lemmas.Long_Integer_Arithmetic is new
  SPARK.Lemmas.Arithmetic (Long_Integer, To_Big_Integer);
