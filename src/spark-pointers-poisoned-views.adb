--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Ada.Unchecked_Conversion;

package body SPARK.Pointers.Poisoned.Views
  with SPARK_Mode => Off
is

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
