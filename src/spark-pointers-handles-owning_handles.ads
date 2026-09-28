--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Handles for pointers subject to ownership and reclaimed explicitly by the
--  user.

pragma Extensions_Allowed (On);

package SPARK.Pointers.Handles.Owning_Handles
  with SPARK_Mode
is

   type Handle is private
   with
     Default_Initial_Condition => (Static => Is_Uninitialized (Handle)),
     Annotate                  => (GNATprove, Ownership, "Needs_Reclamation"),
     Annotate                  =>
       (GNATprove, Predefined_Equality, "No_Equality");

   function "=" (X, Y : Handle) return Boolean is abstract;
   --  Handles have no identity of their own; compare them through the
   --  "=" of the Handle_Operations of the pointer unit they belong to.

   function Is_Reclaimed (H : Handle) return Boolean
   with
     Import,
     Ghost    => Static,
     Global   => null,
     Annotate => (GNATprove, Ownership, "Is_Reclaimed");

   function Is_Uninitialized (H : Handle) return Boolean
   with
     Import,
     Ghost  => Static,
     Global => null,
     Post   => (if Is_Uninitialized'Result then Is_Reclaimed (H));
   --  Used to force initialization

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

end SPARK.Pointers.Handles.Owning_Handles;
