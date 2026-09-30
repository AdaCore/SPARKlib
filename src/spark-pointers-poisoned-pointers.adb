--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Ada.Unchecked_Conversion;
with Ada.Unchecked_Deallocation;

package body SPARK.Pointers.Poisoned.Pointers
  with SPARK_Mode => Off
is

   -----------------------
   -- Handle_Operations --
   -----------------------

   package body Handle_Operations is

      function Pointer_To_Handle is new
        Ada.Unchecked_Conversion (Pointer, Handle);

      ------------------------
      -- Constant_Reference --
      ------------------------

      function Constant_Reference
        (H : aliased Handle) return not null access constant Pointer
      is
         Result : aliased constant Pointer
         with Import, Address => H'Address;
      begin
         return Result'Unchecked_Access;
      end Constant_Reference;

      -------------------
      -- Create_Handle --
      -------------------

      function Create_Handle (X : Input) return Handle
      is (Pointer_To_Handle (Create_Pointer (X)))
      with SPARK_Mode => Off;

      -----------------
      -- Null_Handle --
      -----------------

      function Null_Handle return Handle
      is (Pointer_To_Handle (Null_Pointer));

      ---------------
      -- Reference --
      ---------------

      function Reference
        (H : aliased in out Handle) return not null access Pointer
      is
         Result : aliased Pointer
         with Import, Address => H'Address;
      begin
         return Result'Unchecked_Access;
      end Reference;

   end Handle_Operations;

   ----------------------
   -- Array_Operations --
   ----------------------

   package body Array_Operations
     with SPARK_Mode => Off
   is

      ----------
      -- Move --
      ----------

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

   end Array_Operations;

   ---------------------
   -- Copy_Operations --
   ---------------------

   package body Copy_Operations
     with SPARK_Mode => Off
   is

      ------------
      -- Assign --
      ------------

      procedure Assign (P : in out Pointer; O : Object) is
      begin
         P.Value.all := Copy (O);
      end Assign;

      -----------------
      -- Create_Copy --
      -----------------

      function Create_Copy (O : Object) return Pointer
      is (Value => new Object'(Copy (O)));

      -----------
      -- Deref --
      -----------

      function Deref (P : Pointer) return Object
      is (Copy (P.Value.all));

   end Copy_Operations;

   ------------------------
   -- Constant_Reference --
   ------------------------

   function Constant_Reference
     (P : Readable_Pointer) return not null access constant Object is
   begin
      return P.Value;
   end Constant_Reference;

   ------------
   -- Create --
   ------------

   function Create (X : Input) return Pointer
   is (Value => new Object'(Create_Object (X)))
   with SPARK_Mode => Off;

   --------------------
   -- Extensional_Eq --
   --------------------

   function Extensional_Eq (X, Y : Pointer) return Boolean
   is (Logical_Eq (X, Y));

   ------------------
   -- Is_Reclaimed --
   ------------------

   function Is_Reclaimed (P : Pointer) return Boolean
   is (Is_Poisoned (P) or else P = Null_Pointer);

   ----------
   -- Move --
   ----------

   procedure Move (Source : in out Pointer; Target : in out Pointer) is
   begin
      Target := Source;
   end Move;

   -------------
   -- Reclaim --
   -------------

   procedure Reclaim (P : in out Pointer) is
      procedure Free is new Ada.Unchecked_Deallocation (Object, Object_Access);
   begin
      Free (P.Value);
   end Reclaim;

   ---------------
   -- Reference --
   ---------------

   function Reference
     (P : in out Readable_Pointer) return not null access Object is
   begin
      return P.Value;
   end Reference;

   ----------
   -- Take --
   ----------

   function Take (Source : in out Pointer) return Pointer is
   begin
      return Source;
   end Take;

end SPARK.Pointers.Poisoned.Pointers;
