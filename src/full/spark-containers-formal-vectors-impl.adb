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

   function Count_Type_Last return Count_Type'Base
   is (Count_Type'Last)
   with Inline;
   function Index_Type_Last return Index_Type'Base
   is (Index_Type'Last)
   with Inline;
   --  Non-static wrappers for the two bounds. They are used in the
   --  overflow-guarded conversions of Insert_Space so that those conversions
   --  are ordinary (branch-guarded) run-time checks rather than static
   --  expressions the front end folds into compile-time Constraint_Error on
   --  instantiations whose index base type is narrower than Count_Type.

   procedure Insert_Space
     (Elements : in out Elements_Array;
      Last     : in out Extended_Index;
      Before   : Extended_Index;
      Count    : Count_Type := 1)
   with
     Exit_Cases =>
       (not Valid_Index_For_Insertion (Last, Before)
        or Exceeds_Last_Count (To_Array_Index (Last), Count)               =>
          (Exception_Raised => Constraint_Error),
        Valid_Index_For_Insertion (Last, Before)
        and not Exceeds_Last_Count (To_Array_Index (Last), Count)
        and Exceeds_Capacity (To_Array_Index (Last), Elements'Last, Count) =>
          (Exception_Raised => Capacity_Error),
        others                                                             =>
          Normal_Return),
     Pre        =>
       (Static =>
          Elements'First = 1
          and then Last <= No_Index + Count_Type'Pos (Last_Count)
          and then To_Array_Index (Last) <= Elements'Last
          and then
            (for all I in 1 .. To_Array_Index (Last) =>
               Elements (I).V'Initialized)),
     Post       =>
       (Static =>
          To_Array_Index (Last) = To_Array_Index (Last'Old) + Count
          and then To_Array_Index (Last) <= Elements'Last
          and then
            (for all I in 1 .. To_Array_Index (Last'Old) =>
               Elements (I)'Initialized)
          and then
            (if Count /= 0
             then
               (for all I in 1 .. To_Array_Index (Last) =>
                  (if I < To_Array_Index (Before)
                     or else I > To_Array_Index (Before) + Count - 1
                   then Elements (I)'Initialized))));
   --  Insert_Space takes the backing array and last index separately, rather
   --  than a Vector, on purpose. It slides the existing elements up to open a
   --  hole of Count cells at Before and reports the grown last index in the
   --  in-out Last parameter, but it does NOT touch a Vector: a Ghost_Predicate
   --  is checked at every boundary a Vector crosses (every parameter pass and
   --  return, and after a call updates one of its components), and the hole it
   --  opens transiently breaks that predicate.
   --
   --  The caller must therefore pass a LOCAL last index (not Container.Last
   --  directly) and keep Container.Last at its old value across the call and
   --  the hole-fill: with the old last, Container's predicate is consistent
   --  with the slid array (the post keeps the old used prefix initialized), so
   --  the checks after the call and the fill hold. The caller assigns the
   --  reported new last to Container.Last only after filling the hole. The
   --  post leaves exactly the hole
   --  (To_Array_Index (Before) .. To_Array_Index (Before) + Count - 1)
   --  possibly uninitialized.

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

      if Length (Left) /= Length (Right) then
         return False;
      end if;

      for J in 1 .. Length (Left) loop
         if Left.Elements (J).V /= Right.Elements (J).V then
            return False;
         end if;
      end loop;

      return True;
   end "=";

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
      LS   : constant Capacity_Range := Length (Source);
      Same : constant Boolean := Same_Object (Target, Source);

   begin
      if Same then
         return;
      end if;

      if Target.Capacity < LS then
         raise Constraint_Error;
      end if;

      Clear (Target);
      Append_Vector (Target, Source);
   end Assign;

   --------------
   -- Capacity --
   --------------

   function Capacity (Container : Vector) return Capacity_Range
   is (Container.Capacity);

   -----------
   -- Clear --
   -----------

   procedure Clear (Container : in out Vector) is
   begin
      Container.Last := No_Index;
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
      return Find_Index (Container, Item) /= No_Index;
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
            Target.Elements (1 .. LS) := Source.Elements (1 .. LS);
            Target.Last := Source.Last;
         end return;
      end;
   end Copy;

   ------------
   -- Delete --
   ------------

   procedure Delete (Container : in out Vector; Index : Extended_Index) is
   begin
      Delete (Container, Index, 1);
   end Delete;

   procedure Delete
     (Container : in out Vector; Index : Extended_Index; Count : Count_Type)
   is
      Old_Last : constant Index_Type'Base := Container.Last;
      Old_Len  : constant Count_Type := Length (Container);
      New_Last : Index_Type'Base;
      Count2   : Count_Type'Base;  -- count of items from Index to Old_Last
      Off      : Count_Type'Base;  -- Index expressed as offset from IT'First

   begin
      --  Delete removes items from the vector, the number of which is the
      --  minimum of the specified Count and the items (if any) that exist from
      --  Index to Container.Last. There are no constraints on the specified
      --  value of Count (it can be larger than what's available at this
      --  position in the vector, for example), but there are constraints on
      --  the allowed values of the Index.

      --  As a precondition on the generic actual Index_Type, the base type
      --  must include Index_Type'Pred (Index_Type'First); this is the value
      --  that Container.Last assumes when the vector is empty. However, we do
      --  not allow that as the value for Index when specifying which items
      --  should be deleted, so we must manually check. (That the user is
      --  allowed to specify the value at all here is a consequence of the
      --  declaration of the Extended_Index subtype, which includes the values
      --  in the base range that immediately precede and immediately follow the
      --  values in the Index_Type.)

      if Index < Index_Type'First then
         raise Constraint_Error with "Index is out of range (too small)";
      end if;

      --  We do allow a value greater than Container.Last to be specified as
      --  the Index, but only if it's immediately greater. This allows the
      --  corner case of deleting no items from the back end of the vector to
      --  be treated as a no-op. (It is assumed that specifying an index value
      --  greater than Last + 1 indicates some deeper flaw in the caller's
      --  algorithm, so that case is treated as a proper error.)

      if Index > Old_Last then
         if Index > Old_Last + 1 then
            raise Constraint_Error with "Index is out of range (too large)";
         end if;

         return;
      end if;

      if Count = 0 then
         return;
      end if;

      --  We first calculate what's available for deletion starting at
      --  Index. Here and elsewhere we use the wider of Index_Type'Base and
      --  Count_Type'Base as the type for intermediate values. (See function
      --  Length for more information.)

      if Count_Type'Base'Last >= Index_Type'Pos (Index_Type'Base'Last) then
         Count2 := Count_Type'Base (Old_Last) - Count_Type'Base (Index) + 1;
      else
         Count2 := Count_Type'Base (Old_Last - Index + 1);
      end if;

      --  If more elements are requested (Count) for deletion than are
      --  available (Count2) for deletion beginning at Index, then everything
      --  from Index is deleted. There are no elements to slide down, and so
      --  all we need to do is set the value of Container.Last.

      if Count >= Count2 then
         Container.Last := Index - 1;
         return;
      end if;

      --  There are some elements aren't being deleted (the requested count was
      --  less than the available count), so we must slide them down to Index.
      --  We first calculate the index values of the respective array slices,
      --  using the wider of Index_Type'Base and Count_Type'Base as the type
      --  for intermediate calculations.

      if Index_Type'Base'Last >= Count_Type'Pos (Count_Type'Last) then
         Off := Count_Type'Base (Index - Index_Type'First);
         New_Last := Old_Last - Index_Type'Base (Count);
      else
         Off := Count_Type'Base (Index) - Count_Type'Base (Index_Type'First);
         New_Last := Index_Type'Base (Count_Type'Base (Old_Last) - Count);
      end if;

      --  The array index values for each slice have already been determined,
      --  so we just slide down to Index the elements that weren't deleted.

      declare
         EA  : Elements_Array renames Container.Elements;
         Idx : constant Count_Type := EA'First + Off;
      begin
         EA (Idx .. Old_Len - Count) := EA (Idx + Count .. Old_Len);
         Container.Last := New_Last;
      end;
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
      if Count = 0 then
         return;

      elsif Count >= Length (Container) then
         Clear (Container);
         return;

      else
         Delete (Container, Index_Type'First, Count);
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
      if Count = 0 then
         return;
      end if;

      --  There is no restriction on how large Count can be when deleting
      --  items. If it is equal or greater than the current length, then this
      --  is equivalent to clearing the vector. (In particular, there's no need
      --  for us to actually calculate the new value for Last.)

      --  If the requested count is less than the current length, then we must
      --  calculate the new value for Last. For the type we use the widest of
      --  Index_Type'Base and Count_Type'Base for the intermediate values of
      --  our calculation.  (See the comments in Length for more information.)

      if Count >= Length (Container) then
         Container.Last := No_Index;

      elsif Index_Type'Base'Last >= Count_Type'Pos (Count_Type'Last) then
         Container.Last := Container.Last - Index_Type'Base (Count);

      else
         Container.Last :=
           Index_Type'Base (Count_Type'Base (Container.Last) - Count);
      end if;
   end Delete_Last;

   -------------
   -- Element --
   -------------

   function Element
     (Container : Vector; Index : Extended_Index) return Element_Type is
   begin
      if Index = No_Index or else Index > Container.Last then
         raise Constraint_Error with "Index is out of range";
      end if;

      declare
         II : constant Int'Base := Int (Index) - Int (No_Index);
         I  : constant Capacity_Range := Capacity_Range (II);
      begin
         return Container.Elements (I).V;
      end;
   end Element;

   ------------------
   -- Empty_Vector --
   ------------------

   function Empty_Vector (Capacity : Count_Type := 10) return Vector
   is ((Capacity => Capacity, others => <>));

   ----------------
   -- Find_Index --
   ----------------

   function Find_Index
     (Container : Vector;
      Item      : Element_Type;
      Index     : Index_Type := Index_Type'First) return Extended_Index is
   begin
      for Indx in Index .. Container.Last loop
         if Container.Elements (To_Array_Index (Indx)).V = Item then
            return Indx;
         end if;
      end loop;

      return No_Index;
   end Find_Index;

   -------------------
   -- First_Element --
   -------------------

   function First_Element (Container : Vector) return Element_Type is
   begin
      if Is_Empty (Container) then
         raise Constraint_Error with "Container is empty";
      else
         return Container.Elements (1).V;
      end if;
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

      ---------------
      -- Is_Sorted --
      ---------------

      function Is_Sorted (Container : Vector) return Boolean is
         L : constant Capacity_Range := Length (Container);

      begin
         for J in 1 .. L - 1 loop
            if Container.Elements (J + 1).V < Container.Elements (J).V then
               return False;
            end if;
         end loop;

         return True;
      end Is_Sorted;

      -----------
      -- Merge --
      -----------

      procedure Merge (Target : in out Vector; Source : in out Vector) is
         I    : Count_Type;
         J    : Count_Type;
         Same : constant Boolean := Same_Object (Target, Source);

      begin
         if Same then
            raise Program_Error with "Target and Source denote same container";
         end if;

         if Length (Source) = 0 then
            return;
         end if;

         if Length (Target) = 0 then
            Move (Target => Target, Source => Source);
            return;
         end if;

         if Target.Last >= Index_Type'Last then
            raise Constraint_Error
              with "vector is already at its maximum length";
         end if;

         I := Length (Target);
         declare
            New_Last : Extended_Index := Target.Last;
            TA       : Elements_Array renames Target.Elements;
            SA       : Elements_Array renames Source.Elements;

         begin
            Insert_Space (TA, New_Last, Target.Last + 1, Length (Source));
            J := I + Length (Source);
            while Length (Source) /= 0 loop
               if I = 0 then
                  TA (1 .. J) := SA (1 .. Length (Source));
                  Source.Last := No_Index;
                  exit;
               end if;

               if SA (Length (Source)).V < TA (I).V then
                  TA (J) := TA (I);
                  I := I - 1;

               else
                  TA (J) := SA (Length (Source));
                  Source.Last := Source.Last - 1;
               end if;

               J := J - 1;
            end loop;

            Target.Last := New_Last;
         end;
      end Merge;

      ----------
      -- Sort --
      ----------

      procedure Sort (Container : in out Vector) is
         subtype T is Long_Long_Integer;

         function To_Index (J : T) return Array_Index
         is (Array_Index (J));
         --  The array index subtype starts at 1, hence To_Index is the
         --  identity on the heapsort indices 1 .. Max.

         procedure Sift (S : T);

         Max  : T := T (Length (Container));
         Temp : Element_Type;

         ----------
         -- Sift --
         ----------

         procedure Sift (S : T) is
            C   : T := S;
            Son : T;

         begin
            loop
               Son := 2 * C;

               exit when Son > Max;

               declare
                  Son_Index : Array_Index := To_Index (Son);

               begin
                  if Son < Max then
                     if Container.Elements (Son_Index).V
                       < Container.Elements (Array_Index'Succ (Son_Index)).V
                     then
                        Son := Son + 1;
                        Son_Index := Array_Index'Succ (Son_Index);
                     end if;
                  end if;

                  Container.Elements (To_Index (C)).V :=
                    Container.Elements (Son_Index).V;
               end;

               C := Son;
            end loop;

            while C /= S loop
               declare
                  Father : constant T := C / 2;
               begin
                  if Container.Elements (To_Index (Father)).V < Temp then
                     Container.Elements (To_Index (C)).V :=
                       Container.Elements (To_Index (Father)).V;
                     C := Father;
                  else
                     exit;
                  end if;
               end;
            end loop;

            Container.Elements (To_Index (C)).V := Temp;
         end Sift;

      begin
         if Container.Last <= Index_Type'First then
            return;
         end if;

         for J in reverse 1 .. Max / 2 loop
            Temp := Container.Elements (To_Index (J)).V;
            Sift (J);
         end loop;

         while Max > 1 loop
            Temp := Container.Elements (To_Index (Max)).V;
            Container.Elements (To_Index (Max)).V := Container.Elements (1).V;

            Max := Max - 1;
            Sift (1);
         end loop;
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
      Insert (Container, Before, New_Item, 1);
   end Insert;

   procedure Insert
     (Container : in out Vector;
      Before    : Extended_Index;
      New_Item  : Element_Type;
      Count     : Count_Type)
   is
      J    : Count_Type'Base;  -- scratch
      Last : Extended_Index := Container.Last;
      --  Local last index. Container.Last is left untouched until the hole is
      --  filled, so the Vector predicate stays consistent throughout (see
      --  Insert_Space).

   begin
      --  Use Insert_Space to create the "hole" (the destination slice)

      Insert_Space (Container.Elements, Last, Before, Count);

      if Count = 0 then
         return;
      end if;

      J := To_Array_Index (Before);

      Container.Elements (J .. J - 1 + Count) := [others => (V => New_Item)];

      Container.Last := Last;
   end Insert;

   ------------------
   -- Insert_Space --
   ------------------

   procedure Insert_Space
     (Elements : in out Elements_Array;
      Last     : in out Extended_Index;
      Before   : Extended_Index;
      Count    : Count_Type := 1)
   is
      Old_Length : constant Count_Type := To_Array_Index (Last);

      Max_Length : Count_Type'Base;  -- determined from range of Index_Type
      New_Length : Count_Type'Base;  -- sum of current length and Count

      Index : Index_Type'Base;  -- scratch for intermediate values
      J     : Count_Type'Base;  -- scratch

   begin
      --  As a precondition on the generic actual Index_Type, the base type
      --  must include Index_Type'Pred (Index_Type'First); this is the value
      --  that Last assumes when the vector is empty. However, we do
      --  not allow that as the value for Index when specifying where the new
      --  items should be inserted, so we must manually check. (That the user
      --  is allowed to specify the value at all here is a consequence of the
      --  declaration of the Extended_Index subtype, which includes the values
      --  in the base range that immediately precede and immediately follow the
      --  values in the Index_Type.)

      if Before < Index_Type'First then
         raise Constraint_Error
           with "Before index is out of range (too small)";
      end if;

      --  We do allow a value greater than Container.Last to be specified as
      --  the Index, but only if it's immediately greater. This allows for the
      --  case of appending items to the back end of the vector. (It is assumed
      --  that specifying an index value greater than Last + 1 indicates some
      --  deeper flaw in the caller's algorithm, so that case is treated as a
      --  proper error.)

      if Before > Last and then Before - 1 > Last then
         raise Constraint_Error
           with "Before index is out of range (too large)";
      end if;

      --  We treat inserting 0 items into the container as a no-op, so we
      --  simply return.

      if Count = 0 then
         return;
      end if;

      --  There are two constraints we need to satisfy. The first constraint is
      --  that a container cannot have more than Count_Type'Last elements, so
      --  we must check the sum of the current length and the insertion count.
      --  Note that the value cannot be simply added because the result may
      --  overflow.

      if Old_Length > Count_Type'Last - Count then
         raise Constraint_Error with "Count is out of range";
      end if;

      --  It is now safe compute the length of the new vector, without fear of
      --  overflow.

      New_Length := Old_Length + Count;

      --  The second constraint is that the new Last index value cannot exceed
      --  Index_Type'Last. In each branch below, we calculate the maximum
      --  length (computed from the range of values in Index_Type), and then
      --  compare the new length to the maximum length. If the new length is
      --  acceptable, then we compute the new last index from that.

      if Index_Type'Base'Last >= Count_Type'Pos (Count_Type'Last) then

         --  We have to handle the case when there might be more values in the
         --  range of Index_Type than in the range of Count_Type.

         if Index_Type'First <= 0 then

            --  We know that No_Index (the same as Index_Type'First - 1) is
            --  less than 0, so it is safe to compute the following sum without
            --  fear of overflow.

            Index := No_Index + Index_Type'Base (Count_Type_Last);

            if Index <= Index_Type'Last then

               --  We have determined that range of Index_Type has at least as
               --  many values as in Count_Type, so Count_Type'Last is the
               --  maximum number of items that are allowed.

               Max_Length := Count_Type'Last;

            else
               --  The range of Index_Type has fewer values than in Count_Type,
               --  so the maximum number of items is computed from the range of
               --  the Index_Type.

               Max_Length := Count_Type'Base (Index_Type_Last - No_Index);
            end if;

         else
            --  No_Index is equal or greater than 0, so we can safely compute
            --  the difference without fear of overflow (which we would have to
            --  worry about if No_Index were less than 0, but that case is
            --  handled above).

            if Index_Type_Last - No_Index >= Index_Type'Base (Count_Type_Last)
            then
               --  We have determined that range of Index_Type has at least as
               --  many values as in Count_Type, so Count_Type'Last is the
               --  maximum number of items that are allowed.

               Max_Length := Count_Type'Last;

            else
               --  The range of Index_Type has fewer values than in Count_Type,
               --  so the maximum number of items is computed from the range of
               --  the Index_Type.

               Max_Length := Count_Type'Base (Index_Type_Last - No_Index);
            end if;
         end if;

      elsif Index_Type'First <= 0 then

         --  We know that No_Index (the same as Index_Type'First - 1) is less
         --  than 0, so it is safe to compute the following sum without fear of
         --  overflow.

         J := Count_Type'Base (No_Index) + Count_Type'Last;

         if J <= Count_Type'Base (Index_Type_Last) then

            --  We have determined that range of Index_Type has at least as
            --  many values as in Count_Type, so Count_Type'Last is the maximum
            --  number of items that are allowed.

            Max_Length := Count_Type'Last;

         else
            --  The range of Index_Type has fewer values than Count_Type does,
            --  so the maximum number of items is computed from the range of
            --  the Index_Type.

            Max_Length :=
              Count_Type'Base (Index_Type'Last) - Count_Type'Base (No_Index);
         end if;

      else
         --  No_Index is equal or greater than 0, so we can safely compute the
         --  difference without fear of overflow (which we would have to worry
         --  about if No_Index were less than 0, but that case is handled
         --  above).

         Max_Length :=
           Count_Type'Base (Index_Type_Last) - Count_Type'Base (No_Index);
      end if;

      --  We have just computed the maximum length (number of items). We must
      --  now compare the requested length to the maximum length, as we do not
      --  allow a vector expand beyond the maximum (because that would create
      --  an internal array with a last index value greater than
      --  Index_Type'Last, with no way to index those elements).

      if New_Length > Max_Length then
         raise Constraint_Error with "Count is out of range";

      --  Raise Capacity_Error if the new length exceeds the container's
      --  capacity.

      elsif New_Length > Elements'Last then
         raise Capacity_Error with "New length is larger than capacity";
      end if;

      J := To_Array_Index (Before);

      if Before <= Last then

         --  The new items are being inserted before some existing elements, so
         --  we must slide the existing elements up to their new home.

         Elements (J + Count .. New_Length) := Elements (J .. Old_Length);
      end if;

      if Index_Type'Base'Last >= Count_Type'Pos (Count_Type'Last) then
         Last := No_Index + Index_Type'Base (New_Length);

      else
         Last := Index_Type'Base (Count_Type'Base (No_Index) + New_Length);
      end if;
   end Insert_Space;

   -------------------
   -- Insert_Vector --
   -------------------

   procedure Insert_Vector
     (Container : in out Vector; Before : Extended_Index; New_Item : Vector)
   is
      N    : constant Count_Type := Length (New_Item);
      B    : Count_Type;  -- index Before converted to Count_Type
      Same : constant Boolean := Same_Object (Container, New_Item);
      Last : Extended_Index := Container.Last;
      --  Local last index. Container.Last is left untouched until the hole is
      --  filled, so the Vector predicate stays consistent throughout (see
      --  Insert_Space).

   begin
      if Same then
         raise Program_Error
           with "Container and New_Item denote same container";
      end if;

      --  Use Insert_Space to create the "hole" (the destination slice) into
      --  which we copy the source items.

      Insert_Space (Container.Elements, Last, Before, Count => N);

      if N = 0 then

         --  There's nothing else to do here (vetting of parameters was
         --  performed already in Insert_Space, and Last is unchanged), so we
         --  simply return.

         return;
      end if;

      B := To_Array_Index (Before);

      Container.Elements (B .. B - 1 + N) := New_Item.Elements (1 .. N);

      Container.Last := Last;
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
      if Is_Empty (Container) then
         raise Constraint_Error with "Container is empty";
      else
         return Container.Elements (Length (Container)).V;
      end if;
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
      R : Formal_Model.M.Sequence;

   begin
      for Position in 1 .. Length (Container) loop
         R := Formal_Model.M.Add (R, Container.Elements (Position).V);
      end loop;

      return R;
   end Model;

   ----------
   -- Move --
   ----------

   procedure Move (Target : in out Vector; Source : in out Vector) is
      LS   : constant Capacity_Range := Length (Source);
      Same : constant Boolean := Same_Object (Target, Source);

   begin
      if Same then
         return;
      end if;

      if Target.Capacity < LS then
         raise Constraint_Error;
      end if;

      Clear (Target);
      Append_Vector (Target, Source);
      Clear (Source);
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
     (Container : aliased in out Vector; Index : Index_Type)
      return not null access Element_Type is
   begin
      if Index > Container.Last then
         raise Constraint_Error with "Index is out of range";
      end if;

      return Container.Elements (To_Array_Index (Index)).V'Access;
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

      declare
         II : constant Int'Base := Int (Index) - Int (No_Index);
         I  : constant Capacity_Range := Capacity_Range (II);

      begin
         Container.Elements (I).V := New_Item;
      end;
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
   begin
      if Length (Container) <= 1 then
         return;
      end if;

      declare
         Len  : constant Capacity_Range := Length (Container);
         --  Captured in a constant: a renamed slice's bounds may not depend on
         --  a variable input in SPARK (E0007).
         I, J : Capacity_Range;
         E    : Elements_Array renames Container.Elements (1 .. Len);

      begin
         I := 1;
         J := Len;
         while I < J loop
            declare
               EI : constant Element_Type := E (I).V;

            begin
               E (I).V := E (J).V;
               E (J).V := EI;
            end;

            I := I + 1;
            J := J - 1;
         end loop;
      end;
   end Reverse_Elements;

   ------------------------
   -- Reverse_Find_Index --
   ------------------------

   function Reverse_Find_Index
     (Container : Vector;
      Item      : Element_Type;
      Index     : Index_Type := Index_Type'Last) return Extended_Index
   is

      Last : constant Index_Type'Base :=
        Index_Type'Min (Container.Last, Index);

   begin
      for Indx in reverse Index_Type'First .. Last loop
         if Container.Elements (To_Array_Index (Indx)).V = Item then
            return Indx;
         end if;
      end loop;

      return No_Index;
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

      if I = J then
         return;
      end if;

      declare
         II : constant Int'Base := Int (I) - Int (No_Index);
         JJ : constant Int'Base := Int (J) - Int (No_Index);

         EI : Element_Type renames Container.Elements (Capacity_Range (II)).V;
         EJ : Element_Type renames Container.Elements (Capacity_Range (JJ)).V;

         EI_Copy : constant Element_Type := EI;

      begin
         EI := EJ;
         EJ := EI_Copy;
      end;
   end Swap;

   ---------------
   -- To_Vector --
   ---------------

   function To_Vector
     (New_Item : Element_Type; Length : Capacity_Range) return Vector is
   begin
      if Length = 0 then
         return Empty_Vector (0);
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
