--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Handles for pointers not subject to ownership

pragma Extensions_Allowed (On);

package SPARK.Pointers.Handles.Plain_Handles
  with SPARK_Mode
is

   type Handle is private
   with
     Default_Initial_Condition => null,
     Annotate                  =>
       (GNATprove, Predefined_Equality, "No_Equality");

   function "=" (X, Y : Handle) return Boolean is abstract;
   --  Handles have no identity of their own; compare them through the
   --  "=" of the Handle_Operations of the pointer unit they belong to.

private
   pragma SPARK_Mode (Off);

   type Data_Placeholder is null record;

   type Data_Placeholder_Access is access Data_Placeholder;
   for Data_Placeholder_Access'Size use Standard'Address_Size;
   --  A thin pointer: a handle is reinterpreted as a one-word
   --  pointer, which a fat pointer would break.

   type Handle is record
      Data : Data_Placeholder_Access;
   end record;

end SPARK.Pointers.Handles.Plain_Handles;
