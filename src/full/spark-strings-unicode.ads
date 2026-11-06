--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package SPARK.Strings.Unicode
  with SPARK_Mode
is

   type Code_Point is range 0 .. 16#10_FFFF#;

   subtype Scalar_Value is Code_Point
   with
     Static_Predicate =>
       Scalar_Value in 16#0000# .. 16#D7FF# | 16#E000# .. 16#10_FFFF#;

end SPARK.Strings.Unicode;
