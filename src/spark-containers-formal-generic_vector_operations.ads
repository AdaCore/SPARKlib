--
--  Copyright (C) 2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Vector algorithms over an array of element holders. Storage supplies the
--  array representation and index conversions; the formal subprograms supply
--  element access, copying, transfer and reclamation. This lets the same
--  algorithms work with inline elements or holders that own separately
--  allocated elements.
--
--  Operations receive the array and last index separately. Contracts track
--  the initialized prefix and reclaimed spare cells, independently of element
--  values. Bulk storage operations remain formal so instances can use slice
--  assignments instead of copying elements one at a time.
--
--  Callers provide sufficient storage and handle container-level capacity
--  and alias checks. Index and length checks that can raise exceptions are
--  separate from storage updates, so callers validate before changing owning
--  storage.

pragma Ada_2022;

with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Containers.Functional.Vectors;
with SPARK.Containers.Formal.Generic_Vector_Storage;

private generic
   Last_Count : Count_Type;

   type Index_Type is range <>;
   No_Index : Index_Type'Base;

   type Element_Type (<>) is private;

   with function "=" (Left, Right : Element_Type) return Boolean is <>;

   ---------------------
   -- Element storage --
   ---------------------

   type Holder_Type is private;

   with package Storage is new
     SPARK.Containers.Formal.Generic_Vector_Storage
       (Last_Count  => Last_Count,
        Index_Type  => Index_Type,
        No_Index    => No_Index,
        Holder_Type => Holder_Type);

   use Storage;

   with
     function Is_Initialized (H : Holder_Type) return Boolean
     with Ghost => Static;
   --  H holds a readable element

   with
     function Is_Reclaimed (H : Holder_Type) return Boolean
     with Ghost => Static;
   --  H owns nothing, so overwriting it cannot leak

   with
     function Constant_Access
       (H : aliased Holder_Type) return not null access constant Element_Type;
   --  Read H's element without copying it. The aliased parameter allows
   --  access to an inline element; the result cannot be returned to callers.

   with procedure Fill (H : out Holder_Type; Item : Element_Type);
   --  Fill one reclaimed cell with a copy of Item

   with
     procedure Move (Source : in out Holder_Type; Target : in out Holder_Type);
   --  Move Source's element to Target, leaving Source holding nothing

   ----------------------
   -- Array operations --
   ----------------------

   with
     procedure Copy (Target : in out Elements_Array; Source : Elements_Array);
   --  Copy Source into reclaimed Target cells without consuming Source

   with procedure Exchange (E : in out Elements_Array; I, J : Count_Type'Base);
   --  Exchange two readable cells, preserving other cells

   with procedure Fill_Range (E : in out Elements_Array; Item : Element_Type);
   --  Fill reclaimed cells with copies of Item

   with
     procedure Move_Range
       (Source : in out Elements_Array; Target : in out Elements_Array);
   --  Move Source to Target, leaving its source cells reclaimed

   with
     procedure Reclaim
       (E : in out Elements_Array; First, Last : Count_Type'Base);
   --  Reclaim First .. Last, preserving other cells. Empty ranges are
   --  accepted.

   with
     procedure Relocate
       (E                         : in out Elements_Array;
        Source_From, Source_Up_To : Count_Type'Base;
        Target_From, Target_Up_To : Count_Type'Base);
   --  Move a range within E in either direction, leaving the vacated cells
   --  reclaimed so that no element is designated twice and the hole can be
   --  filled without leaking.

package SPARK.Containers.Formal.Generic_Vector_Operations with
    SPARK_Mode,
    Always_Terminates
is
   function Valid_Elements
     (E : Elements_Array; Last : Extended_Index) return Boolean
   is (E'First = 1
       and then Last <= No_Index + Count_Type'Pos (Last_Count)
       and then To_Array_Index (Last) <= E'Last
       and then
         (for all I in 1 .. To_Array_Index (Last) => Is_Initialized (E (I)))
       and then
         (for all I in E'Range =>
            (if I > To_Array_Index (Last) then Is_Reclaimed (E (I)))))
   with Ghost => Static, Global => null;
   --  The used prefix fits in the array and is entirely readable, and the
   --  cells beyond it own nothing, so a relocation may land in them without
   --  leaking. This is the array-and-last half of each container's structural
   --  invariant; it spans both parameters, so it is threaded as Pre/Post
   --  rather than carried in a type predicate. The reclamation clause is
   --  vacuous where the element is held inline.

   generic
      --!format off
      with package M is new
        SPARK.Containers.Functional.Vectors
          (Index_Type   => Index_Type,
           Element_Type => Element_Type,
           others       => <>)
        with Ghost => SPARKlib_Logic;
      --!format on
   package Generic_Model with Ghost => SPARKlib_Logic is
      function M_Elements_In_Union
        (Container, Left, Right : M.Sequence) return Boolean
      with Ghost => SPARKlib_Full, Global => null;

      function M_Elements_Included
        (Left  : M.Sequence;
         L_Fst : Index_Type := Index_Type'First;
         L_Lst : M.Extended_Index;
         Right : M.Sequence;
         R_Fst : Index_Type := Index_Type'First;
         R_Lst : M.Extended_Index) return Boolean
      with Ghost => SPARKlib_Full, Global => null;

      function M_Elements_Reversed (Left, Right : M.Sequence) return Boolean
      with Ghost => SPARKlib_Full, Global => null;

      function M_Elements_Swapped
        (Left, Right : M.Sequence; X, Y : Index_Type) return Boolean
      with Ghost => SPARKlib_Full, Global => null;

      function Model
        (E : Elements_Array; Last : Extended_Index) return M.Sequence
      with Global => null, Pre => (Static => Valid_Elements (E, Last));
      --  The sequence of elements in the used prefix

      generic
         with function "<" (Left, Right : Element_Type) return Boolean is <>;
      package Generic_Sorting is
         function M_Elements_Sorted (Container : M.Sequence) return Boolean
         with Global => null;
      end Generic_Sorting;
   end Generic_Model;

   --  The following ghost helpers express, without any model, the exact
   --  conditions under which the insertion operations raise an exception, so
   --  that the Exit_Cases of those operations state precisely when, and
   --  which, exception is raised.

   function Valid_Index_For_Insertion
     (Last : Extended_Index; Before : Extended_Index) return Boolean
   is ((Before in Index_Type'First .. Last)
       or else (Before /= No_Index and then Before - 1 = Last))
   with Ghost => Static, Global => null;
   --  Before designates a valid insertion point: an existing index, or the
   --  slot immediately after the last one (so that appending is allowed). A
   --  Before outside this set makes the insertion raise Constraint_Error.

   function Exceeds_Last_Count
     (Length : Count_Type; Count : Count_Type) return Boolean
   is (Count > 0 and then Length > Last_Count - Count)
   with Ghost => Static, Global => null;
   --  Inserting Count items would push the length past the maximum vector
   --  length Last_Count, which raises Constraint_Error.

   function Exceeds_Capacity
     (Length : Count_Type; Capacity : Capacity_Range; Count : Count_Type)
      return Boolean
   is (Count > 0
       and then Length <= Last_Count - Count
       and then Length > Capacity - Count)
   with Ghost => Static, Global => null;
   --  Inserting Count items fits within Last_Count but exceeds the allocated
   --  capacity. How to react to that is the caller's decision, so no
   --  operation here mentions this condition in its own contract.

   procedure Check_Insertion
     (Last       : Extended_Index;
      Before     : Extended_Index;
      Count      : Count_Type;
      New_Length : out Count_Type)
   with
     Global     => null,
     Exit_Cases =>
       (not Valid_Index_For_Insertion (Last, Before)
        or Exceeds_Last_Count (To_Array_Index (Last), Count) =>
          (Exception_Raised => Constraint_Error),
        others                                               => Normal_Return),
     Pre        => (Static => Last <= No_Index + Count_Type'Pos (Last_Count)),
     Post       =>
       (Static =>
          New_Length >= Count
          and then New_Length - Count = To_Array_Index (Last)),
     Inline;
   --  Validate an insertion of Count items before index Before and report the
   --  resulting length. Raises Constraint_Error if Before is not a valid
   --  insertion point or if the insertion would push the length past
   --  Last_Count. The capacity decision is left to the caller, which is the
   --  only one that can grow an array.

   function Equal
     (Left       : Elements_Array;
      Left_Last  : Extended_Index;
      Right      : Elements_Array;
      Right_Last : Extended_Index) return Boolean
   with
     Global => null,
     Pre    =>
       (Static =>
          Valid_Elements (Left, Left_Last)
          and then Valid_Elements (Right, Right_Last)),
     Inline;
   --  Compare the used prefixes element by element. The caller handles the
   --  identity guard before comparing elements.

   function Element
     (E : Elements_Array; Last : Extended_Index; Index : Extended_Index)
      return Element_Type
   with
     Side_Effects,
     Global     => null,
     Pre        => (Static => Valid_Elements (E, Last)),
     Exit_Cases =>
       ((Index in Index_Type'First .. Last) => Normal_Return,
        others                              =>
          (Exception_Raised => Constraint_Error)),
     Inline;
   --  Return a copy of the element at Index, raising Constraint_Error if
   --  Index is outside the used prefix.

   function First_Element
     (E : Elements_Array; Last : Extended_Index) return Element_Type
   with
     Side_Effects,
     Global     => null,
     Pre        => (Static => Valid_Elements (E, Last)),
     Exit_Cases =>
       (Last = No_Index => (Exception_Raised => Constraint_Error),
        others          => Normal_Return),
     Inline;
   --  Return a copy of the first element, raising Constraint_Error for an
   --  empty vector.

   function Last_Element
     (E : Elements_Array; Last : Extended_Index) return Element_Type
   with
     Side_Effects,
     Global     => null,
     Pre        => (Static => Valid_Elements (E, Last)),
     Exit_Cases =>
       (Last = No_Index => (Exception_Raised => Constraint_Error),
        others          => Normal_Return),
     Inline;
   --  Return a copy of the last element, raising Constraint_Error for an
   --  empty vector.

   procedure Swap
     (E : in out Elements_Array; Last : Extended_Index; I, J : Index_Type)
   with
     Global => null,
     Pre    =>
       (Static =>
          Valid_Elements (E, Last) and then I <= Last and then J <= Last),
     Post   => (Static => Valid_Elements (E, Last)),
     Inline;
   --  Exchange two used cells. The caller validates the indices before
   --  mutating owning storage.

   function Find_Index
     (E     : Elements_Array;
      Last  : Extended_Index;
      Item  : Element_Type;
      Index : Index_Type := Index_Type'First) return Extended_Index
   with
     Global => null,
     Pre    => (Static => Valid_Elements (E, Last)),
     Post   =>
       (Static =>
          Find_Index'Result = No_Index
          or else Find_Index'Result in Index .. Last);
   --  Search Index .. Last for the first element equal to Item, returning
   --  No_Index if none is found. The Post states only the result range; the
   --  model-based specification lives in the container.

   function Reverse_Find_Index
     (E     : Elements_Array;
      Last  : Extended_Index;
      Item  : Element_Type;
      Index : Index_Type := Index_Type'Last) return Extended_Index
   with
     Global => null,
     Pre    => (Static => Valid_Elements (E, Last)),
     Post   =>
       (Static =>
          Reverse_Find_Index'Result = No_Index
          or else
            Reverse_Find_Index'Result
            in Index_Type'First .. Index_Type'Min (Last, Index));
   --  Search backwards from the smaller of Index and Last for an element
   --  equal to Item, returning No_Index if none is found.

   procedure Reverse_Elements
     (E : in out Elements_Array; Last : Extended_Index)
   with
     Global => null,
     Pre    => (Static => Valid_Elements (E, Last)),
     Post   => (Static => Valid_Elements (E, Last)),
     Inline;
   --  Reverse the used prefix, leaving the last index and unused cells
   --  unchanged. Exchange preserves initialization and reclamation.

   procedure Replace_Element
     (E        : in out Elements_Array;
      Last     : Extended_Index;
      Index    : Index_Type;
      New_Item : Element_Type)
   with
     Global => null,
     Pre    => (Static => Valid_Elements (E, Last) and then Index <= Last),
     Post   => (Static => Valid_Elements (E, Last)),
     Inline;
   --  Replace the cell at Index after the caller has validated the index.
   --  Reclaim the old element before filling the cell with New_Item.

   procedure Insert_Internal
     (E        : in out Elements_Array;
      Last     : in out Extended_Index;
      Before   : Extended_Index;
      New_Item : Element_Type;
      Count    : Count_Type)
   with
     Global => null,
     Pre    =>
       (Static =>
          E'Last in Capacity_Range
          and then Valid_Elements (E, Last)
          and then Valid_Index_For_Insertion (Last, Before)
          and then not Exceeds_Last_Count (To_Array_Index (Last), Count)
          and then
            not Exceeds_Capacity (To_Array_Index (Last), E'Last, Count)),
     Post   =>
       (Static =>
          Valid_Elements (E, Last)
          and then To_Array_Index (Last) = To_Array_Index (Last'Old) + Count),
     Inline;
   --  Insert Count copies of New_Item before index Before, sliding the cells
   --  from Before upwards to make room, and report the grown last index. The
   --  caller has already validated the insertion with Check_Insertion and
   --  taken the capacity decision, which only it can take. Count = 0 is a
   --  no-op.
   --
   --  Relocation leaves reclaimed cells that Fill makes readable before the
   --  operation returns. Valid_Elements holds at both call boundaries, so a
   --  caller's container predicate never observes an open hole.

   procedure Insert_Slice
     (E           : in out Elements_Array;
      Last        : in out Extended_Index;
      Before      : Extended_Index;
      Source      : Elements_Array;
      Source_Last : Extended_Index)
   with
     Global => null,
     Pre    =>
       (Static =>
          E'Last in Capacity_Range
          and then Valid_Elements (E, Last)
          and then Valid_Elements (Source, Source_Last)
          and then Valid_Index_For_Insertion (Last, Before)
          and then
            not Exceeds_Last_Count
                  (To_Array_Index (Last), To_Array_Index (Source_Last))
          and then
            not Exceeds_Capacity
                  (To_Array_Index (Last),
                   E'Last,
                   To_Array_Index (Source_Last))),
     Post   =>
       (Static =>
          Valid_Elements (E, Last)
          and then
            To_Array_Index (Last)
            = To_Array_Index (Last'Old) + To_Array_Index (Source_Last)),
     Inline;
   --  Insert the used prefix of Source before index Before, sliding the cells
   --  from Before upwards to make room, and report the grown last index. As
   --  for Insert_Internal, the slide and the copy happen in one operation. An
   --  empty Source is a no-op.

   procedure Assign
     (E           : in out Elements_Array;
      Last        : in out Extended_Index;
      Source      : Elements_Array;
      Source_Last : Extended_Index)
   with
     Global => null,
     Pre    =>
       (Static =>
          Valid_Elements (E, Last)
          and then Valid_Elements (Source, Source_Last)
          and then To_Array_Index (Source_Last) <= E'Last),
     Post   =>
       (Static => Valid_Elements (E, Last) and then Last = Source_Last),
     Inline;
   --  Reclaim the used range and replace it with independent copies of the
   --  used prefix of Source. The caller handles identity and capacity checks.

   procedure Clear (E : in out Elements_Array; Last : in out Extended_Index)
   with
     Global  => null,
     Depends => (Last => null, E => (E, Last)),
     Pre     => (Static => Valid_Elements (E, Last)),
     Post    => (Static => Valid_Elements (E, Last) and then Last = No_Index),
     Inline;
   --  Reclaim the used range and reset Last

   procedure Check_Deletion (Last : Extended_Index; Index : Extended_Index)
   with
     Global     => null,
     Pre        => (Static => Last <= No_Index + Count_Type'Pos (Last_Count)),
     Exit_Cases =>
       (Valid_Index_For_Insertion (Last, Index) => Normal_Return,
        others                                  =>
          (Exception_Raised => Constraint_Error)),
     Post       => (Static => Valid_Index_For_Insertion (Last, Index)),
     Inline;
   --  Validate a deletion index, allowing the position immediately after
   --  Last for a no-op. Other invalid indices raise Constraint_Error.

   procedure Delete_Internal
     (E     : in out Elements_Array;
      Last  : in out Extended_Index;
      Index : Extended_Index;
      Count : Count_Type)
   with
     Global => null,
     Pre    =>
       (Static =>
          Valid_Elements (E, Last)
          and then Valid_Index_For_Insertion (Last, Index)),
     Post   => (Static => Valid_Elements (E, Last) and then Last <= Last'Old),
     Inline;
   --  Delete up to Count elements starting at Index, reclaiming them before
   --  sliding the remaining suffix down. The caller has validated Index with
   --  Check_Deletion; the position immediately after Last is a no-op.

   procedure Delete_First
     (E     : in out Elements_Array;
      Last  : in out Extended_Index;
      Count : Count_Type := 1)
   with
     Global => null,
     Pre    => (Static => Valid_Elements (E, Last)),
     Post   => (Static => Valid_Elements (E, Last) and then Last <= Last'Old),
     Inline;
   --  Delete up to Count elements from the front, clearing the vector when
   --  Count is at least its length.

   procedure Delete_Last
     (E     : in out Elements_Array;
      Last  : in out Extended_Index;
      Count : Count_Type := 1)
   with
     Global => null,
     Pre    => (Static => Valid_Elements (E, Last)),
     Post   => (Static => Valid_Elements (E, Last) and then Last <= Last'Old),
     Inline;
   --  Reclaim up to Count elements from the back and shorten the used prefix

   generic
      with function "<" (Left, Right : Element_Type) return Boolean is <>;
   package Generic_Sorting with SPARK_Mode, Always_Terminates is
      function Is_Sorted
        (E : Elements_Array; Last : Extended_Index) return Boolean
      with Global => null, Pre => (Static => Valid_Elements (E, Last)), Inline;

      procedure Merge
        (Target      : in out Elements_Array;
         Target_Last : in out Extended_Index;
         Source      : in out Elements_Array;
         Source_Last : in out Extended_Index)
      with
        Global => null,
        Pre    =>
          (Static =>
             Target'Last in Capacity_Range
             and then Valid_Elements (Target, Target_Last)
             and then Valid_Elements (Source, Source_Last)
             and then
               not Exceeds_Last_Count
                     (To_Array_Index (Target_Last),
                      To_Array_Index (Source_Last))
             and then
               not Exceeds_Capacity
                     (To_Array_Index (Target_Last),
                      Target'Last,
                      To_Array_Index (Source_Last))),
        Post   =>
          (Static =>
             Valid_Elements (Target, Target_Last)
             and then Valid_Elements (Source, Source_Last)
             and then Source_Last = No_Index
             and then
               To_Array_Index (Target_Last)
               = To_Array_Index (Target_Last'Old)
                 + To_Array_Index (Source_Last'Old)),
        Inline;
      --  Merge the used prefixes into Target and empty Source. The caller
      --  checks container identity and reserves enough capacity first.

      procedure Sort (E : in out Elements_Array; Last : Extended_Index)
      with
        Global => null,
        Pre    => (Static => Valid_Elements (E, Last)),
        Post   => (Static => Valid_Elements (E, Last)),
        Inline;
      --  Sort the used prefix with heapsort, leaving its length unchanged
   end Generic_Sorting;

   pragma Inline (Find_Index);
   pragma Inline (Reverse_Find_Index);

end SPARK.Containers.Formal.Generic_Vector_Operations;
