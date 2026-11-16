--
--  Copyright (C) 2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with SPARK.Big_Integers; use SPARK.Big_Integers;

package body SPARK.Containers.Formal.Generic_Vector_Operations
  with SPARK_Mode
is

   ------------
   -- Assign --
   ------------

   procedure Assign
     (E           : in out Elements_Array;
      Last        : in out Extended_Index;
      Source      : Elements_Array;
      Source_Last : Extended_Index)
   is
      LS : constant Capacity_Range := To_Array_Index (Source_Last);
   begin
      Clear (E, Last);

      Copy (E (1 .. LS), Source (1 .. LS));
      Last := Source_Last;
   end Assign;

   --------------------
   -- Check_Deletion --
   --------------------

   procedure Check_Deletion (Last : Extended_Index; Index : Extended_Index) is
   begin
      --  As a precondition on the generic actual Index_Type, the base type
      --  must include Index_Type'Pred (Index_Type'First); this is the value
      --  that Last assumes when the vector is empty. However, we do not allow
      --  that as the value for Index when specifying which items should be
      --  deleted, so we must manually check.

      if Index < Index_Type'First then
         raise Constraint_Error with "Index is out of range (too small)";
      end if;

      --  We allow a value greater than Last to be specified as the Index,
      --  but only if it's immediately greater. This allows the corner case
      --  of deleting no items from the back end to be treated as a no-op.

      if Index > Last then
         if Index > Last + 1 then
            raise Constraint_Error with "Index is out of range (too large)";
         end if;
      end if;
   end Check_Deletion;

   ---------------------
   -- Check_Insertion --
   ---------------------

   procedure Check_Insertion
     (Last       : Extended_Index;
      Before     : Extended_Index;
      Count      : Count_Type;
      New_Length : out Count_Type)
   is
      Old_Length : constant Count_Type := To_Array_Index (Last);
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
      --  simply report the unchanged length and return.

      if Count = 0 then
         New_Length := Old_Length;
         return;
      end if;

      --  Last_Count accounts for both the index range and Count_Type'Last.
      --  Check the remaining room before adding Count to avoid overflow.

      if Old_Length > Last_Count - Count then
         raise Constraint_Error with "Count is out of range";
      end if;

      New_Length := Old_Length + Count;
   end Check_Insertion;

   -----------
   -- Clear --
   -----------

   procedure Clear (E : in out Elements_Array; Last : in out Extended_Index) is
   begin
      Reclaim (E, 1, To_Array_Index (Last));
      Last := No_Index;
   end Clear;

   ------------------
   -- Delete_First --
   ------------------

   procedure Delete_First
     (E     : in out Elements_Array;
      Last  : in out Extended_Index;
      Count : Count_Type := 1) is
   begin
      if Count = 0 then
         return;

      elsif Count >= To_Array_Index (Last) then
         Clear (E, Last);
         return;

      else
         Delete_Internal (E, Last, Index_Type'First, Count);
      end if;
   end Delete_First;

   ---------------------
   -- Delete_Internal --
   ---------------------

   procedure Delete_Internal
     (E     : in out Elements_Array;
      Last  : in out Extended_Index;
      Index : Extended_Index;
      Count : Count_Type)
   is
      Old_Last : constant Index_Type'Base := Last;
      Old_Len  : constant Count_Type := To_Array_Index (Last);
      New_Last : Index_Type'Base;
      Count2   : Count_Type'Base;  -- count of items from Index to Old_Last
      Off      : Count_Type'Base;  -- Index expressed as offset from IT'First

   begin
      --  Delete removes items from the vector, the number of which is the
      --  minimum of the specified Count and the items (if any) that exist from
      --  Index to Last. There are no constraints on the specified Count, but
      --  there are constraints on the allowed values of Index.

      if Index > Old_Last then
         return;
      end if;

      if Count = 0 then
         return;
      end if;

      --  Calculate what's available for deletion starting at Index, using
      --  the wider of Index_Type'Base and Count_Type'Base for intermediate
      --  values.

      if Count_Type'Base'Last >= Index_Type'Pos (Index_Type'Base'Last) then
         Count2 := Count_Type'Base (Old_Last) - Count_Type'Base (Index) + 1;
      else
         Count2 := Count_Type'Base (Old_Last - Index + 1);
      end if;

      --  When Count is at least the available count, reclaim the suffix and
      --  shorten the vector. There are no elements to slide down.

      if Count >= Count2 then
         Reclaim (E, To_Array_Index (Index), Old_Len);
         Last := Index - 1;
         return;
      end if;

      --  Some elements aren't being deleted, so slide them down to Index.
      --  Calculate the array slice indices using the wider base type for
      --  intermediate values.

      if Index_Type'Base'Last >= Count_Type'Pos (Count_Type'Last) then
         Off := Count_Type'Base (Index - Index_Type'First);
         New_Last := Old_Last - Index_Type'Base (Count);
      else
         Off := Count_Type'Base (Index) - Count_Type'Base (Index_Type'First);
         New_Last := Index_Type'Base (Count_Type'Base (Old_Last) - Count);
      end if;

      declare
         Idx : constant Count_Type := E'First + Off;
      begin
         Reclaim (E, Idx, Idx + Count - 1);
         Relocate (E, Idx + Count, Old_Len, Idx, Old_Len - Count);
         Last := New_Last;
      end;
   end Delete_Internal;

   -----------------
   -- Delete_Last --
   -----------------

   procedure Delete_Last
     (E     : in out Elements_Array;
      Last  : in out Extended_Index;
      Count : Count_Type := 1)
   is
      Old_Len  : constant Count_Type := To_Array_Index (Last);
      New_Last : Extended_Index;
   begin
      if Count = 0 then
         return;
      end if;

      --  There is no restriction on Count. Deleting at least the current
      --  length clears the vector without calculating a new last index.

      if Count >= Old_Len then
         Clear (E, Last);
         return;

      elsif Index_Type'Base'Last >= Count_Type'Pos (Count_Type'Last) then
         New_Last := Last - Index_Type'Base (Count);

      else
         New_Last := Index_Type'Base (Count_Type'Base (Last) - Count);
      end if;

      Reclaim (E, Old_Len - Count + 1, Old_Len);
      Last := New_Last;
   end Delete_Last;

   -------------
   -- Element --
   -------------

   function Element
     (E : Elements_Array; Last : Extended_Index; Index : Extended_Index)
      return Element_Type is
   begin
      if Index = No_Index or else Index > Last then
         raise Constraint_Error with "Index is out of range";
      end if;

      return Constant_Access (E (To_Array_Index (Index))).all;
   end Element;

   -----------
   -- Equal --
   -----------

   function Equal
     (Left       : Elements_Array;
      Left_Last  : Extended_Index;
      Right      : Elements_Array;
      Right_Last : Extended_Index) return Boolean is
   begin
      if Left_Last /= Right_Last then
         return False;
      end if;

      for J in 1 .. To_Array_Index (Left_Last) loop
         if Constant_Access (Left (J)).all /= Constant_Access (Right (J)).all
         then
            return False;
         end if;
      end loop;

      return True;
   end Equal;

   ----------------
   -- Find_Index --
   ----------------

   function Find_Index
     (E     : Elements_Array;
      Last  : Extended_Index;
      Item  : Element_Type;
      Index : Index_Type := Index_Type'First) return Extended_Index is
   begin
      for Indx in Index .. Last loop
         if Constant_Access (E (To_Array_Index (Indx))).all = Item then
            return Indx;
         end if;
      end loop;

      return No_Index;
   end Find_Index;

   -------------------
   -- First_Element --
   -------------------

   function First_Element
     (E : Elements_Array; Last : Extended_Index) return Element_Type is
   begin
      if Last < Index_Type'First then
         raise Constraint_Error with "Container is empty";
      else
         return Constant_Access (E (1)).all;
      end if;
   end First_Element;

   -------------------
   -- Generic_Model --
   -------------------

   package body Generic_Model is
      package Count_Conversions is new Signed_Conversions (Count_Type);

      function Element (S : M.Sequence; I : Index_Type) return Element_Type
      renames M.Get;

      ---------------------
      -- Generic_Sorting --
      ---------------------

      package body Generic_Sorting is

         -----------------------
         -- M_Elements_Sorted --
         -----------------------

         function M_Elements_Sorted (Container : M.Sequence) return Boolean
         with SPARK_Mode => Off
         is
         begin
            if M.Length (Container) <= 1 then
               return True;
            end if;

            for I in Index_Type'First + 1 .. M.Last (Container) loop
               if Element (Container, I) < Element (Container, I - 1) then
                  return False;
               end if;
            end loop;

            return True;
         end M_Elements_Sorted;

      end Generic_Sorting;

      -------------------------
      -- M_Elements_In_Union --
      -------------------------

      function M_Elements_In_Union
        (Container, Left, Right : M.Sequence) return Boolean
      with SPARK_Mode => Off
      is
      begin
         for Index in Index_Type'First .. M.Last (Container) loop
            declare
               Found : Boolean := False;
            begin
               for J in Index_Type'First .. M.Last (Left) loop
                  if M.Element_Logic_Equal
                       (Element (Container, Index), Element (Left, J))
                  then
                     Found := True;
                     exit;
                  end if;
               end loop;

               if not Found then
                  for J in Index_Type'First .. M.Last (Right) loop
                     if M.Element_Logic_Equal
                          (Element (Container, Index), Element (Right, J))
                     then
                        Found := True;
                        exit;
                     end if;
                  end loop;
               end if;

               if not Found then
                  return False;
               end if;
            end;
         end loop;

         return True;
      end M_Elements_In_Union;

      -------------------------
      -- M_Elements_Included --
      -------------------------

      function M_Elements_Included
        (Left  : M.Sequence;
         L_Fst : Index_Type := Index_Type'First;
         L_Lst : M.Extended_Index;
         Right : M.Sequence;
         R_Fst : Index_Type := Index_Type'First;
         R_Lst : M.Extended_Index) return Boolean
      with SPARK_Mode => Off
      is
      begin
         for I in L_Fst .. L_Lst loop
            declare
               Found : Boolean := False;
               J     : M.Extended_Index := R_Fst - 1;

            begin
               while not Found and J < R_Lst loop
                  J := J + 1;
                  if M.Element_Logic_Equal
                       (Element (Left, I), Element (Right, J))
                  then
                     Found := True;
                  end if;
               end loop;

               if not Found then
                  return False;
               end if;
            end;
         end loop;

         return True;
      end M_Elements_Included;

      -------------------------
      -- M_Elements_Reversed --
      -------------------------

      function M_Elements_Reversed (Left, Right : M.Sequence) return Boolean
      with SPARK_Mode => Off
      is
         L : constant M.Extended_Index := M.Last (Left);

      begin
         if L /= M.Last (Right) then
            return False;
         end if;

         for I in Index_Type'First .. L loop
            if not M.Element_Logic_Equal
                     (Element (Left, I), Element (Right, L - I + 1))
            then
               return False;
            end if;
         end loop;

         return True;
      end M_Elements_Reversed;

      ------------------------
      -- M_Elements_Swapped --
      ------------------------

      function M_Elements_Swapped
        (Left, Right : M.Sequence; X, Y : Index_Type) return Boolean
      with SPARK_Mode => Off
      is
      begin
         if M.Length (Left) /= M.Length (Right)
           or else
             not M.Element_Logic_Equal (Element (Left, X), Element (Right, Y))
           or else
             not M.Element_Logic_Equal (Element (Left, Y), Element (Right, X))
         then
            return False;
         end if;

         for I in Index_Type'First .. M.Last (Left) loop
            if I /= X
              and then I /= Y
              and then
                not M.Element_Logic_Equal
                      (Element (Left, I), Element (Right, I))
            then
               return False;
            end if;
         end loop;

         return True;
      end M_Elements_Swapped;

      -----------
      -- Model --
      -----------

      function Model
        (E : Elements_Array; Last : Extended_Index) return M.Sequence
      is
         R : M.Sequence;
      begin
         for Position in 1 .. To_Array_Index (Last) loop
            pragma
              Loop_Invariant
                (Static =>
                   M.Length (R)
                   = Count_Conversions.To_Big_Integer (Position - 1));
            R := M.Add (R, Constant_Access (E (Position)).all);
         end loop;

         return R;
      end Model;

   end Generic_Model;

   ---------------------
   -- Generic_Sorting --
   ---------------------

   package body Generic_Sorting is

      ---------------
      -- Is_Sorted --
      ---------------

      function Is_Sorted
        (E : Elements_Array; Last : Extended_Index) return Boolean
      is
         L : constant Capacity_Range := To_Array_Index (Last);
      begin
         for J in 1 .. L - 1 loop
            if Constant_Access (E (J + 1)).all < Constant_Access (E (J)).all
            then
               return False;
            end if;
         end loop;
         return True;
      end Is_Sorted;

      -----------
      -- Merge --
      -----------

      procedure Merge
        (Target      : in out Elements_Array;
         Target_Last : in out Extended_Index;
         Source      : in out Elements_Array;
         Source_Last : in out Extended_Index)
      is
         Old_Length : constant Count_Type := To_Array_Index (Target_Last);
         New_Length : constant Count_Type :=
           Old_Length + To_Array_Index (Source_Last);
         I          : Count_Type := Old_Length;
         J          : Count_Type := New_Length;
      begin
         while Source_Last /= No_Index loop
            pragma
              Loop_Invariant (Static => J = I + To_Array_Index (Source_Last));
            pragma Loop_Invariant (Static => I <= Old_Length);
            pragma Loop_Invariant (Static => J <= New_Length);
            pragma
              Loop_Invariant (Static => Valid_Elements (Source, Source_Last));
            pragma
              Loop_Invariant
                (Static =>
                   (for all K in 1 .. New_Length =>
                      (if K <= I or else K > J
                       then Is_Initialized (Target (K)))));
            pragma
              Loop_Invariant
                (Static =>
                   (for all K in Target'Range =>
                      (if K > I and then K <= J
                       then Is_Reclaimed (Target (K)))));
            pragma
              Loop_Invariant
                (Static =>
                   (for all K in Target'Range =>
                      (if K > New_Length then Is_Reclaimed (Target (K)))));
            pragma Loop_Variant (Static => (Decreases => J));

            if I = 0 then
               Move_Range (Source (1 .. J), Target (1 .. J));
               pragma
                 Assert
                   (Static =>
                      (for all K in 1 .. New_Length =>
                         Is_Initialized (Target (K)))
                      and then
                        (for all K in Target'Range =>
                           (if K > New_Length then Is_Reclaimed (Target (K))))
                      and then
                        (for all K in Source'Range =>
                           Is_Reclaimed (Source (K))));
               Source_Last := No_Index;
               exit;
            end if;

            if Constant_Access (Source (To_Array_Index (Source_Last))).all
              < Constant_Access (Target (I)).all
            then
               Relocate (Target, I, I, J, J);
               I := I - 1;

            else
               Move (Source (To_Array_Index (Source_Last)), Target (J));
               Source_Last := Source_Last - 1;
            end if;

            J := J - 1;
         end loop;

         pragma
           Assert
             (Static =>
                (for all K in Target'Range =>
                   (if K > New_Length then Is_Reclaimed (Target (K))))
                and then
                  (for all K in Source'Range => Is_Reclaimed (Source (K))));

         if Index_Type'Base'Last >= Count_Type'Pos (Count_Type'Last) then
            Target_Last := No_Index + Index_Type'Base (New_Length);

         else
            Target_Last :=
              Index_Type'Base (Count_Type'Base (No_Index) + New_Length);
         end if;
      end Merge;

      ----------
      -- Sort --
      ----------

      procedure Sort (E : in out Elements_Array; Last : Extended_Index) is
         subtype T is Long_Long_Integer;

         Len : constant Count_Type := To_Array_Index (Last);

         function To_Index (J : T) return Array_Index
         is (Array_Index (J))
         with Pre => J in 1 .. T (Len);
         --  The array index subtype starts at 1, hence To_Index is the
         --  identity on the heapsort indices 1 .. Max.

         function Is_Anc (Root, Node : T) return Boolean
         is (Node = Root
             or else (Node > Root and then Is_Anc (Root, Node / 2)))
         with
           Ghost              => Static,
           Global             => null,
           Subprogram_Variant => (Decreases => Node),
           Pre                => (Static => Root >= 1 and then Node >= 1);
         --  Node lies in the subtree rooted at Root. The sift path remains
         --  in that subtree when climbing from a node to its father.

         function Valid_With_Hole (Hole : T) return Boolean
         is (E'First = 1
             and then Last <= No_Index + Count_Type'Pos (Last_Count)
             and then Len <= E'Last
             and then Hole in 1 .. T (Len)
             and then
               (for all I in E'Range =>
                  (if I = Count_Type (Hole)
                   then Is_Reclaimed (E (I))
                   elsif I <= Len
                   then Is_Initialized (E (I))
                   else Is_Reclaimed (E (I)))))
         with Ghost => Static;
         --  The extracted element leaves one reclaimed cell in the used
         --  prefix; every other used cell remains readable.

         Max  : T := T (Len);
         Temp : aliased Holder_Type;

         procedure Sift (S : T)
         with
           Pre  =>
             (Static =>
                S in 1 .. Max
                and then Max <= T (Len)
                and then Is_Initialized (Temp)
                and then Valid_With_Hole (S)),
           Post =>
             (Static => Valid_Elements (E, Last) and then Is_Reclaimed (Temp));
         --  Sift the element held in Temp down the heap rooted at S, over
         --  the heap region 1 .. Max, and fill the final reclaimed cell.

         ----------
         -- Sift --
         ----------

         procedure Sift (S : T) is
            C   : T := S;
            Son : T;

         begin
            loop
               pragma Loop_Invariant (Static => C in S .. Max);
               pragma Loop_Invariant (Static => Is_Anc (S, C));
               pragma Loop_Invariant (Static => Valid_With_Hole (C));
               pragma Loop_Invariant (Static => Is_Initialized (Temp));
               pragma Loop_Variant (Static => (Increases => C));
               Son := 2 * C;

               exit when Son > Max;

               declare
                  Son_Index : Array_Index := To_Index (Son);

               begin
                  if Son < Max then
                     if Constant_Access (E (Son_Index)).all
                       < Constant_Access (E (Array_Index'Succ (Son_Index))).all
                     then
                        Son := Son + 1;
                        Son_Index := Array_Index'Succ (Son_Index);
                     end if;
                  end if;

                  Relocate
                    (E, Son_Index, Son_Index, To_Index (C), To_Index (C));
               end;

               C := Son;
            end loop;

            while C /= S loop
               pragma Loop_Invariant (Static => C in 1 .. Max);
               pragma Loop_Invariant (Static => C >= S);
               pragma Loop_Invariant (Static => Is_Anc (S, C));
               pragma Loop_Invariant (Static => Valid_With_Hole (C));
               pragma Loop_Invariant (Static => Is_Initialized (Temp));
               pragma Loop_Variant (Static => (Decreases => C));
               declare
                  Father : constant T := C / 2;
               begin
                  if Constant_Access (E (To_Index (Father))).all
                    < Constant_Access (Temp).all
                  then
                     Relocate
                       (E,
                        To_Index (Father),
                        To_Index (Father),
                        To_Index (C),
                        To_Index (C));
                     C := Father;
                  else
                     exit;
                  end if;
               end;
            end loop;

            Move (Temp, E (To_Index (C)));
         end Sift;

      begin
         for J in reverse 1 .. Max / 2 loop
            pragma Loop_Invariant (Static => Max = T (Len));
            pragma Loop_Invariant (Static => Valid_Elements (E, Last));
            pragma Loop_Invariant (Static => Is_Reclaimed (Temp));
            Move (E (To_Index (J)), Temp);
            Sift (J);
         end loop;

         while Max > 1 loop
            pragma Loop_Invariant (Static => Max in 1 .. T (Len));
            pragma Loop_Invariant (Static => Valid_Elements (E, Last));
            pragma Loop_Invariant (Static => Is_Reclaimed (Temp));
            pragma Loop_Variant (Static => (Decreases => Max));
            Move (E (To_Index (Max)), Temp);
            Relocate (E, 1, 1, To_Index (Max), To_Index (Max));

            Max := Max - 1;
            Sift (1);
         end loop;
      end Sort;

   end Generic_Sorting;

   ---------------------
   -- Insert_Internal --
   ---------------------

   procedure Insert_Internal
     (E        : in out Elements_Array;
      Last     : in out Extended_Index;
      Before   : Extended_Index;
      New_Item : Element_Type;
      Count    : Count_Type)
   is
      Old_Length : constant Count_Type := To_Array_Index (Last);

      New_Length : Count_Type;
      J          : Count_Type;

   begin
      if Count = 0 then
         return;
      end if;

      New_Length := Old_Length + Count;
      J := To_Array_Index (Before);

      if J <= Old_Length then
         Relocate (E, J, Old_Length, J + Count, New_Length);
      end if;
      Fill_Range (E (J .. J - 1 + Count), New_Item);

      if Index_Type'Base'Last >= Count_Type'Pos (Count_Type'Last) then
         Last := No_Index + Index_Type'Base (New_Length);

      else
         Last := Index_Type'Base (Count_Type'Base (No_Index) + New_Length);
      end if;
   end Insert_Internal;

   ------------------
   -- Insert_Slice --
   ------------------

   procedure Insert_Slice
     (E           : in out Elements_Array;
      Last        : in out Extended_Index;
      Before      : Extended_Index;
      Source      : Elements_Array;
      Source_Last : Extended_Index)
   is
      Old_Length : constant Count_Type := To_Array_Index (Last);
      Count      : constant Count_Type := To_Array_Index (Source_Last);

      New_Length : Count_Type;
      J          : Count_Type;

   begin
      if Count = 0 then
         return;
      end if;

      New_Length := Old_Length + Count;
      J := To_Array_Index (Before);

      if J <= Old_Length then
         Relocate (E, J, Old_Length, J + Count, New_Length);
      end if;
      Copy (E (J .. J - 1 + Count), Source (1 .. Count));

      if Index_Type'Base'Last >= Count_Type'Pos (Count_Type'Last) then
         Last := No_Index + Index_Type'Base (New_Length);

      else
         Last := Index_Type'Base (Count_Type'Base (No_Index) + New_Length);
      end if;
   end Insert_Slice;

   ------------------
   -- Last_Element --
   ------------------

   function Last_Element
     (E : Elements_Array; Last : Extended_Index) return Element_Type is
   begin
      if Last < Index_Type'First then
         raise Constraint_Error with "Container is empty";
      else
         return Constant_Access (E (To_Array_Index (Last))).all;
      end if;
   end Last_Element;

   ---------------------
   -- Replace_Element --
   ---------------------

   procedure Replace_Element
     (E        : in out Elements_Array;
      Last     : Extended_Index;
      Index    : Index_Type;
      New_Item : Element_Type)
   is
      I : constant Count_Type := To_Array_Index (Index);
   begin
      Reclaim (E, I, I);
      Fill (E (I), New_Item);
   end Replace_Element;

   ----------------------
   -- Reverse_Elements --
   ----------------------

   procedure Reverse_Elements
     (E : in out Elements_Array; Last : Extended_Index)
   is
      Len  : constant Capacity_Range := To_Array_Index (Last);
      I, J : Count_Type;
   begin
      I := 1;
      J := Len;
      while I < J loop
         pragma Loop_Invariant (Static => I >= 1 and then J <= Len);
         pragma Loop_Invariant (Static => Valid_Elements (E, Last));
         pragma Loop_Variant (Static => (Decreases => J - I));
         Exchange (E, I, J);
         I := I + 1;
         J := J - 1;
      end loop;
   end Reverse_Elements;

   ------------------------
   -- Reverse_Find_Index --
   ------------------------

   function Reverse_Find_Index
     (E     : Elements_Array;
      Last  : Extended_Index;
      Item  : Element_Type;
      Index : Index_Type := Index_Type'Last) return Extended_Index
   is
      Search_Last : constant Index_Type'Base := Index_Type'Min (Last, Index);
   begin
      for Indx in reverse Index_Type'First .. Search_Last loop
         if Constant_Access (E (To_Array_Index (Indx))).all = Item then
            return Indx;
         end if;
      end loop;

      return No_Index;
   end Reverse_Find_Index;

   ----------
   -- Swap --
   ----------

   procedure Swap
     (E : in out Elements_Array; Last : Extended_Index; I, J : Index_Type) is
   begin
      Exchange (E, To_Array_Index (I), To_Array_Index (J));
   end Swap;

end SPARK.Containers.Formal.Generic_Vector_Operations;
