--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package body SPARK.Pointers.Static_Allocation
  with SPARK_Mode => Off
is
   X : aliased Object := Create_Object;
begin
   P := X'Access;
end SPARK.Pointers.Static_Allocation;
