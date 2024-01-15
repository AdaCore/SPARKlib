--
--  Copyright (C) 2022-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma SPARK_Mode;

with SPARK.Big_Reals;

package SPARK.Conversions.Float_Conversions is new
  SPARK.Big_Reals.Float_Conversions (Float);
