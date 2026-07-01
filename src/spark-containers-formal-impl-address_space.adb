--
--  Copyright (C) 2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with System;
use type System.Address;

package body SPARK.Containers.Formal.Impl.Address_Space
  with SPARK_Mode => Off
is

   package body Address_Comparison
     with SPARK_Mode => Off
   is

      --------------------------
      -- Object_Logical_Equal --
      --------------------------

      function Object_Logical_Equal (Left, Right : Object_Type) return Boolean
      is (Left = Right);

      -----------------
      -- Same_Object --
      -----------------

      function Same_Object (Left, Right : Object_Type) return Boolean
      is (Left'Address = Right'Address);

   end Address_Comparison;

end SPARK.Containers.Formal.Impl.Address_Space;
