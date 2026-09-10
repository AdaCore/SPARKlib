--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Ada.Unchecked_Conversion;

package body SPARK.Pointers.Poisoned.Views
  with SPARK_Mode => Off
is

   ----------------------
   -- Array_Operations --
   ----------------------

   package body Array_Operations
     with SPARK_Mode => Off
   is

      --------------
      -- Get_View --
      --------------

      function Get_View
        (A : aliased in out Object_Array) return not null access Readable_Array
      is
         type Object_Array_Acc is access all Object_Array;
         type Readable_Array_Acc is access all Readable_Array;
         function To_View_Array is new
           Ada.Unchecked_Conversion (Object_Array_Acc, Readable_Array_Acc);
      begin
         return To_View_Array (A'Access).all'Unchecked_Access;
      end Get_View;

      ----------
      -- Move --
      ----------

      procedure Move
        (Source       : in out View_Array;
         Source_From  : Index_Type'Base;
         Source_Up_To : Index_Type'Base;
         Target       : in out View_Array;
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
        (A : in out View_Array; Source : Index_Type; Target : Index_Type) is
      begin
         A (Target) := A (Source);
      end Relocate;

      --------------
      -- Relocate --
      --------------

      procedure Relocate
        (A            : in out View_Array;
         Source_From  : Index_Type'Base;
         Source_Up_To : Index_Type'Base;
         Target_From  : Index_Type'Base;
         Target_Up_To : Index_Type'Base) is
      begin
         A (Target_From .. Target_Up_To) := A (Source_From .. Source_Up_To);
      end Relocate;

   end Array_Operations;

   ------------------------
   -- Constant_Reference --
   ------------------------

   function Constant_Reference
     (V : aliased Readable_View) return not null access constant Object
   is
      type View_Access is access constant Readable_View;
      type Object_Access is access constant Object;
      function From_View is new
        Ada.Unchecked_Conversion (View_Access, Object_Access);
   begin
      return From_View (V'Access).all'Unchecked_Access;
   end Constant_Reference;

   ----------
   -- Copy --
   ----------

   function Copy (V : View) return View
   is (V);

   ------------
   -- Create --
   ------------

   function Create (X : Input) return View
   is (Value => Create_Object (X));

   --------------------
   -- Extensional_Eq --
   --------------------

   function Extensional_Eq (X, Y : View) return Boolean
   is (Logical_Eq (X, Y));

   --------------
   -- Get_View --
   --------------

   function Get_View
     (X : aliased in out Object) return not null access Readable_View
   is
      type View_Access is access all Readable_View;
      type Object_Access is access all Object;
      function To_View is new
        Ada.Unchecked_Conversion (Object_Access, View_Access);
   begin
      return To_View (X'Access).all'Unchecked_Access;
   end Get_View;

   ------------------
   -- Is_Reclaimed --
   ------------------

   function Is_Reclaimed (V : View) return Boolean
   is (Is_Poisoned (V) or else Is_Reclaimed (Peek (V)));

   ----------
   -- Move --
   ----------

   procedure Move (Source : in out View; Target : in out View) is
   begin
      Target := Source;
   end Move;

   procedure Move (Source : in out View; Target : in out Object) is
   begin
      Target := Source.Value;
   end Move;

   ---------------
   -- Reference --
   ---------------

   function Reference
     (V : aliased in out Readable_View) return not null access Object
   is
      type View_Access is access all Readable_View;
      type Object_Access is access all Object;
      function From_View is new
        Ada.Unchecked_Conversion (View_Access, Object_Access);
   begin
      return From_View (V'Access).all'Unchecked_Access;
   end Reference;

   ----------
   -- Take --
   ----------

   function Take (Source : in out View) return View is
   begin
      return Source;
   end Take;

   function Take (Source : in out View) return Object is
   begin
      return Source.Value;
   end Take;

end SPARK.Pointers.Poisoned.Views;
