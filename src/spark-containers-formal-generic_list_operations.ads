--
--  Copyright (C) 2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  List algorithms over separate arrays of links and element holders.
--  Storage supplies the link representation and its structural model;
--  the formal subprograms supply element access, copying, transfer and
--  reclamation. This lets the same algorithms work with inline elements
--  or holders that own separately allocated elements.
--
--  Operations receive the arrays and list bookkeeping separately, so link
--  updates leave element storage untouched. Contracts preserve the list
--  structure and track which holders are initialized or reclaimed,
--  independently of element values.
--
--  Callers provide sufficient storage and handle container-level capacity
--  and alias checks.

pragma Ada_2022;

with SPARK.Containers.Formal.Generic_List_Storage;
with SPARK.Containers.Functional.Maps;
with SPARK.Containers.Functional.Vectors;
with SPARK.Containers.Types; use SPARK.Containers.Types;

private generic
   type Element_Type (<>) is private;
   with function "=" (Left, Right : Element_Type) return Boolean is <>;
   type Holder_Type is private;
   with package Storage is new Generic_List_Storage (Holder_Type);
   with
     function Is_Initialized (H : Holder_Type) return Boolean
     with Ghost => Static;
   --  Whether H contains an initialized element that can be read

   with
     function Is_Reclaimed (H : Holder_Type) return Boolean
     with Ghost => Static;
   --  Whether H holds no resources requiring reclamation before reuse

   with
     function Constant_Access
       (H : aliased Holder_Type) return not null access constant Element_Type;
   --  Read an inline or owning element without copying it

   with procedure Fill (H : out Holder_Type; Item : Element_Type);
   --  Initialize H with a copy of Item

   with procedure Reclaim (H : in out Holder_Type);
   --  Release any resources owned by H

   with
     procedure Move_Element
       (Source : in out Holder_Type; Target : in out Holder_Type);
   --  Transfer the element to Target, leaving Source reclaimed

   with
     procedure Copy_Elements
       (Target : in out Storage.Elements_Array;
        Source : Storage.Elements_Array;
        Nodes  : Storage.Node_Array;
        Free   : Count_Type'Base);
   --  Copy elements at their original indices; Nodes and Free identify live
   --  elements.

   with
     procedure Exchange
       (Elements : in out Storage.Elements_Array; I, J : Count_Type);
   --  Swap the elements at I and J without changing the other holders

package SPARK.Containers.Formal.Generic_List_Operations with
    SPARK_Mode,
    Always_Terminates
is
   use Storage;
   use Storage.Structural_Model;
   use Storage.Structural_Model.Node_Reachability;

   function Valid_Elements
     (Nodes    : Node_Array;
      Elements : Elements_Array;
      Free     : Count_Type'Base;
      Extra    : Count_Type := 0) return Boolean
   is (Elements'First = Nodes'First
       and then Elements'Last = Nodes'Last
       and then
         (for all I in Elements'Range =>
            (if I = Extra
               or else
                 ((Free >= 0 or else I <= -(Free + 1))
                  and then Nodes (I).Prev /= -1)
             then Is_Initialized (Elements (I))
             else Is_Reclaimed (Elements (I)))))
   with Ghost => Static, Pre => Valid_Links (Nodes, Free);
   --  Allocated elements are initialized. Free and untouched cells are
   --  reclaimed.

   procedure Assign
     (Target_Nodes    : in out Node_Array;
      Target_Elements : in out Elements_Array;
      Target_Free     : in out Count_Type'Base;
      Target_First    : in out Count_Type;
      Target_Last     : in out Count_Type;
      Target_Length   : in out Count_Type;
      Source_Nodes    : Node_Array;
      Source_Elements : Elements_Array;
      Source_Free     : Count_Type'Base;
      Source_First    : Count_Type;
      Source_Last     : Count_Type;
      Source_Length   : Count_Type)
   with
     Global => null,
     Pre    =>
       (Static =>
          Structural_Invariant
            (Target_Nodes,
             Target_Free,
             Target_First,
             Target_Last,
             Target_Length)
          and then Valid_Elements (Target_Nodes, Target_Elements, Target_Free)
          and then
            Structural_Invariant
              (Source_Nodes,
               Source_Free,
               Source_First,
               Source_Last,
               Source_Length)
          and then Valid_Elements (Source_Nodes, Source_Elements, Source_Free)
          and then Source_Length <= Target_Nodes'Last),
     Post   =>
       (Static =>
          Structural_Invariant
            (Target_Nodes,
             Target_Free,
             Target_First,
             Target_Last,
             Target_Length)
          and then Valid_Elements (Target_Nodes, Target_Elements, Target_Free)
          and then Target_Length = Source_Length);
   --  Clear the target, then copy the source elements in traversal order

   procedure Clear
     (Nodes    : in out Node_Array;
      Elements : in out Elements_Array;
      Free     : in out Count_Type'Base;
      First    : in out Count_Type;
      Last     : in out Count_Type;
      Length   : in out Count_Type)
   with
     Global => null,
     Pre    =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Length)
          and then Valid_Elements (Nodes, Elements, Free)),
     Post   =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Length)
          and then Valid_Elements (Nodes, Elements, Free)
          and then Length = 0);
   --  Unlink and reclaim every element, leaving an empty list

   procedure Copy
     (Target_Nodes    : in out Node_Array;
      Target_Elements : in out Elements_Array;
      Target_Free     : in out Count_Type'Base;
      Target_First    : out Count_Type;
      Target_Last     : out Count_Type;
      Target_Length   : out Count_Type;
      Source_Nodes    : Node_Array;
      Source_Elements : Elements_Array;
      Source_Free     : Count_Type'Base;
      Source_First    : Count_Type;
      Source_Last     : Count_Type;
      Source_Length   : Count_Type)
   with
     Global => null,
     Pre    =>
       (Static =>
          Target_Nodes'First = 1
          and then Target_Nodes'Last in Count_Type
          and then Target_Elements'First = Target_Nodes'First
          and then Target_Elements'Last = Target_Nodes'Last
          and then Target_Free = -1
          and then (for all H of Target_Elements => Is_Reclaimed (H))
          and then
            Structural_Invariant
              (Source_Nodes,
               Source_Free,
               Source_First,
               Source_Last,
               Source_Length)
          and then Valid_Elements (Source_Nodes, Source_Elements, Source_Free)
          and then Source_Nodes'Last <= Target_Nodes'Last),
     Post   =>
       (Static =>
          Structural_Invariant
            (Target_Nodes,
             Target_Free,
             Target_First,
             Target_Last,
             Target_Length)
          and then Valid_Elements (Target_Nodes, Target_Elements, Target_Free)
          and then Target_Length = Source_Length);
   --  Copy the storage and extend its free list into any extra capacity

   procedure Delete
     (Nodes    : in out Node_Array;
      Elements : in out Elements_Array;
      Free     : in out Count_Type'Base;
      First    : in out Count_Type;
      Last     : in out Count_Type;
      Length   : in out Count_Type;
      X        : Count_Type)
   with
     Global => null,
     Pre    =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Length)
          and then Valid_Elements (Nodes, Elements, Free)
          and then X in Memory (Nodes, Free)'Range
          and then
            Memory_Index_Sets.Contains (Active_Set (Nodes, Free, First), X)),
     Post   =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Length)
          and then Valid_Elements (Nodes, Elements, Free)
          and then Length = Length'Old - 1
          and then
            Is_Add
              (Active_Set (Nodes, Free, First),
               Active_Set (Nodes'Old, Free'Old, First'Old),
               X));
   --  Unlink and reclaim the active node X

   procedure Delete
     (Nodes    : in out Node_Array;
      Elements : in out Elements_Array;
      Free     : in out Count_Type'Base;
      First    : in out Count_Type;
      Last     : in out Count_Type;
      Length   : in out Count_Type;
      Position : in out Count_Type;
      Count    : Count_Type)
   with
     Global => null,
     Pre    =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Length)
          and then Valid_Elements (Nodes, Elements, Free)
          and then Position in Memory (Nodes, Free)'Range
          and then
            Memory_Index_Sets.Contains
              (Active_Set (Nodes, Free, First), Position)),
     Post   =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Length)
          and then Valid_Elements (Nodes, Elements, Free)
          and then Position = 0);
   --  Delete up to Count nodes starting at Position, then clear Position

   procedure Delete_First
     (Nodes    : in out Node_Array;
      Elements : in out Elements_Array;
      Free     : in out Count_Type'Base;
      First    : in out Count_Type;
      Last     : in out Count_Type;
      Length   : in out Count_Type;
      Count    : Count_Type)
   with
     Global => null,
     Pre    =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Length)
          and then Valid_Elements (Nodes, Elements, Free)),
     Post   =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Length)
          and then Valid_Elements (Nodes, Elements, Free));
   --  Unlink and reclaim up to Count nodes from the head

   procedure Delete_Last
     (Nodes    : in out Node_Array;
      Elements : in out Elements_Array;
      Free     : in out Count_Type'Base;
      First    : in out Count_Type;
      Last     : in out Count_Type;
      Length   : in out Count_Type;
      Count    : Count_Type)
   with
     Global => null,
     Pre    =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Length)
          and then Valid_Elements (Nodes, Elements, Free)),
     Post   =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Length)
          and then Valid_Elements (Nodes, Elements, Free));
   --  Unlink and reclaim up to Count nodes from the tail

   function Element
     (Elements : Elements_Array; X : Count_Type) return Element_Type
   with
     Global => null,
     Pre    =>
       (Static => X in Elements'Range and then Is_Initialized (Elements (X)));
   --  Return a copy of the element at X

   function Equal
     (Left_Nodes     : Node_Array;
      Left_Elements  : Elements_Array;
      Left_Free      : Count_Type'Base;
      Left_First     : Count_Type;
      Left_Last      : Count_Type;
      Left_Length    : Count_Type;
      Right_Nodes    : Node_Array;
      Right_Elements : Elements_Array;
      Right_Free     : Count_Type'Base;
      Right_First    : Count_Type;
      Right_Last     : Count_Type;
      Right_Length   : Count_Type) return Boolean
   with
     Global => null,
     Pre    =>
       (Static =>
          Structural_Invariant
            (Left_Nodes, Left_Free, Left_First, Left_Last, Left_Length)
          and then Valid_Elements (Left_Nodes, Left_Elements, Left_Free)
          and then
            Structural_Invariant
              (Right_Nodes, Right_Free, Right_First, Right_Last, Right_Length)
          and then Valid_Elements (Right_Nodes, Right_Elements, Right_Free));
   --  Compare active elements in traversal order using the supplied equality

   function Find
     (Nodes    : Node_Array;
      Elements : Elements_Array;
      Free     : Count_Type'Base;
      First    : Count_Type;
      Last     : Count_Type;
      Length   : Count_Type;
      Item     : Element_Type;
      Position : Count_Type) return Count_Type
   with
     Global => null,
     Pre    =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Length)
          and then Valid_Elements (Nodes, Elements, Free)
          and then
            (Position = 0
             or else
               Memory_Index_Sets.Contains
                 (Active_Set (Nodes, Free, First), Position)));
   --  Search forward from Position, or First when Position is zero

   generic
      type Cursor_Type is private;
      with
        function To_Cursor (Index : Count_Type) return Cursor_Type
        with Ghost => SPARKlib_Logic;
      --  Convert a node index to its public cursor

      with
        function Node (Position : Cursor_Type) return Count_Type
        with Ghost => SPARKlib_Logic;
      --  Retrieve the node index represented by Position

      --!format off
      with package M is new
        SPARK.Containers.Functional.Vectors
          (Index_Type   => Positive_Count_Type,
           Element_Type => Element_Type,
           others       => <>)
        with Ghost => SPARKlib_Logic;
      with package P is new
        SPARK.Containers.Functional.Maps
          (Key_Type     => Cursor_Type,
           Element_Type => Positive_Count_Type,
           others       => <>)
        with Ghost => SPARKlib_Logic;
      --!format on
   package Generic_Model with Ghost => SPARKlib_Logic is

      generic
         with function "<" (Left, Right : Element_Type) return Boolean is <>;
      package Generic_Sorting is
         function M_Elements_Sorted (Container : M.Sequence) return Boolean
         with Global => null;
      end Generic_Sorting;

      function M_Elements_In_Union
        (Container, Left, Right : M.Sequence) return Boolean
      with Ghost => SPARKlib_Full, Global => null;

      function M_Elements_Included
        (Left  : M.Sequence;
         L_Fst : Positive_Count_Type := 1;
         L_Lst : Count_Type;
         Right : M.Sequence;
         R_Fst : Positive_Count_Type := 1;
         R_Lst : Count_Type) return Boolean
      with Ghost => SPARKlib_Full, Global => null;

      function M_Elements_Reversed (Left, Right : M.Sequence) return Boolean
      with Ghost => SPARKlib_Full, Global => null;

      function M_Elements_Swapped
        (Left, Right : M.Sequence; X, Y : Positive_Count_Type) return Boolean
      with Ghost => SPARKlib_Full, Global => null;

      function Mapping_Preserved
        (M_Left, M_Right : M.Sequence; P_Left, P_Right : P.Map) return Boolean
      with Ghost => SPARKlib_Full, Global => null;

      function Model
        (Nodes    : Node_Array;
         Elements : Elements_Array;
         Free     : Count_Type'Base;
         First    : Count_Type;
         Last     : Count_Type;
         Length   : Count_Type) return M.Sequence
      with
        Global => null,
        Pre    =>
          (Static =>
             Structural_Invariant (Nodes, Free, First, Last, Length)
             and then Valid_Elements (Nodes, Elements, Free));
      --  The sequence of active elements in traversal order

      function P_Positions_Shifted
        (Small, Big : P.Map;
         Cut        : Positive_Count_Type;
         Count      : Count_Type := 1) return Boolean
      with Global => null;

      function P_Positions_Swapped
        (Left, Right : P.Map; X, Y : Cursor_Type) return Boolean
      with Global => null;

      function P_Positions_Truncated
        (Small, Big : P.Map;
         Cut        : Positive_Count_Type;
         Count      : Count_Type := 1) return Boolean
      with Global => null;

      function Positions
        (Nodes  : Node_Array;
         Free   : Count_Type'Base;
         First  : Count_Type;
         Last   : Count_Type;
         Length : Count_Type) return P.Map
      with
        Global => null,
        Pre    =>
          (Static => Structural_Invariant (Nodes, Free, First, Last, Length));
      --  Map each active cursor to its one-based traversal position

   end Generic_Model;

   generic
      with function "<" (Left, Right : Element_Type) return Boolean is <>;
   package Generic_Sorting with SPARK_Mode, Always_Terminates is

      function Is_Sorted
        (Nodes    : Node_Array;
         Elements : Elements_Array;
         Free     : Count_Type'Base;
         First    : Count_Type;
         Last     : Count_Type;
         Length   : Count_Type) return Boolean
      with
        Global => null,
        Pre    =>
          (Static =>
             Structural_Invariant (Nodes, Free, First, Last, Length)
             and then Valid_Elements (Nodes, Elements, Free));
      --  Check whether adjacent active elements are in nondecreasing order

      procedure Merge
        (Target_Nodes    : in out Node_Array;
         Target_Elements : in out Elements_Array;
         Target_Free     : in out Count_Type'Base;
         Target_First    : in out Count_Type;
         Target_Last     : in out Count_Type;
         Target_Length   : in out Count_Type;
         Source_Nodes    : in out Node_Array;
         Source_Elements : in out Elements_Array;
         Source_Free     : in out Count_Type'Base;
         Source_First    : in out Count_Type;
         Source_Last     : in out Count_Type;
         Source_Length   : in out Count_Type)
      with
        Global => null,
        Pre    =>
          (Static =>
             Structural_Invariant
               (Target_Nodes,
                Target_Free,
                Target_First,
                Target_Last,
                Target_Length)
             and then
               Valid_Elements (Target_Nodes, Target_Elements, Target_Free)
             and then
               Structural_Invariant
                 (Source_Nodes,
                  Source_Free,
                  Source_First,
                  Source_Last,
                  Source_Length)
             and then
               Valid_Elements (Source_Nodes, Source_Elements, Source_Free)
             and then Target_Length <= Count_Type'Last - Source_Length
             and then Target_Length + Source_Length <= Target_Nodes'Last),
        Post   =>
          (Static =>
             Structural_Invariant
               (Target_Nodes,
                Target_Free,
                Target_First,
                Target_Last,
                Target_Length)
             and then
               Valid_Elements (Target_Nodes, Target_Elements, Target_Free)
             and then
               Structural_Invariant
                 (Source_Nodes,
                  Source_Free,
                  Source_First,
                  Source_Last,
                  Source_Length)
             and then
               Valid_Elements (Source_Nodes, Source_Elements, Source_Free));
      --  Merge sorted source elements into the target, then empty the source

      procedure Sort
        (Nodes    : in out Node_Array;
         Elements : Elements_Array;
         Free     : Count_Type'Base;
         First    : in out Count_Type;
         Last     : in out Count_Type;
         Length   : Count_Type)
      with
        Global => null,
        Pre    =>
          (Static =>
             Structural_Invariant (Nodes, Free, First, Last, Length)
             and then Valid_Elements (Nodes, Elements, Free)),
        Post   =>
          (Static =>
             Structural_Invariant (Nodes, Free, First, Last, Length)
             and then Valid_Elements (Nodes, Elements, Free));
      --  Stably sort the active list by relinking its nodes

   end Generic_Sorting;

   procedure Insert
     (Nodes    : in out Node_Array;
      Elements : in out Elements_Array;
      Free     : in out Count_Type'Base;
      First    : in out Count_Type;
      Last     : in out Count_Type;
      Length   : in out Count_Type;
      Before   : Count_Type;
      New_Item : Element_Type;
      Position : out Count_Type;
      Count    : Count_Type)
   with
     Inline,
     Global => null,
     Pre    =>
       (Static =>
          Count > 0
          and then Structural_Invariant (Nodes, Free, First, Last, Length)
          and then Valid_Elements (Nodes, Elements, Free)
          and then
            (Before = 0
             or else
               Memory_Index_Sets.Contains
                 (Active_Set (Nodes, Free, First), Before))
          and then Length <= Count_Type'Last - Count
          and then Length + Count <= Nodes'Last),
     Post   =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Length)
          and then Valid_Elements (Nodes, Elements, Free)
          and then Length = Length'Old + Count
          and then
            (Before = 0
             or else
               Memory_Index_Sets.Contains
                 (Active_Set (Nodes, Free, First), Before)));
   --  Insert Count copies before Before, or append when Before is zero

   procedure Move
     (Target_Nodes    : in out Node_Array;
      Target_Elements : in out Elements_Array;
      Target_Free     : in out Count_Type'Base;
      Target_First    : in out Count_Type;
      Target_Last     : in out Count_Type;
      Target_Length   : in out Count_Type;
      Source_Nodes    : in out Node_Array;
      Source_Elements : in out Elements_Array;
      Source_Free     : in out Count_Type'Base;
      Source_First    : in out Count_Type;
      Source_Last     : in out Count_Type;
      Source_Length   : in out Count_Type)
   with
     Inline,
     Global => null,
     Pre    =>
       (Static =>
          Structural_Invariant
            (Target_Nodes,
             Target_Free,
             Target_First,
             Target_Last,
             Target_Length)
          and then Valid_Elements (Target_Nodes, Target_Elements, Target_Free)
          and then
            Structural_Invariant
              (Source_Nodes,
               Source_Free,
               Source_First,
               Source_Last,
               Source_Length)
          and then Valid_Elements (Source_Nodes, Source_Elements, Source_Free)
          and then Source_Length <= Target_Nodes'Last),
     Post   =>
       (Static =>
          Structural_Invariant
            (Target_Nodes,
             Target_Free,
             Target_First,
             Target_Last,
             Target_Length)
          and then Valid_Elements (Target_Nodes, Target_Elements, Target_Free)
          and then
            Structural_Invariant
              (Source_Nodes,
               Source_Free,
               Source_First,
               Source_Last,
               Source_Length)
          and then Valid_Elements (Source_Nodes, Source_Elements, Source_Free)
          and then Target_Length = Source_Length'Old
          and then Source_Length = 0);
   --  Clear the target, then copy and reclaim the source elements in order

   procedure Replace_Element (H : in out Holder_Type; New_Item : Element_Type)
   with
     Global => null,
     Pre    => (Static => Is_Initialized (H)),
     Post   => (Static => Is_Initialized (H));
   --  Reclaim the previous element, then fill H with a copy of New_Item

   procedure Reverse_Elements
     (Nodes : in out Node_Array;
      Free  : Count_Type'Base;
      First : in out Count_Type;
      Last  : in out Count_Type;
      Count : Count_Type)
   with
     Global => null,
     Pre    =>
       (Static => Structural_Invariant (Nodes, Free, First, Last, Count)),
     Post   =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Count)
          and then
            Memory_Index_Sets."="
              (Active_Set (Nodes, Free, First),
               Active_Set (Nodes'Old, Free, First'Old)));
   --  Reverse the links of the active list

   function Reverse_Find
     (Nodes    : Node_Array;
      Elements : Elements_Array;
      Free     : Count_Type'Base;
      First    : Count_Type;
      Last     : Count_Type;
      Length   : Count_Type;
      Item     : Element_Type;
      Position : Count_Type) return Count_Type
   with
     Global => null,
     Pre    =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Length)
          and then Valid_Elements (Nodes, Elements, Free)
          and then
            (Position = 0
             or else
               Memory_Index_Sets.Contains
                 (Active_Set (Nodes, Free, First), Position)));
   --  Search backward from Position, or Last when Position is zero

   procedure Splice
     (Target_Nodes    : in out Node_Array;
      Target_Elements : in out Elements_Array;
      Target_Free     : in out Count_Type'Base;
      Target_First    : in out Count_Type;
      Target_Last     : in out Count_Type;
      Target_Length   : in out Count_Type;
      Source_Nodes    : in out Node_Array;
      Source_Elements : in out Elements_Array;
      Source_Free     : in out Count_Type'Base;
      Source_First    : in out Count_Type;
      Source_Last     : in out Count_Type;
      Source_Length   : in out Count_Type;
      Before          : Count_Type)
   with
     Global => null,
     Pre    =>
       (Static =>
          Structural_Invariant
            (Target_Nodes,
             Target_Free,
             Target_First,
             Target_Last,
             Target_Length)
          and then Valid_Elements (Target_Nodes, Target_Elements, Target_Free)
          and then
            Structural_Invariant
              (Source_Nodes,
               Source_Free,
               Source_First,
               Source_Last,
               Source_Length)
          and then Valid_Elements (Source_Nodes, Source_Elements, Source_Free)
          and then
            (Before = 0
             or else
               Memory_Index_Sets.Contains
                 (Active_Set (Target_Nodes, Target_Free, Target_First),
                  Before))
          and then Target_Length <= Count_Type'Last - Source_Length
          and then Target_Length + Source_Length <= Target_Nodes'Last),
     Post   =>
       (Static =>
          Structural_Invariant
            (Target_Nodes,
             Target_Free,
             Target_First,
             Target_Last,
             Target_Length)
          and then Valid_Elements (Target_Nodes, Target_Elements, Target_Free)
          and then
            Structural_Invariant
              (Source_Nodes,
               Source_Free,
               Source_First,
               Source_Last,
               Source_Length)
          and then Valid_Elements (Source_Nodes, Source_Elements, Source_Free)
          and then Target_Length = Target_Length'Old + Source_Length'Old
          and then Source_Length = 0
          and then
            (Before = 0
             or else
               Memory_Index_Sets.Contains
                 (Active_Set (Target_Nodes, Target_Free, Target_First),
                  Before)));
   --  Move the source elements before Before, then release their source nodes

   procedure Splice
     (Target_Nodes    : in out Node_Array;
      Target_Elements : in out Elements_Array;
      Target_Free     : in out Count_Type'Base;
      Target_First    : in out Count_Type;
      Target_Last     : in out Count_Type;
      Target_Length   : in out Count_Type;
      Source_Nodes    : in out Node_Array;
      Source_Elements : in out Elements_Array;
      Source_Free     : in out Count_Type'Base;
      Source_First    : in out Count_Type;
      Source_Last     : in out Count_Type;
      Source_Length   : in out Count_Type;
      Before          : Count_Type;
      Position        : in out Count_Type)
   with
     Global => null,
     Pre    =>
       (Static =>
          Structural_Invariant
            (Target_Nodes,
             Target_Free,
             Target_First,
             Target_Last,
             Target_Length)
          and then Valid_Elements (Target_Nodes, Target_Elements, Target_Free)
          and then
            Structural_Invariant
              (Source_Nodes,
               Source_Free,
               Source_First,
               Source_Last,
               Source_Length)
          and then Valid_Elements (Source_Nodes, Source_Elements, Source_Free)
          and then
            (Before = 0
             or else
               Memory_Index_Sets.Contains
                 (Active_Set (Target_Nodes, Target_Free, Target_First),
                  Before))
          and then Position in Memory (Source_Nodes, Source_Free)'Range
          and then
            Memory_Index_Sets.Contains
              (Active_Set (Source_Nodes, Source_Free, Source_First), Position)
          and then Target_Length < Count_Type'Last
          and then Target_Length < Target_Nodes'Last),
     Post   =>
       (Static =>
          Structural_Invariant
            (Target_Nodes,
             Target_Free,
             Target_First,
             Target_Last,
             Target_Length)
          and then Valid_Elements (Target_Nodes, Target_Elements, Target_Free)
          and then
            Structural_Invariant
              (Source_Nodes,
               Source_Free,
               Source_First,
               Source_Last,
               Source_Length)
          and then Valid_Elements (Source_Nodes, Source_Elements, Source_Free)
          and then Target_Length = Target_Length'Old + 1
          and then Source_Length = Source_Length'Old - 1
          and then
            (Before = 0
             or else
               Memory_Index_Sets.Contains
                 (Active_Set (Target_Nodes, Target_Free, Target_First),
                  Before))
          and then
            Is_Add
              (Active_Set (Source_Nodes, Source_Free, Source_First),
               Active_Set
                 (Source_Nodes'Old, Source_Free'Old, Source_First'Old),
               Position'Old));
   --  Move Position before Before, release its source node, and update it

   procedure Splice
     (Nodes    : in out Node_Array;
      Free     : Count_Type'Base;
      First    : in out Count_Type;
      Last     : in out Count_Type;
      Count    : Count_Type;
      Before   : Count_Type;
      Position : Count_Type)
   with
     Global => null,
     Pre    =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Count)
          and then Before in Memory (Nodes, Free)'Range | 0
          and then
            (Before = 0
             or else
               Memory_Index_Sets.Contains
                 (Active_Set (Nodes, Free, First), Before))
          and then Position in Memory (Nodes, Free)'Range
          and then
            Memory_Index_Sets.Contains
              (Active_Set (Nodes, Free, First), Position)),
     Post   =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Count)
          and then
            Memory_Index_Sets."="
              (Active_Set (Nodes, Free, First),
               Active_Set (Nodes'Old, Free, First'Old)));
   --  Relink Position before Before, or at the end when Before is zero

   procedure Swap
     (Nodes    : Node_Array;
      Elements : in out Elements_Array;
      Free     : Count_Type'Base;
      I, J     : Count_Type)
   with
     Global => null,
     Pre    =>
       (Static =>
          Valid_Links (Nodes, Free)
          and then Valid_Elements (Nodes, Elements, Free)
          and then I in Elements'Range
          and then J in Elements'Range
          and then I /= J
          and then Is_Initialized (Elements (I))
          and then Is_Initialized (Elements (J))),
     Post   => (Static => Valid_Elements (Nodes, Elements, Free));
   --  Exchange two initialized elements without changing the links

   procedure Swap_Links
     (Nodes : in out Node_Array;
      Free  : Count_Type'Base;
      First : in out Count_Type;
      Last  : in out Count_Type;
      Count : Count_Type;
      I     : Count_Type;
      J     : Count_Type)
   with
     Global => null,
     Pre    =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Count)
          and then I in Memory (Nodes, Free)'Range
          and then J in Memory (Nodes, Free)'Range
          and then
            Memory_Index_Sets.Contains (Active_Set (Nodes, Free, First), I)
          and then
            Memory_Index_Sets.Contains (Active_Set (Nodes, Free, First), J)),
     Post   =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Count)
          and then
            Memory_Index_Sets."="
              (Active_Set (Nodes, Free, First),
               Active_Set (Nodes'Old, Free, First'Old)));
   --  Exchange two active nodes without changing their element storage

end SPARK.Containers.Formal.Generic_List_Operations;
