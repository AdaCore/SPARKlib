--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package body SPARK.Pointers.Poisoned.Pointers.Array_Operations
  with SPARK_Mode => Off
is

   ----------
   -- Move --
   ----------

   procedure Move
     (Source : in out Pointer_Array; Target : in out Pointer_Array)
   is
      pragma Unmodified (Source);
   begin
      Target := Source;
   end Move;

   procedure Move
     (Source       : in out Pointer_Array;
      Source_From  : Index_Type'Base;
      Source_Up_To : Index_Type'Base;
      Target       : in out Pointer_Array;
      Target_From  : Index_Type'Base;
      Target_Up_To : Index_Type'Base)
   is
      pragma Unmodified (Source);
      --  The elements moved out of Source are poisoned in the
      --  model, so Source is in out even though the copy below
      --  only reads it.
   begin
      Target (Target_From .. Target_Up_To) :=
        Source (Source_From .. Source_Up_To);
   end Move;

   --------------
   -- Relocate --
   --------------

   procedure Relocate
     (A : in out Pointer_Array; Source : Index_Type; Target : Index_Type) is
   begin
      A (Target) := A (Source);
   end Relocate;

   --------------
   -- Relocate --
   --------------

   procedure Relocate
     (A            : in out Pointer_Array;
      Source_From  : Index_Type'Base;
      Source_Up_To : Index_Type'Base;
      Target_From  : Index_Type'Base;
      Target_Up_To : Index_Type'Base) is
   begin
      A (Target_From .. Target_Up_To) := A (Source_From .. Source_Up_To);
   end Relocate;

end SPARK.Pointers.Poisoned.Pointers.Array_Operations;
