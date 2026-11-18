--
--  Copyright (C) 2004-2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with SPARK.Containers.Formal.Vectors.Impl;

package body SPARK.Containers.Formal.Vectors
  with SPARK_Mode => Off
is

   package Vector_Impl is new SPARK.Containers.Formal.Vectors.Impl;

   ---------
   -- "=" --
   ---------

   function "=" (Left : Vector; Right : Vector) return Boolean
   is (Vector_Impl."=" (Left, Right));

   ------------
   -- Append --
   ------------

   procedure Append (Container : in out Vector; New_Item : Element_Type)
   renames Vector_Impl.Append;

   procedure Append
     (Container : in out Vector; New_Item : Element_Type; Count : Count_Type)
   renames Vector_Impl.Append;

   -------------------
   -- Append_Vector --
   -------------------

   procedure Append_Vector (Container : in out Vector; New_Item : Vector)
   renames Vector_Impl.Append_Vector;

   ------------
   -- Assign --
   ------------

   procedure Assign (Target : in out Vector; Source : Vector)
   renames Vector_Impl.Assign;

   --------------
   -- Capacity --
   --------------

   function Capacity (Container : Vector) return Capacity_Range
   renames Vector_Impl.Capacity;

   -----------
   -- Clear --
   -----------

   procedure Clear (Container : in out Vector) renames Vector_Impl.Clear;

   ------------------------
   -- Constant_Reference --
   ------------------------

   function Constant_Reference
     (Container : aliased Vector; Index : Index_Type)
      return not null access constant Element_Type
   renames Vector_Impl.Constant_Reference;

   --------------
   -- Contains --
   --------------

   function Contains (Container : Vector; Item : Element_Type) return Boolean
   renames Vector_Impl.Contains;

   ----------
   -- Copy --
   ----------

   function Copy
     (Source : Vector; Capacity : Capacity_Range := 0) return Vector
   renames Vector_Impl.Copy;

   ------------
   -- Delete --
   ------------

   procedure Delete (Container : in out Vector; Index : Extended_Index)
   renames Vector_Impl.Delete;

   procedure Delete
     (Container : in out Vector; Index : Extended_Index; Count : Count_Type)
   renames Vector_Impl.Delete;

   ------------------
   -- Delete_First --
   ------------------

   procedure Delete_First (Container : in out Vector)
   renames Vector_Impl.Delete_First;

   procedure Delete_First (Container : in out Vector; Count : Count_Type)
   renames Vector_Impl.Delete_First;

   -----------------
   -- Delete_Last --
   -----------------

   procedure Delete_Last (Container : in out Vector)
   renames Vector_Impl.Delete_Last;

   procedure Delete_Last (Container : in out Vector; Count : Count_Type)
   renames Vector_Impl.Delete_Last;

   -------------
   -- Element --
   -------------

   function Element
     (Container : Vector; Index : Extended_Index) return Element_Type
   renames Vector_Impl.Element;

   ------------------
   -- Empty_Vector --
   ------------------

   function Empty_Vector (Capacity : Count_Type := 10) return Vector
   renames Vector_Impl.Empty_Vector;

   ----------------
   -- Find_Index --
   ----------------

   function Find_Index
     (Container : Vector;
      Item      : Element_Type;
      Index     : Index_Type := Index_Type'First) return Extended_Index
   renames Vector_Impl.Find_Index;

   -------------------
   -- First_Element --
   -------------------

   function First_Element (Container : Vector) return Element_Type
   renames Vector_Impl.First_Element;

   -----------------
   -- First_Index --
   -----------------

   function First_Index (Container : Vector) return Index_Type
   renames Vector_Impl.First_Index;

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
      renames Vector_Impl.Vector_Model.M_Elements_In_Union;

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
           Vector_Impl.Vector_Model.M_Elements_Included
             (Left, L_Fst, L_Lst, Right, R_Fst, R_Lst);
      end M_Elements_Included;

      -------------------------
      -- M_Elements_Reversed --
      -------------------------

      function M_Elements_Reversed
        (Left : M.Sequence; Right : M.Sequence) return Boolean
      renames Vector_Impl.Vector_Model.M_Elements_Reversed;

      ------------------------
      -- M_Elements_Swapped --
      ------------------------

      function M_Elements_Swapped
        (Left : M.Sequence; Right : M.Sequence; X : Index_Type; Y : Index_Type)
         return Boolean
      renames Vector_Impl.Vector_Model.M_Elements_Swapped;

      -----------
      -- Model --
      -----------

      function Model (Container : Vector) return M.Sequence
      renames Vector_Impl.Model;

   end Formal_Model;

   ---------------------
   -- Generic_Sorting --
   ---------------------

   package body Generic_Sorting
     with SPARK_Mode => Off
   is
      package Sorting_Impl is new Vector_Impl.Generic_Sorting ("<");

      ------------------
      -- Formal_Model --
      ------------------

      package body Formal_Model is
         package Model_Sorting is new
           Vector_Impl.Vector_Model.Generic_Sorting ("<");

         -----------------------
         -- M_Elements_Sorted --
         -----------------------

         function M_Elements_Sorted (Container : M.Sequence) return Boolean
         renames Model_Sorting.M_Elements_Sorted;
      end Formal_Model;

      ---------------
      -- Is_Sorted --
      ---------------

      function Is_Sorted (Container : Vector) return Boolean
      renames Sorting_Impl.Is_Sorted;

      -----------
      -- Merge --
      -----------

      procedure Merge (Target : in out Vector; Source : in out Vector)
      renames Sorting_Impl.Merge;

      ----------
      -- Sort --
      ----------

      procedure Sort (Container : in out Vector) renames Sorting_Impl.Sort;

   end Generic_Sorting;

   -----------------
   -- Has_Element --
   -----------------

   function Has_Element
     (Container : Vector; Position : Extended_Index) return Boolean
   renames Vector_Impl.Has_Element;

   ------------
   -- Insert --
   ------------

   procedure Insert
     (Container : in out Vector;
      Before    : Extended_Index;
      New_Item  : Element_Type)
   renames Vector_Impl.Insert;

   procedure Insert
     (Container : in out Vector;
      Before    : Extended_Index;
      New_Item  : Element_Type;
      Count     : Count_Type)
   renames Vector_Impl.Insert;

   -------------------
   -- Insert_Vector --
   -------------------

   procedure Insert_Vector
     (Container : in out Vector; Before : Extended_Index; New_Item : Vector)
   renames Vector_Impl.Insert_Vector;

   --------------
   -- Is_Empty --
   --------------

   function Is_Empty (Container : Vector) return Boolean
   renames Vector_Impl.Is_Empty;

   ----------------
   -- Iter_First --
   ----------------

   function Iter_First (Container : Vector) return Extended_Index
   renames Vector_Impl.Iter_First;

   ----------------------
   -- Iter_Has_Element --
   ----------------------

   function Iter_Has_Element
     (Container : Vector; Position : Extended_Index) return Boolean
   renames Vector_Impl.Iter_Has_Element;

   ---------------
   -- Iter_Next --
   ---------------

   function Iter_Next
     (Container : Vector; Position : Extended_Index) return Extended_Index
   renames Vector_Impl.Iter_Next;

   ------------------
   -- Last_Element --
   ------------------

   function Last_Element (Container : Vector) return Element_Type
   renames Vector_Impl.Last_Element;

   ----------------
   -- Last_Index --
   ----------------

   function Last_Index (Container : Vector) return Extended_Index
   renames Vector_Impl.Last_Index;

   ------------
   -- Length --
   ------------

   function Length (Container : Vector) return Capacity_Range
   renames Vector_Impl.Length;

   ----------
   -- Move --
   ----------

   procedure Move (Target : in out Vector; Source : in out Vector)
   renames Vector_Impl.Move;

   -------------
   -- Prepend --
   -------------

   procedure Prepend (Container : in out Vector; New_Item : Element_Type)
   renames Vector_Impl.Prepend;

   procedure Prepend
     (Container : in out Vector; New_Item : Element_Type; Count : Count_Type)
   renames Vector_Impl.Prepend;

   --------------------
   -- Prepend_Vector --
   --------------------

   procedure Prepend_Vector (Container : in out Vector; New_Item : Vector)
   renames Vector_Impl.Prepend_Vector;

   ---------------
   -- Reference --
   ---------------

   function Reference
     (Container : aliased in out Vector; Index : Index_Type)
      return not null access Element_Type
   renames Vector_Impl.Reference;

   ---------------------
   -- Replace_Element --
   ---------------------

   procedure Replace_Element
     (Container : in out Vector; Index : Index_Type; New_Item : Element_Type)
   renames Vector_Impl.Replace_Element;

   ----------------------
   -- Reserve_Capacity --
   ----------------------

   procedure Reserve_Capacity
     (Container : in out Vector; Capacity : Capacity_Range)
   renames Vector_Impl.Reserve_Capacity;

   ----------------------
   -- Reverse_Elements --
   ----------------------

   procedure Reverse_Elements (Container : in out Vector)
   renames Vector_Impl.Reverse_Elements;

   ------------------------
   -- Reverse_Find_Index --
   ------------------------

   function Reverse_Find_Index
     (Container : Vector;
      Item      : Element_Type;
      Index     : Index_Type := Index_Type'Last) return Extended_Index
   renames Vector_Impl.Reverse_Find_Index;

   ----------
   -- Swap --
   ----------

   procedure Swap (Container : in out Vector; I : Index_Type; J : Index_Type)
   renames Vector_Impl.Swap;

   ---------------
   -- To_Vector --
   ---------------

   function To_Vector
     (New_Item : Element_Type; Length : Capacity_Range) return Vector
   renames Vector_Impl.To_Vector;

end SPARK.Containers.Formal.Vectors;
