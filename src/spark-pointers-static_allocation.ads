--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Storage for a single object, exposed through an owning access value.
--  Each instance declares an aliased object initialized by Create_Object,
--  without using an allocator. The object lives as long as the
--  instance, and its access type is subject to the SPARK ownership policy.
--  Create_Object and components of Object may require heap allocation.

pragma Extensions_Allowed (On);
pragma
  Warnings
    (Off,
     """P"" may be null",
     Reason =>
       "P is initialized in the package body before the initial condition");

generic
   type Object (<>) is private;
   with
     function Create_Object return Object
     with Pre => True;

package SPARK.Pointers.Static_Allocation with
    SPARK_Mode,
    Initializes       => P,
    Initial_Condition =>
      (Static => P /= null and then Object_Logic_Equal (P.all, Create_Object))
is
   pragma Elaborate_Body;

   function Object_Logic_Equal (Left, Right : Object) return Boolean
   with
     Import,
     Ghost    => Static,
     Global   => null,
     Annotate => (GNATprove, Logical_Equal);
   --  Logical equality on objects. It is marked as import as it cannot be
   --  safely executed on most object types.

   type Object_Access is access all Object;

   P : Object_Access;
   --  Initially owns the object created during elaboration. Ownership can
   --  be transferred using an ordinary assignment.

end SPARK.Pointers.Static_Allocation;

pragma Warnings (On, """P"" may be null");
