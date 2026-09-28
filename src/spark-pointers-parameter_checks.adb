--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package body SPARK.Pointers.Parameter_Checks
  with SPARK_Mode
is

   -----------------------
   -- Assignment_Checks --
   -----------------------

   package body Assignment_Checks is

      procedure Check_Assignment (X : in out T; X_Save : T) is

         --  Assign X into Y and check that it is preserved

         Y : T := X;
         pragma Unmodified (Y);
         --  Y is not modified, but it must be a variable rather than a
         --  constant: for an owning T the declaration moves X into Y and the
         --  assignment below moves it back.

      begin
         pragma Assert (Logical_Eq (X_Save, Y));

         X := Y;
      end Check_Assignment;

   end Assignment_Checks;

   -------------------------
   -- Is_Reclaimed_Checks --
   -------------------------

   package body Is_Reclaimed_Checks is
      pragma Assertion_Policy (SPARKlib_Internal => Ignore);

      procedure Check_Reclamation is

         --  Check that we can prove reclamation of any value of type T on
         --  which Is_Reclaimed returns True.

         function Reclaimed_Value return T
         with
           Import,
           Global => null,
           Post   => Is_Reclaimed (Reclaimed_Value'Result);

         V : constant T := Reclaimed_Value;
         pragma Unreferenced (V);
         --  Declaring V is the check: it must be provable that a value on
         --  which Is_Reclaimed holds needs no reclamation at the end of the
         --  scope. Nothing is done with it.
      begin
         null;
      end Check_Reclamation;

   end Is_Reclaimed_Checks;

   ------------------------
   -- Reclamation_Checks --
   ------------------------

   package body Reclamation_Checks is
      pragma Assertion_Policy (SPARKlib_Internal => Ignore);

      procedure Check_Reclamation is

         --  Check that we can prove reclamation of any value of type T after
         --  a call to Reclaim.

         function Any_Value return T
         with Import, Global => null;

         V : T := Any_Value;
      begin
         Reclaim (V);
      end Check_Reclamation;

   end Reclamation_Checks;

end SPARK.Pointers.Parameter_Checks;
