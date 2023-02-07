--
--  Copyright (C) 2022-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

pragma SPARK_Mode;

with SPARK.Big_Reals;

package SPARK.Conversions.Float_Conversions is new
  SPARK.Big_Reals.Float_Conversions (Float);
