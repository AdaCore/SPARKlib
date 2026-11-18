--
--  Copyright (C) 2004-2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

package body SPARK.Containers.Formal.Vectors.Impl
  with SPARK_Mode
is

   package Address_Comparisons is new
     SPARK.Containers.Formal.Impl.Address_Space.Address_Comparison (Vector);

   function Same_Object (Left, Right : Vector) return Boolean
   renames Address_Comparisons.Same_Object;

   subtype Int is Long_Long_Integer;

   procedure Check_Aliasing (Container, New_Item : Vector)
   with Global => Address_State, Inline;
   --  Raise Program_Error if Container and New_Item are the same vector

   procedure Append
     (Elements : in out Elements_Array;
      Last     : in out Extended_Index;
      New_Item : Element_Type;
      Count    : Count_Type := 1)
   with
     Global     => null,
     Pre        =>
       (Static =>
          Elements'Last in Capacity_Range
          and then Ops.Valid_Elements (Elements, Last)),
     Exit_Cases =>
       (Exceeds_Last_Count (To_Array_Index (Last), Count)              =>
          (Exception_Raised => Constraint_Error),
        Exceeds_Capacity (To_Array_Index (Last), Elements'Last, Count) =>
          (Exception_Raised => Capacity_Error),
        others                                                         =>
          Normal_Return),
     Post       =>
       (Static =>
          Ops.Valid_Elements (Elements, Last)
          and then To_Array_Index (Last) = To_Array_Index (Last'Old) + Count),
     Inline;
   --  Append Count copies of New_Item, checking the length and capacity limits

   procedure Insert
     (Elements : in out Elements_Array;
      Last     : in out Extended_Index;
      Before   : Extended_Index;
      New_Item : Element_Type;
      Count    : Count_Type)
   with
     Global     => null,
     Pre        =>
       (Static =>
          Elements'Last in Capacity_Range
          and then Ops.Valid_Elements (Elements, Last)),
     Exit_Cases =>
       (not Valid_Index_For_Insertion (Last, Before)
        or Exceeds_Last_Count (To_Array_Index (Last), Count)               =>
          (Exception_Raised => Constraint_Error),
        Valid_Index_For_Insertion (Last, Before)
        and Exceeds_Capacity (To_Array_Index (Last), Elements'Last, Count) =>
          (Exception_Raised => Capacity_Error),
        others                                                             =>
          Normal_Return),
     Post       =>
       (Static =>
          Ops.Valid_Elements (Elements, Last)
          and then To_Array_Index (Last) = To_Array_Index (Last'Old) + Count),
     Inline;
   --  Insert Count copies of New_Item before Before, checking the insertion
   --  index, length, and capacity limits.

   procedure Insert_Vector
     (Elements    : in out Elements_Array;
      Last        : in out Extended_Index;
      Before      : Extended_Index;
      Source      : Elements_Array;
      Source_Last : Extended_Index)
   with
     Global     => null,
     Pre        =>
       (Static =>
          Elements'Last in Capacity_Range
          and then Ops.Valid_Elements (Elements, Last)
          and then Ops.Valid_Elements (Source, Source_Last)),
     Exit_Cases =>
       (not Valid_Index_For_Insertion (Last, Before)
        or
          Exceeds_Last_Count
            (To_Array_Index (Last), To_Array_Index (Source_Last)) =>
          (Exception_Raised => Constraint_Error),
        Valid_Index_For_Insertion (Last, Before)
        and
          Exceeds_Capacity
            (To_Array_Index (Last),
             Elements'Last,
             To_Array_Index (Source_Last))                        =>
          (Exception_Raised => Capacity_Error),
        others                                                    =>
          Normal_Return),
     Post       =>
       (Static =>
          Ops.Valid_Elements (Elements, Last)
          and then
            To_Array_Index (Last)
            = To_Array_Index (Last'Old) + To_Array_Index (Source_Last)),
     Inline;
   --  Insert the used prefix of Source before Before, checking the insertion
   --  index, length, and capacity limits.

   ---------
   -- "=" --
   ---------

   function "=" (Left, Right : Vector) return Boolean is
      Same : constant Boolean := Same_Object (Left, Right);
      --  Volatile read in a non-interfering context (object initialization)

   begin
      if Same then
         return True;
      end if;

      return Ops.Equal (Left.Elements, Left.Last, Right.Elements, Right.Last);
   end "=";

   ------------
   -- Append --
   ------------

   procedure Append (Container : in out Vector; New_Item : Element_Type) is
   begin
      Append (Container.Elements, Container.Last, New_Item);
   end Append;

   procedure Append
     (Container : in out Vector; New_Item : Element_Type; Count : Count_Type)
   is
   begin
      Append (Container.Elements, Container.Last, New_Item, Count);
   end Append;

   procedure Append
     (Elements : in out Elements_Array;
      Last     : in out Extended_Index;
      New_Item : Element_Type;
      Count    : Count_Type := 1) is
   begin
      if Count = 0 then
         return;
      end if;

      if Last >= Index_Type'Last then
         raise Constraint_Error with "vector is already at its maximum length";
      end if;

      Insert (Elements, Last, Last + 1, New_Item, Count);
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

      Check_Aliasing (Container, New_Item);
      Insert_Vector
        (Container.Elements,
         Container.Last,
         Container.Last + 1,
         New_Item.Elements,
         New_Item.Last);
   end Append_Vector;

   ------------
   -- Assign --
   ------------

   procedure Assign (Target : in out Vector; Source : Vector) is
      LS   : constant Capacity_Range := Length (Source);
      Same : constant Boolean := Same_Object (Target, Source);

   begin
      if Same then
         return;
      end if;

      if Target.Capacity < LS then
         raise Constraint_Error;
      end if;

      Ops.Clear (Target.Elements, Target.Last);
      Ops.Assign (Target.Elements, Target.Last, Source.Elements, Source.Last);
   end Assign;

   --------------
   -- Capacity --
   --------------

   function Capacity (Container : Vector) return Capacity_Range
   is (Container.Capacity);

   --------------------
   -- Check_Aliasing --
   --------------------

   procedure Check_Aliasing (Container, New_Item : Vector) is
      Same : constant Boolean := Same_Object (Container, New_Item);
   begin
      if Same then
         raise Program_Error
           with "Container and New_Item denote same container";
         pragma
           Annotate
             (GNATprove,
              Intentional,
              "exception might be raised",
              "callers pass an in out container and an in source, which "
              & "cannot alias in SPARK");
      end if;
   end Check_Aliasing;

   -----------
   -- Clear --
   -----------

   procedure Clear (Container : in out Vector) is
   begin
      Ops.Clear (Container.Elements, Container.Last);
   end Clear;

   ------------------------
   -- Constant_Reference --
   ------------------------

   function Constant_Reference
     (Container : aliased Vector; Index : Index_Type)
      return not null access constant Element_Type is
   begin
      if Index > Container.Last then
         raise Constraint_Error with "Index is out of range";
      end if;

      return Container.Elements (To_Array_Index (Index)).V'Access;
   end Constant_Reference;

   --------------
   -- Contains --
   --------------

   function Contains (Container : Vector; Item : Element_Type) return Boolean
   is
   begin
      return
        Ops.Find_Index (Container.Elements, Container.Last, Item) /= No_Index;
   end Contains;

   ----------
   -- Copy --
   ----------

   function Copy
     (Source : Vector; Capacity : Capacity_Range := 0) return Vector
   is
      LS : constant Capacity_Range := Length (Source);
      C  : Capacity_Range;

   begin
      if Capacity = 0 then
         C := LS;
      elsif Capacity >= LS then
         C := Capacity;
      else
         raise Capacity_Error with "Capacity too small";
      end if;

      declare
         Target_Capacity : constant Capacity_Range := C;
         --  Target_Capacity must be a constant: it is used as a subtype
         --  constraint below, which may not depend on a variable input in
         --  SPARK (E0007).
      begin
         return Target : Vector (Target_Capacity) do
            Ops.Assign
              (Target.Elements, Target.Last, Source.Elements, Source.Last);
         end return;
      end;
   end Copy;

   procedure Copy
     (Target : in out Storage.Elements_Array; Source : Storage.Elements_Array)
   is
   begin
      Target := Source;
   end Copy;

   ------------
   -- Delete --
   ------------

   procedure Delete (Container : in out Vector; Index : Extended_Index) is
   begin
      Ops.Check_Deletion (Container.Last, Index);
      Ops.Delete_Internal (Container.Elements, Container.Last, Index, 1);
   end Delete;

   procedure Delete
     (Container : in out Vector; Index : Extended_Index; Count : Count_Type) is
   begin
      Ops.Check_Deletion (Container.Last, Index);
      Ops.Delete_Internal (Container.Elements, Container.Last, Index, Count);
   end Delete;

   ------------------
   -- Delete_First --
   ------------------

   procedure Delete_First (Container : in out Vector) is
   begin
      Ops.Delete_First (Container.Elements, Container.Last);
   end Delete_First;

   procedure Delete_First (Container : in out Vector; Count : Count_Type) is
   begin
      Ops.Delete_First (Container.Elements, Container.Last, Count);
   end Delete_First;

   -----------------
   -- Delete_Last --
   -----------------

   procedure Delete_Last (Container : in out Vector) is
   begin
      Ops.Delete_Last (Container.Elements, Container.Last);
   end Delete_Last;

   procedure Delete_Last (Container : in out Vector; Count : Count_Type) is
   begin
      Ops.Delete_Last (Container.Elements, Container.Last, Count);
   end Delete_Last;

   -------------
   -- Element --
   -------------

   function Element
     (Container : Vector; Index : Extended_Index) return Element_Type is
   begin
      return Ops.Element (Container.Elements, Container.Last, Index);
   end Element;

   ------------------
   -- Empty_Vector --
   ------------------

   function Empty_Vector (Capacity : Count_Type := 10) return Vector is
   begin
      if Capacity > Last_Count then
         raise Constraint_Error with "last index is out of range";
      end if;
      return (Capacity => Capacity, others => <>);
   end Empty_Vector;

   --------------
   -- Exchange --
   --------------

   procedure Exchange
     (E : in out Storage.Elements_Array; I, J : Count_Type'Base) is
   begin
      if I = J then
         return;
      end if;

      declare
         EI : constant Element_Type := E (I).V;
      begin
         E (I).V := E (J).V;
         E (J).V := EI;
      end;
   end Exchange;

   ----------
   -- Fill --
   ----------

   procedure Fill (H : out Relaxed_Element; Item : Element_Type) is
   begin
      H.V := Item;
   end Fill;

   procedure Fill (E : in out Storage.Elements_Array; Item : Element_Type) is
   begin
      E := [others => (V => Item)];
   end Fill;

   ----------------
   -- Find_Index --
   ----------------

   function Find_Index
     (Container : Vector;
      Item      : Element_Type;
      Index     : Index_Type := Index_Type'First) return Extended_Index is
   begin
      return Ops.Find_Index (Container.Elements, Container.Last, Item, Index);
   end Find_Index;

   -------------------
   -- First_Element --
   -------------------

   function First_Element (Container : Vector) return Element_Type is
   begin
      return Ops.First_Element (Container.Elements, Container.Last);
   end First_Element;

   -----------------
   -- First_Index --
   -----------------

   function First_Index (Dummy_Container : Vector) return Index_Type
   is (Index_Type'First);

   ---------------------
   -- Generic_Sorting --
   ---------------------

   package body Generic_Sorting is

      package Sorting is new Ops.Generic_Sorting ("<");

      ---------------
      -- Is_Sorted --
      ---------------

      function Is_Sorted (Container : Vector) return Boolean is
      begin
         return Sorting.Is_Sorted (Container.Elements, Container.Last);
      end Is_Sorted;

      -----------
      -- Merge --
      -----------

      procedure Merge (Target : in out Vector; Source : in out Vector) is
         New_Length : Count_Type;
         Same       : constant Boolean := Same_Object (Target, Source);

      begin
         if Same then
            raise Program_Error with "Target and Source denote same container";
            pragma
              Annotate
                (GNATprove,
                 Intentional,
                 "exception might be raised",
                 "unreachable in SPARK: two in out parameters cannot alias, "
                 & "so Same_Object never holds here");
         end if;

         if Length (Source) = 0 then
            return;
         end if;

         if Length (Target) = 0 then
            if Length (Source) > Target.Capacity then
               raise Capacity_Error with "Capacity too small";
            end if;

         else
            if Target.Last >= Index_Type'Last then
               raise Constraint_Error
                 with "vector is already at its maximum length";
            end if;

            Ops.Check_Insertion
              (Target.Last, Target.Last + 1, Length (Source), New_Length);
            if New_Length > Target.Capacity then
               raise Capacity_Error with "New length is larger than capacity";
            end if;
         end if;

         Sorting.Merge
           (Target.Elements, Target.Last, Source.Elements, Source.Last);
      end Merge;

      ----------
      -- Sort --
      ----------

      procedure Sort (Container : in out Vector) is
      begin
         Sorting.Sort (Container.Elements, Container.Last);
      end Sort;

   end Generic_Sorting;

   -----------------
   -- Has_Element --
   -----------------

   function Has_Element
     (Container : Vector; Position : Extended_Index) return Boolean
   is (Position in Index_Type'First .. Container.Last);

   ------------
   -- Insert --
   ------------

   procedure Insert
     (Container : in out Vector;
      Before    : Extended_Index;
      New_Item  : Element_Type) is
   begin
      Insert (Container.Elements, Container.Last, Before, New_Item, 1);
   end Insert;

   procedure Insert
     (Container : in out Vector;
      Before    : Extended_Index;
      New_Item  : Element_Type;
      Count     : Count_Type) is
   begin
      Insert (Container.Elements, Container.Last, Before, New_Item, Count);
   end Insert;

   procedure Insert
     (Elements : in out Elements_Array;
      Last     : in out Extended_Index;
      Before   : Extended_Index;
      New_Item : Element_Type;
      Count    : Count_Type)
   is
      New_Length : Count_Type;

   begin
      Ops.Check_Insertion (Last, Before, Count, New_Length);

      --  Raise Capacity_Error if the new length exceeds the container's
      --  capacity.

      if New_Length > Elements'Last then
         raise Capacity_Error with "New length is larger than capacity";
      end if;

      Ops.Insert_Internal (Elements, Last, Before, New_Item, Count);
   end Insert;

   -------------------
   -- Insert_Vector --
   -------------------

   procedure Insert_Vector
     (Container : in out Vector; Before : Extended_Index; New_Item : Vector) is
   begin
      Check_Aliasing (Container, New_Item);
      Insert_Vector
        (Container.Elements,
         Container.Last,
         Before,
         New_Item.Elements,
         New_Item.Last);
   end Insert_Vector;

   procedure Insert_Vector
     (Elements    : in out Elements_Array;
      Last        : in out Extended_Index;
      Before      : Extended_Index;
      Source      : Elements_Array;
      Source_Last : Extended_Index)
   is
      N          : constant Count_Type := To_Array_Index (Source_Last);
      New_Length : Count_Type;

   begin
      Ops.Check_Insertion (Last, Before, N, New_Length);

      --  Raise Capacity_Error if the new length exceeds the container's
      --  capacity.

      if New_Length > Elements'Last then
         raise Capacity_Error with "New length is larger than capacity";
      end if;

      Ops.Insert_Slice (Elements, Last, Before, Source, Source_Last);
   end Insert_Vector;

   --------------
   -- Is_Empty --
   --------------

   function Is_Empty (Container : Vector) return Boolean
   is (Container.Last < Index_Type'First);

   ----------------
   -- Iter_First --
   ----------------

   function Iter_First (Dummy_Container : Vector) return Extended_Index
   is (Index_Type'First);

   ----------------------
   -- Iter_Has_Element --
   ----------------------

   function Iter_Has_Element
     (Container : Vector; Position : Extended_Index) return Boolean
   is (Position in Index_Type'First .. Container.Last);

   ---------------
   -- Iter_Next --
   ---------------

   function Iter_Next
     (Container : Vector; Position : Extended_Index) return Extended_Index
   is (if Position = Container.Last
       then No_Index
       else Extended_Index'Succ (Position));

   ------------------
   -- Last_Element --
   ------------------

   function Last_Element (Container : Vector) return Element_Type is
   begin
      return Ops.Last_Element (Container.Elements, Container.Last);
   end Last_Element;

   ----------------
   -- Last_Index --
   ----------------

   function Last_Index (Container : Vector) return Extended_Index
   is (Container.Last);

   ------------
   -- Length --
   ------------

   function Length (Container : Vector) return Capacity_Range
   is (To_Array_Index (Container.Last));

   -----------
   -- Model --
   -----------

   function Model (Container : Vector) return Formal_Model.M.Sequence is
   begin
      return Vector_Model.Model (Container.Elements, Container.Last);
   end Model;

   ----------
   -- Move --
   ----------

   procedure Move
     (Source : in out Relaxed_Element; Target : in out Relaxed_Element) is
   begin
      Target := Source;
   end Move;

   procedure Move (Target : in out Vector; Source : in out Vector) is
      LS   : constant Capacity_Range := Length (Source);
      Same : constant Boolean := Same_Object (Target, Source);

   begin
      if Same then
         return;
      end if;

      if Target.Capacity < LS then
         raise Capacity_Error with "Capacity too small";
      end if;

      Ops.Clear (Target.Elements, Target.Last);
      Ops.Assign (Target.Elements, Target.Last, Source.Elements, Source.Last);

      Ops.Clear (Source.Elements, Source.Last);
   end Move;

   ----------------
   -- Move_Range --
   ----------------

   procedure Move_Range
     (Source : in out Storage.Elements_Array;
      Target : in out Storage.Elements_Array) is
   begin
      Target := Source;
   end Move_Range;

   -------------
   -- Prepend --
   -------------

   procedure Prepend (Container : in out Vector; New_Item : Element_Type) is
   begin
      Insert
        (Container.Elements, Container.Last, Index_Type'First, New_Item, 1);
   end Prepend;

   procedure Prepend
     (Container : in out Vector; New_Item : Element_Type; Count : Count_Type)
   is
   begin
      Insert
        (Container.Elements,
         Container.Last,
         Index_Type'First,
         New_Item,
         Count);
   end Prepend;

   --------------------
   -- Prepend_Vector --
   --------------------

   procedure Prepend_Vector (Container : in out Vector; New_Item : Vector) is
   begin
      Check_Aliasing (Container, New_Item);
      Insert_Vector
        (Container.Elements,
         Container.Last,
         Index_Type'First,
         New_Item.Elements,
         New_Item.Last);
   end Prepend_Vector;

   -------------
   -- Reclaim --
   -------------

   procedure Reclaim
     (E : in out Storage.Elements_Array; First, Last : Count_Type'Base) is
   begin
      null;
   end Reclaim;

   ---------------
   -- Reference --
   ---------------

   function Reference
     (Container : aliased in out Vector; Index : Index_Type)
      return not null access Element_Type is
   begin
      if Index > Container.Last then
         raise Constraint_Error with "Index is out of range";
      end if;

      return Container.Elements (To_Array_Index (Index)).V'Access;
   end Reference;

   --------------
   -- Relocate --
   --------------

   procedure Relocate
     (E                         : in out Storage.Elements_Array;
      Source_From, Source_Up_To : Count_Type'Base;
      Target_From, Target_Up_To : Count_Type'Base) is
   begin
      E (Target_From .. Target_Up_To) := E (Source_From .. Source_Up_To);
   end Relocate;

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
        (Container.Elements, Container.Last, Index, New_Item);
   end Replace_Element;

   ----------------------
   -- Reserve_Capacity --
   ----------------------

   procedure Reserve_Capacity
     (Container : in out Vector; Capacity : Capacity_Range) is
   begin
      if Capacity > Container.Capacity then
         raise Capacity_Error with "Capacity is out of range";
      end if;
   end Reserve_Capacity;

   ----------------------
   -- Reverse_Elements --
   ----------------------

   procedure Reverse_Elements (Container : in out Vector) is
      Len : constant Capacity_Range := Length (Container);
   begin
      Ops.Reverse_Elements (Container.Elements (1 .. Len), Container.Last);
   end Reverse_Elements;

   ------------------------
   -- Reverse_Find_Index --
   ------------------------

   function Reverse_Find_Index
     (Container : Vector;
      Item      : Element_Type;
      Index     : Index_Type := Index_Type'Last) return Extended_Index is
   begin
      return
        Ops.Reverse_Find_Index
          (Container.Elements, Container.Last, Item, Index);
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

      Ops.Swap (Container.Elements, Container.Last, I, J);
   end Swap;

   ---------------
   -- To_Vector --
   ---------------

   function To_Vector
     (New_Item : Element_Type; Length : Capacity_Range) return Vector is
   begin
      if Length = 0 then
         return V : Vector (0) do
            V := Empty_Vector (0);
         end return;
      end if;

      declare
         First       : constant Int := Int (Index_Type'First);
         Last_As_Int : constant Int'Base := First + Int (Length) - 1;
         Last        : Index_Type;

      begin
         Last := Index_Type (Last_As_Int);

         return
           (Capacity => Length,
            Last     => Last,
            Elements => [others => (V => New_Item)]);
      end;
   end To_Vector;

end SPARK.Containers.Formal.Vectors.Impl;
