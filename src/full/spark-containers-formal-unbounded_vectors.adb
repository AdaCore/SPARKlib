--
--  Copyright (C) 2022-2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with Ada.Unchecked_Deallocation;

with System;
use type System.Address;

package body SPARK.Containers.Formal.Unbounded_Vectors
  with SPARK_Mode => Off
is
   use type Element_Array_Access;

   --  Calls to Ops pass array storage and scalar controls separately. If an
   --  element allocation raises Storage_Error, array updates can remain while
   --  scalar out parameters are not copied back. No exceptional copy-back or
   --  rollback is provided, as recovery from Storage_Error is not supported.

   -----------------------
   -- Local_Subprograms --
   -----------------------

   function To_Array_Index (Index : Index_Type) return Array_Index;

   procedure Free_Element_Array is new
     Ada.Unchecked_Deallocation (Element_Array, Element_Array_Access);

   function Length_Internal (Container : Vector) return Capacity_Range;
   --  Internal version of Length without a postcondition calling Model

   package Vector_Model is new Ops.Generic_Model (Formal_Model.M);

   ---------
   -- "=" --
   ---------

   function "=" (Left : Vector; Right : Vector) return Boolean is
   begin
      if Left'Address = Right'Address then
         return True;
      end if;

      if Left.Elements = null then
         return Is_Empty (Right);
      elsif Right.Elements = null then
         return Is_Empty (Left);
      end if;

      return
        Ops.Equal
          (Left.Elements.all, Left.Last, Right.Elements.all, Right.Last);
   end "=";

   ------------
   -- Adjust --
   ------------

   procedure Adjust (V : in out Vector) is
      Dest : Element_Array_Access;
      L    : constant Count_Type := Length_Internal (V);
   begin
      if V.Elements = null then
         return;
      end if;

      Dest := new Element_Array (1 .. V.Elements'Length);
      Indefinite_Ops.Copy (Dest (1 .. L), V.Elements (1 .. L));
      V.Elements := Dest;
   end Adjust;

   ------------
   -- Append --
   ------------

   procedure Append (Container : in out Vector; New_Item : Element_Type) is
   begin
      Append (Container, New_Item, 1);
   end Append;

   procedure Append
     (Container : in out Vector; New_Item : Element_Type; Count : Count_Type)
   is
   begin
      if Count = 0 then
         return;
      end if;

      if Container.Last >= Index_Type'Last then
         raise Constraint_Error with "vector is already at its maximum length";
      end if;

      Insert (Container, Container.Last + 1, New_Item, Count);
   end Append;

   -------------------
   -- Append_Vector --
   -------------------

   procedure Append_Vector (Container : in out Vector; New_Item : Vector) is
   begin
      if Is_Empty (New_Item) then
         return;
      end if;

      if Container.Last >= Index_Type'Last then
         raise Constraint_Error with "vector is already at its maximum length";
      end if;

      Insert_Vector (Container, Container.Last + 1, New_Item);
   end Append_Vector;

   ------------
   -- Assign --
   ------------

   procedure Assign (Target : in out Vector; Source : Vector) is
      N : constant Count_Type := Length_Internal (Source);
   begin
      if Target'Address = Source'Address then
         return;
      end if;

      if Target.Elements /= null then
         Ops.Clear (Target.Elements.all, Target.Last);
      end if;

      if N = 0 then
         return;
      end if;

      if Target.Elements = null or else Target.Elements'Length < N then
         Indefinite_Ops.Resize (Target.Elements, Target.Last, N);
      end if;

      Ops.Assign
        (Target.Elements.all, Target.Last, Source.Elements.all, Source.Last);
   end Assign;

   -----------
   -- Clear --
   -----------

   procedure Clear (Container : in out Vector) is
   begin
      if Container.Elements /= null then
         Ops.Clear (Container.Elements.all, Container.Last);
      end if;
   end Clear;

   ------------------------
   -- Constant_Reference --
   ------------------------

   function Constant_Reference
     (Container : Vector; Index : Extended_Index)
      return not null access constant Element_Type is
   begin
      if Index > Container.Last then
         raise Constraint_Error with "Index is out of range";
      end if;

      return
        Cells.Constant_Reference (Container.Elements (To_Array_Index (Index)));
   end Constant_Reference;

   --------------
   -- Contains --
   --------------

   function Contains (Container : Vector; Item : Element_Type) return Boolean
   is
   begin
      return Find_Index (Container, Item) /= No_Index;
   end Contains;

   ----------
   -- Copy --
   ----------

   function Copy (Source : Vector) return Vector is
   begin
      return Target : Vector do
         Assign (Target, Source);
      end return;
   end Copy;

   ------------
   -- Delete --
   ------------

   procedure Delete (Container : in out Vector; Index : Extended_Index) is
   begin
      Delete (Container, Index, 1);
   end Delete;

   procedure Delete
     (Container : in out Vector; Index : Extended_Index; Count : Count_Type) is
   begin
      Ops.Check_Deletion (Container.Last, Index);
      if Container.Elements /= null then
         Ops.Delete_Internal
           (Container.Elements.all, Container.Last, Index, Count);
      end if;
   end Delete;

   ------------------
   -- Delete_First --
   ------------------

   procedure Delete_First (Container : in out Vector) is
   begin
      Delete_First (Container, 1);
   end Delete_First;

   procedure Delete_First (Container : in out Vector; Count : Count_Type) is
   begin
      if Container.Elements /= null then
         Ops.Delete_First (Container.Elements.all, Container.Last, Count);
      end if;
   end Delete_First;

   -----------------
   -- Delete_Last --
   -----------------

   procedure Delete_Last (Container : in out Vector) is
   begin
      Delete_Last (Container, 1);
   end Delete_Last;

   procedure Delete_Last (Container : in out Vector; Count : Count_Type) is
   begin
      if Container.Elements /= null then
         Ops.Delete_Last (Container.Elements.all, Container.Last, Count);
      end if;
   end Delete_Last;

   -------------
   -- Element --
   -------------

   function Element
     (Container : Vector; Index : Extended_Index) return Element_Type is
   begin
      if Container.Elements = null then
         raise Constraint_Error with "Index is out of range";
      end if;

      return Ops.Element (Container.Elements.all, Container.Last, Index);
   end Element;

   --------------
   -- Finalize --
   --------------

   procedure Finalize (V : in out Vector) is
   begin
      if V.Elements = null then
         return;
      end if;

      Ops.Clear (V.Elements.all, V.Last);
      Free_Element_Array (V.Elements);
   end Finalize;

   ----------------
   -- Find_Index --
   ----------------

   function Find_Index
     (Container : Vector;
      Item      : Element_Type;
      Index     : Index_Type := Index_Type'First) return Extended_Index is
   begin
      if Container.Elements = null then
         return No_Index;
      end if;

      return
        Ops.Find_Index (Container.Elements.all, Container.Last, Item, Index);
   end Find_Index;

   -------------------
   -- First_Element --
   -------------------

   function First_Element (Container : Vector) return Element_Type is
   begin
      if Container.Elements = null then
         raise Constraint_Error with "Container is empty";
      else
         return Ops.First_Element (Container.Elements.all, Container.Last);
      end if;
   end First_Element;

   -----------------
   -- First_Index --
   -----------------

   function First_Index (Container : Vector) return Index_Type is
      pragma Unreferenced (Container);
   begin
      return Index_Type'First;
   end First_Index;

   ------------------
   -- Formal_Model --
   ------------------

   package body Formal_Model is

      -------------------------
      -- M_Elements_In_Union --
      -------------------------

      function M_Elements_In_Union
        (Container : M.Sequence; Left : M.Sequence; Right : M.Sequence)
         return Boolean
      renames Vector_Model.M_Elements_In_Union;

      -------------------------
      -- M_Elements_Included --
      -------------------------

      function M_Elements_Included
        (Left  : M.Sequence;
         L_Fst : Index_Type := Index_Type'First;
         L_Lst : Extended_Index;
         Right : M.Sequence;
         R_Fst : Index_Type := Index_Type'First;
         R_Lst : Extended_Index) return Boolean is
      begin
         return
           Vector_Model.M_Elements_Included
             (Left, L_Fst, L_Lst, Right, R_Fst, R_Lst);
      end M_Elements_Included;

      -------------------------
      -- M_Elements_Reversed --
      -------------------------

      function M_Elements_Reversed
        (Left : M.Sequence; Right : M.Sequence) return Boolean
      renames Vector_Model.M_Elements_Reversed;

      ------------------------
      -- M_Elements_Swapped --
      ------------------------

      function M_Elements_Swapped
        (Left : M.Sequence; Right : M.Sequence; X : Index_Type; Y : Index_Type)
         return Boolean
      renames Vector_Model.M_Elements_Swapped;

      -----------
      -- Model --
      -----------

      function Model (Container : Vector) return M.Sequence is
      begin
         if Container.Elements = null then
            return M.Empty_Sequence;
         end if;

         return Vector_Model.Model (Container.Elements.all, Container.Last);
      end Model;

   end Formal_Model;

   ---------------------
   -- Generic_Sorting --
   ---------------------

   package body Generic_Sorting
     with SPARK_Mode => Off
   is

      package Sorting is new Ops.Generic_Sorting ("<");

      ------------------
      -- Formal_Model --
      ------------------

      package body Formal_Model is
         package Model_Sorting is new Vector_Model.Generic_Sorting ("<");

         -----------------------
         -- M_Elements_Sorted --
         -----------------------

         function M_Elements_Sorted (Container : M.Sequence) return Boolean
         renames Model_Sorting.M_Elements_Sorted;
      end Formal_Model;

      ---------------
      -- Is_Sorted --
      ---------------

      function Is_Sorted (Container : Vector) return Boolean is
      begin
         if Container.Elements = null then
            return True;
         end if;

         return Sorting.Is_Sorted (Container.Elements.all, Container.Last);
      end Is_Sorted;

      -----------
      -- Merge --
      -----------

      procedure Merge (Target : in out Vector; Source : in out Vector) is
         I : constant Count_Type := Length_Internal (Target);
         N : constant Count_Type := Length_Internal (Source);
      begin
         if Target'Address = Source'Address then
            raise Program_Error with "Target and Source denote same container";
         end if;

         if N = 0 then
            return;
         end if;

         if I = 0 then
            Move (Target => Target, Source => Source);
            return;
         end if;

         if Count_Type'Base (Last_Count) - I < N then
            raise Constraint_Error with "Source too large for Target";
         end if;

         if Target.Elements'Length < I + N then
            Indefinite_Ops.Resize (Target.Elements, Target.Last, I + N);
         end if;

         Sorting.Merge
           (Target.Elements.all,
            Target.Last,
            Source.Elements.all,
            Source.Last);
      end Merge;

      ----------
      -- Sort --
      ----------

      procedure Sort (Container : in out Vector) is
      begin
         if Container.Last <= Index_Type'First then
            return;
         end if;

         Sorting.Sort (Container.Elements.all, Container.Last);
      end Sort;

   end Generic_Sorting;

   -----------------
   -- Has_Element --
   -----------------

   function Has_Element
     (Container : Vector; Position : Extended_Index) return Boolean is
   begin
      return Position in First_Index (Container) .. Last_Index (Container);
   end Has_Element;

   ------------
   -- Insert --
   ------------

   procedure Insert
     (Container : in out Vector;
      Before    : Extended_Index;
      New_Item  : Element_Type) is
   begin
      Insert (Container, Before, New_Item, 1);
   end Insert;

   procedure Insert
     (Container : in out Vector;
      Before    : Extended_Index;
      New_Item  : Element_Type;
      Count     : Count_Type)
   is
      New_Length : Count_Type;
   begin
      Ops.Check_Insertion (Container.Last, Before, Count, New_Length);
      if Count = 0 then
         return;
      end if;

      if Container.Elements = null
        or else Container.Elements'Length < New_Length
      then
         Indefinite_Ops.Resize
           (Container.Elements, Container.Last, New_Length);
      end if;

      Ops.Insert_Internal
        (Container.Elements.all, Container.Last, Before, New_Item, Count);
   end Insert;

   -------------------
   -- Insert_Vector --
   -------------------

   procedure Insert_Vector
     (Container : in out Vector; Before : Extended_Index; New_Item : Vector)
   is
      N          : constant Count_Type := Length_Internal (New_Item);
      New_Length : Count_Type;
   begin
      if Container'Address = New_Item'Address then
         raise Program_Error
           with "Container and New_Item denote same container";
      end if;

      Ops.Check_Insertion (Container.Last, Before, N, New_Length);
      if N = 0 then
         return;
      end if;

      if Container.Elements = null
        or else Container.Elements'Length < New_Length
      then
         Indefinite_Ops.Resize
           (Container.Elements, Container.Last, New_Length);
      end if;

      Ops.Insert_Slice
        (Container.Elements.all,
         Container.Last,
         Before,
         New_Item.Elements.all,
         New_Item.Last);
   end Insert_Vector;

   --------------
   -- Is_Empty --
   --------------

   function Is_Empty (Container : Vector) return Boolean is
   begin
      return Last_Index (Container) < Index_Type'First;
   end Is_Empty;

   ------------------
   -- Last_Element --
   ------------------

   function Last_Element (Container : Vector) return Element_Type is
   begin
      if Container.Elements = null then
         raise Constraint_Error with "Container is empty";
      else
         return Ops.Last_Element (Container.Elements.all, Container.Last);
      end if;
   end Last_Element;

   ----------------
   -- Last_Index --
   ----------------

   function Last_Index (Container : Vector) return Extended_Index is
   begin
      return Container.Last;
   end Last_Index;

   ------------
   -- Length --
   ------------

   function Length (Container : Vector) return Capacity_Range is
   begin
      return Length_Internal (Container);
   end Length;

   ---------------------
   -- Length_Internal --
   ---------------------

   function Length_Internal (Container : Vector) return Capacity_Range
   is (Storage.To_Array_Index (Container.Last));

   ----------
   -- Move --
   ----------

   procedure Move (Target : in out Vector; Source : in out Vector) is
   begin
      if Target'Address = Source'Address then
         return;
      end if;

      if Target.Elements /= null then
         Ops.Clear (Target.Elements.all, Target.Last);
         Free_Element_Array (Target.Elements);
      end if;

      Target.Elements := Source.Elements;
      Target.Last := Source.Last;

      Source.Elements := null;
      Source.Last := No_Index;
   end Move;

   -------------
   -- Prepend --
   -------------

   procedure Prepend (Container : in out Vector; New_Item : Element_Type) is
   begin
      Prepend (Container, New_Item, 1);
   end Prepend;

   procedure Prepend
     (Container : in out Vector; New_Item : Element_Type; Count : Count_Type)
   is
   begin
      Insert (Container, Index_Type'First, New_Item, Count);
   end Prepend;

   --------------------
   -- Prepend_Vector --
   --------------------

   procedure Prepend_Vector (Container : in out Vector; New_Item : Vector) is
   begin
      Insert_Vector (Container, Index_Type'First, New_Item);
   end Prepend_Vector;

   ---------------
   -- Reference --
   ---------------

   function Reference
     (Container : Vector; Index : Index_Type)
      return not null access Element_Type is
   begin
      if Index > Container.Last then
         raise Constraint_Error with "Index is out of range";
      end if;

      return Cells.Reference (Container.Elements (To_Array_Index (Index)));
   end Reference;

   ---------------------
   -- Replace_Element --
   ---------------------

   procedure Replace_Element
     (Container : in out Vector; Index : Index_Type; New_Item : Element_Type)
   is
   begin
      if Index > Container.Last then
         raise Constraint_Error with "Index is out of range";
      end if;

      Ops.Replace_Element
        (Container.Elements.all, Container.Last, Index, New_Item);
   end Replace_Element;

   ----------------------
   -- Reverse_Elements --
   ----------------------

   procedure Reverse_Elements (Container : in out Vector) is
   begin
      if Container.Elements /= null then
         Ops.Reverse_Elements (Container.Elements.all, Container.Last);
      end if;
   end Reverse_Elements;

   ------------------------
   -- Reverse_Find_Index --
   ------------------------

   function Reverse_Find_Index
     (Container : Vector;
      Item      : Element_Type;
      Index     : Index_Type := Index_Type'Last) return Extended_Index is
   begin
      if Container.Elements = null then
         return No_Index;
      end if;

      return
        Ops.Reverse_Find_Index
          (Container.Elements.all, Container.Last, Item, Index);
   end Reverse_Find_Index;

   ----------
   -- Swap --
   ----------

   procedure Swap (Container : in out Vector; I : Index_Type; J : Index_Type)
   is
   begin
      if I > Container.Last then
         raise Constraint_Error with "I index is out of range";
      end if;

      if J > Container.Last then
         raise Constraint_Error with "J index is out of range";
      end if;

      Ops.Swap (Container.Elements.all, Container.Last, I, J);
   end Swap;

   --------------------
   -- To_Array_Index --
   --------------------

   function To_Array_Index (Index : Index_Type) return Array_Index
   is (Storage.To_Array_Index (Index));

   ---------------
   -- To_Vector --
   ---------------

   function To_Vector
     (New_Item : Element_Type; Length : Capacity_Range) return Vector is
   begin
      if Length = 0 then
         return Empty_Vector;
      end if;

      declare
         Vec : Vector;

      begin
         Append (Vec, New_Item, Length);

         return Vec;
      end;
   end To_Vector;

end SPARK.Containers.Formal.Unbounded_Vectors;
