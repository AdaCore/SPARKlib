--
--  Copyright (C) 2020-2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma SPARK_Mode;

with SPARK.Big_Integers; use SPARK.Big_Integers;

package SPARK.Conversions.Long_Integer_Conversions is new
  Signed_Conversions (Long_Integer);
