--
--  Copyright (C) 2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with SPARK.Big_Integers; use SPARK.Big_Integers;

package body SPARK.Containers.Formal.Generic_List_Operations
  with SPARK_Mode
is

   -----------------------
   -- Local Subprograms --
   -----------------------

   function Allocated
     (Nodes : Node_Array; Free : Count_Type'Base; I : Count_Type)
      return Boolean
   is ((Free >= 0 or else I <= -(Free + 1)) and then Nodes (I).Prev /= -1)
   with
     Ghost => Static,
     Pre   => Valid_Links (Nodes, Free) and then I in Nodes'Range;

   function Limbo_State
     (Nodes    : Node_Array;
      Free     : Count_Type'Base;
      First    : Count_Type;
      Last     : Count_Type;
      New_Node : Count_Type;
      Count    : Count_Type) return Boolean
   is (Valid_Links (Nodes, Free)
       and then Valid_Memory (Memory (Nodes, Free))
       and then First in Memory (Nodes, Free)'Range | 0
       and then New_Node in Memory (Nodes, Free)'Range
       and then Count < Nodes'Last
       and then Nodes (New_Node).Prev'Initialized
       and then Nodes (New_Node).Next'Initialized
       and then
         not Memory_Index_Sets.Contains
               (Active_Set (Nodes, Free, First), New_Node)
       and then Active_List_Valid (Nodes, Free, First, Last, Count)
       and then
         Free_Chain_Valid
           (Nodes,
            Free,
            Memory_Index_Sets.Add (Active_Set (Nodes, Free, First), New_Node))
       and then Free_Count_Correct (Nodes, Free, Count + 1)
       and then Covered (Nodes, Free, First, New_Node))
   with Ghost => Static;

   function Limbo_State
     (Nodes    : Node_Array;
      Elements : Elements_Array;
      Free     : Count_Type'Base;
      First    : Count_Type;
      Last     : Count_Type;
      New_Node : Count_Type;
      Count    : Count_Type) return Boolean
   is (Limbo_State (Nodes, Free, First, Last, New_Node, Count)
       and then Valid_Elements (Nodes, Elements, Free, New_Node)
       and then Is_Initialized (Elements (New_Node)))
   with Ghost => Static;
   --  New_Node is initialized and detached from both the active and free lists

   procedure Allocate
     (Nodes    : in out Node_Array;
      Elements : in out Elements_Array;
      Free     : in out Count_Type'Base;
      First    : Count_Type;
      Last     : Count_Type;
      Count    : Count_Type;
      New_Item : Element_Type;
      New_Node : out Count_Type)
   with
     Global => null,
     Pre    =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Count)
          and then Valid_Elements (Nodes, Elements, Free)
          and then Count < Nodes'Last),
     Post   =>
       (Static =>
          Limbo_State (Nodes, Elements, Free, First, Last, New_Node, Count)
          and then
            Memory_Index_Sets."="
              (Active_Set (Nodes, Free, First),
               Active_Set (Nodes'Old, Free'Old, First)));
   --  Take a reclaimed cell off the free list and fill its element

   procedure Detach_Node
     (Nodes  : in out Node_Array;
      Free   : Count_Type'Base;
      First  : in out Count_Type;
      Last   : in out Count_Type;
      Length : in out Count_Type;
      X      : Count_Type)
   with
     Inline,
     Global => null,
     Pre    =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Length)
          and then Length > 0
          and then X in Memory (Nodes, Free)'Range
          and then
            Memory_Index_Sets.Contains (Active_Set (Nodes, Free, First), X)),
     Post   =>
       (Static =>
          Limbo_State (Nodes, Free, First, Last, X, Length)
          and then Length = Length'Old - 1
          and then
            Is_Add
              (Active_Set (Nodes, Free, First),
               Active_Set (Nodes'Old, Free, First'Old),
               X));
   --  Detach an active node without changing its payload or free storage

   procedure Free
     (Nodes    : in out Node_Array;
      Elements : in out Elements_Array;
      Free     : in out Count_Type'Base;
      First    : Count_Type;
      Last     : Count_Type;
      Count    : Count_Type;
      X        : Count_Type)
   with
     Global => null,
     Pre    =>
       (Static =>
          Valid_Links (Nodes, Free)
          and then Valid_Memory (Memory (Nodes, Free))
          and then First in Memory (Nodes, Free)'Range | 0
          and then X in Memory (Nodes, Free)'Range
          and then Count < Nodes'Last
          and then
            not Memory_Index_Sets.Contains (Active_Set (Nodes, Free, First), X)
          and then Active_List_Valid (Nodes, Free, First, Last, Count)
          and then
            Free_Chain_Valid
              (Nodes,
               Free,
               Memory_Index_Sets.Add (Active_Set (Nodes, Free, First), X))
          and then Free_Count_Correct (Nodes, Free, Count + 1)
          and then Covered (Nodes, Free, First, X)
          and then Valid_Elements (Nodes, Elements, Free, X)),
     Post   =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Count)
          and then Valid_Elements (Nodes, Elements, Free)
          and then
            Memory_Index_Sets."="
              (Active_Set (Nodes, Free, First),
               Active_Set (Nodes'Old, Free'Old, First)));
   --  Reclaim a detached node and return it to the free store

   procedure Insert_First_Node
     (Nodes    : in out Node_Array;
      Free     : Count_Type'Base;
      First    : in out Count_Type;
      Last     : Count_Type;
      New_Node : Count_Type;
      Count    : Count_Type)
   with
     Inline,
     Global => null,
     Pre    =>
       (Static =>
          Limbo_State (Nodes, Free, First, Last, New_Node, Count)
          and then Count >= 1
          and then Count < Count_Type'Last),
     Post   =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Count + 1)
          and then First = New_Node
          and then
            Is_Add
              (Active_Set (Nodes'Old, Free, First'Old),
               Active_Set (Nodes, Free, First),
               New_Node));
   --  Link a detached node before the first node of a nonempty list

   procedure Insert_Interior_Node
     (Nodes    : in out Node_Array;
      Free     : Count_Type'Base;
      First    : Count_Type;
      Last     : Count_Type;
      Before   : Count_Type;
      New_Node : Count_Type;
      Count    : Count_Type)
   with
     Inline,
     Global => null,
     Pre    =>
       (Static =>
          Limbo_State (Nodes, Free, First, Last, New_Node, Count)
          and then Before in Memory (Nodes, Free)'Range
          and then
            Memory_Index_Sets.Contains
              (Active_Set (Nodes, Free, First), Before)
          and then Before /= First
          and then Count < Count_Type'Last),
     Post   =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Count + 1)
          and then
            Is_Add
              (Active_Set (Nodes'Old, Free, First),
               Active_Set (Nodes, Free, First),
               New_Node));
   --  Link a detached node before an active node other than First

   procedure Insert_Internal
     (Nodes    : in out Node_Array;
      Free     : Count_Type'Base;
      First    : in out Count_Type;
      Last     : in out Count_Type;
      Count    : in out Count_Type;
      Before   : Count_Type;
      New_Node : Count_Type)
   with
     Inline,
     Global => null,
     Pre    =>
       (Static =>
          Limbo_State (Nodes, Free, First, Last, New_Node, Count)
          and then
            (Before = 0
             or else
               Memory_Index_Sets.Contains
                 (Active_Set (Nodes, Free, First), Before))),
     Post   =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Count)
          and then Count = Count'Old + 1
          and then
            Is_Add
              (Active_Set (Nodes'Old, Free, First'Old),
               Active_Set (Nodes, Free, First),
               New_Node));
   --  Link a detached node before Before, or append when Before is zero

   procedure Insert_Last_Node
     (Nodes    : in out Node_Array;
      Free     : Count_Type'Base;
      First    : Count_Type;
      Last     : in out Count_Type;
      New_Node : Count_Type;
      Count    : Count_Type)
   with
     Inline,
     Global => null,
     Pre    =>
       (Static =>
          Limbo_State (Nodes, Free, First, Last, New_Node, Count)
          and then Count >= 1
          and then Count < Count_Type'Last),
     Post   =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Count + 1)
          and then Last = New_Node
          and then
            Is_Add
              (Active_Set (Nodes'Old, Free, First),
               Active_Set (Nodes, Free, First),
               New_Node));
   --  Link a detached node after the last node of a nonempty list

   procedure Insert_Moved
     (Nodes       : in out Node_Array;
      Elements    : in out Elements_Array;
      Free        : in out Count_Type'Base;
      First       : in out Count_Type;
      Last        : in out Count_Type;
      Length      : in out Count_Type;
      Before      : Count_Type;
      Source_Item : in out Holder_Type;
      Position    : out Count_Type)
   with
     Inline,
     Global => null,
     Pre    =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Length)
          and then Valid_Elements (Nodes, Elements, Free)
          and then Length < Nodes'Last
          and then
            (Before = 0
             or else
               Memory_Index_Sets.Contains
                 (Active_Set (Nodes, Free, First), Before))
          and then Is_Initialized (Source_Item)),
     Post   =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Length)
          and then Valid_Elements (Nodes, Elements, Free)
          and then Length = Length'Old + 1
          and then
            (Before = 0
             or else
               Memory_Index_Sets.Contains
                 (Active_Set (Nodes, Free, First), Before))
          and then Is_Reclaimed (Source_Item));
   --  Consume a source payload into a new node before Before

   procedure Lemma_Add_Length
     (S1, S2 : Memory_Index_Set; E : Positive_Count_Type)
   with
     Ghost => Static,
     Pre   => Is_Add (S1, S2, E),
     Post  =>
       Memory_Index_Sets.Length (S2) = Memory_Index_Sets.Length (S1) + 1;
   --  Adding exactly E increases the set cardinality by one

   procedure Release_Node
     (Nodes : in out Node_Array;
      Free  : in out Count_Type'Base;
      First : Count_Type;
      Last  : Count_Type;
      Count : Count_Type;
      X     : Count_Type)
   with
     Inline,
     Global => null,
     Pre    => (Static => Limbo_State (Nodes, Free, First, Last, X, Count)),
     Post   =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Count)
          and then
            Memory_Index_Sets."="
              (Active_Set (Nodes, Free, First),
               Active_Set (Nodes'Old, Free'Old, First))
          and then
            (for all I in Nodes'Range =>
               Allocated (Nodes, Free, I)
               = (I /= X and then Allocated (Nodes'Old, Free'Old, I))));
   --  Return a detached node to free storage without touching its payload

   procedure Reserve_Node
     (Nodes    : in out Node_Array;
      Free     : in out Count_Type'Base;
      First    : Count_Type;
      Last     : Count_Type;
      Count    : Count_Type;
      New_Node : Count_Type)
   with
     Inline,
     Global => null,
     Pre    =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Count)
          and then Count < Nodes'Last
          and then New_Node = (if Free >= 0 then Free else -Free)),
     Post   =>
       (Static =>
          Limbo_State (Nodes, Free, First, Last, New_Node, Count)
          and then
            Memory_Index_Sets."="
              (Active_Set (Nodes, Free, First),
               Active_Set (Nodes'Old, Free'Old, First))
          and then not Allocated (Nodes'Old, Free'Old, New_Node)
          and then
            (for all I in Nodes'Range =>
               Allocated (Nodes, Free, I)
               = Allocated (Nodes'Old, Free'Old, I)));
   --  Reserve the next free node without touching its payload

   procedure Unlink_First_Node
     (Nodes : in out Node_Array;
      Free  : Count_Type'Base;
      First : in out Count_Type;
      Last  : Count_Type;
      Count : Count_Type)
   with
     Inline,
     Global => null,
     Pre    =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Count)
          and then Count >= 2),
     Post   =>
       (Static =>
          Limbo_State (Nodes, Free, First, Last, First'Old, Count - 1)
          and then First'Old in Memory (Nodes, Free)'Range
          and then
            Is_Add
              (Active_Set (Nodes, Free, First),
               Active_Set (Nodes'Old, Free, First'Old),
               First'Old));
   --  Detach the head of a list with at least two nodes, preserving the count

   procedure Unlink_Interior_Node
     (Nodes : in out Node_Array;
      Free  : Count_Type'Base;
      First : Count_Type;
      Last  : Count_Type;
      Count : Count_Type;
      X     : Count_Type)
   with
     Inline,
     Global => null,
     Pre    =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Count)
          and then X in Nodes'Range
          and then
            Memory_Index_Sets.Contains (Active_Set (Nodes, Free, First), X)
          and then X /= First
          and then X /= Last),
     Post   =>
       (Static =>
          Limbo_State (Nodes, Free, First, Last, X, Count - 1)
          and then X in Memory (Nodes, Free)'Range
          and then
            Is_Add
              (Active_Set (Nodes, Free, First),
               Active_Set (Nodes'Old, Free, First),
               X));
   --  Detach an interior node, preserving the endpoints and count

   procedure Unlink_Last_Node
     (Nodes : in out Node_Array;
      Free  : Count_Type'Base;
      First : Count_Type;
      Last  : in out Count_Type;
      Count : Count_Type)
   with
     Inline,
     Global => null,
     Pre    =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Count)
          and then Count >= 2),
     Post   =>
       (Static =>
          Limbo_State (Nodes, Free, First, Last, Last'Old, Count - 1)
          and then Last'Old in Memory (Nodes, Free)'Range
          and then
            Is_Add
              (Active_Set (Nodes, Free, First),
               Active_Set (Nodes'Old, Free, First),
               Last'Old));
   --  Detach the tail of a list with at least two nodes, preserving the count

   procedure Unlink_Sole_Node
     (Nodes : Node_Array;
      Free  : Count_Type'Base;
      First : in out Count_Type;
      Last  : in out Count_Type;
      Count : Count_Type)
   with
     Inline,
     Global => null,
     Pre    =>
       (Static =>
          Structural_Invariant (Nodes, Free, First, Last, Count)
          and then Count = 1),
     Post   =>
       (Static =>
          Limbo_State (Nodes, Free, First, Last, First'Old, 0)
          and then First = 0
          and then Last = 0
          and then First'Old in Memory (Nodes, Free)'Range);
   --  Detach the only node without changing its links or the stored count

   --------------
   -- Allocate --
   --------------

   procedure Allocate
     (Nodes    : in out Node_Array;
      Elements : in out Elements_Array;
      Free     : in out Count_Type'Base;
      First    : Count_Type;
      Last     : Count_Type;
      Count    : Count_Type;
      New_Item : Element_Type;
      New_Node : out Count_Type) is
   begin
      New_Node := (if Free >= 0 then Free else -Free);
      Fill (Elements (New_Node), New_Item);
      Reserve_Node (Nodes, Free, First, Last, Count, New_Node);

      pragma
        Assert (Static => Valid_Elements (Nodes, Elements, Free, New_Node));
   end Allocate;

   ------------
   -- Assign --
   ------------

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
   is
      N        : Node_Array renames Source_Nodes;
      J        : Count_Type;
      Position : Count_Type;

   begin
      Clear
        (Target_Nodes,
         Target_Elements,
         Target_Free,
         Target_First,
         Target_Last,
         Target_Length);

      J := Source_First;
      while J /= 0 loop
         pragma
           Loop_Invariant
             (Static =>
                Structural_Invariant
                  (Target_Nodes,
                   Target_Free,
                   Target_First,
                   Target_Last,
                   Target_Length));
         pragma
           Loop_Invariant
             (Static =>
                Valid_Elements (Target_Nodes, Target_Elements, Target_Free));
         pragma
           Loop_Invariant
             (Static =>
                Memory_Index_Sets.Contains
                  (Active_Set (Source_Nodes, Source_Free, Source_First), J));
         pragma
           Loop_Invariant
             (Static =>
                Big_Conversions.To_Big (Target_Length)
                + Memory_Index_Sets.Length
                    (Reachable_Set (J, Memory (Source_Nodes, Source_Free)))
                = Big_Conversions.To_Big (Source_Length));
         pragma
           Loop_Variant
             (Static =>
                (Decreases =>
                   Memory_Index_Sets.Length
                     (Reachable_Set (J, Memory (Source_Nodes, Source_Free)))));

         Lemma_Reachable_Is_Acyclic
           (Source_First, J, Memory (Source_Nodes, Source_Free));
         Lemma_Reachable_Included
           (Source_First, J, Memory (Source_Nodes, Source_Free));

         --  Advancing J to its successor drops it from the reachable set, so
         --  the count decreases by one, matching the node insertion adds.

         Lemma_Reachable_Def (J, Memory (Source_Nodes, Source_Free));
         Lemma_Is_Acyclic_Def (J, Memory (Source_Nodes, Source_Free));

         Insert
           (Target_Nodes,
            Target_Elements,
            Target_Free,
            Target_First,
            Target_Last,
            Target_Length,
            Before   => 0,
            New_Item => Constant_Access (Source_Elements (J)).all,
            Position => Position,
            Count    => 1);
         J := N (J).Next;
      end loop;
   end Assign;

   -----------
   -- Clear --
   -----------

   procedure Clear
     (Nodes    : in out Node_Array;
      Elements : in out Elements_Array;
      Free     : in out Count_Type'Base;
      First    : in out Count_Type;
      Last     : in out Count_Type;
      Length   : in out Count_Type)
   is
      X : Count_Type;
   begin
      if Length = 0 then
         return;
      end if;

      while Length > 1 loop
         pragma
           Loop_Invariant
             (Static =>
                Structural_Invariant (Nodes, Free, First, Last, Length));
         pragma
           Loop_Invariant (Static => Valid_Elements (Nodes, Elements, Free));
         pragma Loop_Variant (Static => (Decreases => Length));

         X := First;
         Unlink_First_Node (Nodes, Free, First, Last, Length);
         Length := Length - 1;
         Generic_List_Operations.Free
           (Nodes, Elements, Free, First, Last, Length, X);
      end loop;

      --  Exactly one active node is left; drop it

      X := First;
      Unlink_Sole_Node (Nodes, Free, First, Last, Length);
      Length := 0;
      Generic_List_Operations.Free
        (Nodes, Elements, Free, First, Last, Length, X);
   end Clear;

   ----------
   -- Copy --
   ----------

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
   is

      procedure Rebuild_Free_List
        (Nodes : Node_Array; Free : Count_Type'Base; Base, Cont : Count_Type)
      with
        Ghost => Static,
        Pre   =>
          Valid_Links (Nodes, Free)
          and then Valid_Memory (Memory (Nodes, Free))
          and then Free = Base
          and then Base in 1 .. Nodes'Last
          and then Cont in 0 .. Base - 1
          and then Is_Acyclic (Cont, Memory (Nodes, Free))
          and then
            (for all J in Base .. Nodes'Last - 1 => Nodes (J).Next = J + 1)
          and then Nodes (Nodes'Last).Next = Cont
          and then (for all J in Base .. Nodes'Last => Nodes (J).Prev = -1)
          and then
            (for all I of Reachable_Set (Cont, Memory (Nodes, Free)) =>
               I <= Base - 1)
          and then
            (for all I of Reachable_Set (Cont, Memory (Nodes, Free)) =>
               Nodes (I).Prev = -1),
        Post  =>
          Is_Acyclic (Base, Memory (Nodes, Free))
          and then
            (for all I of Reachable_Set (Base, Memory (Nodes, Free)) =>
               I in Base .. Nodes'Last
               or else
                 Memory_Index_Sets.Contains
                   (Reachable_Set (Cont, Memory (Nodes, Free)), I))
          and then
            (for all I of Reachable_Set (Base, Memory (Nodes, Free)) =>
               Nodes (I).Prev = -1)
          and then
            (for all I in Base .. Nodes'Last =>
               Memory_Index_Sets.Contains
                 (Reachable_Set (Base, Memory (Nodes, Free)), I))
          and then
            (for all I of Reachable_Set (Cont, Memory (Nodes, Free)) =>
               Memory_Index_Sets.Contains
                 (Reachable_Set (Base, Memory (Nodes, Free)), I))
          and then
            Memory_Index_Sets.Length
              (Reachable_Set (Base, Memory (Nodes, Free)))
            = Big_Conversions.To_Big (Nodes'Last - Base + 1)
              + Memory_Index_Sets.Length
                  (Reachable_Set (Cont, Memory (Nodes, Free)));
      --  The new tail chains into Cont. Induction from the last node gives
      --  acyclicity, coverage, deallocation and the combined free count.

      -----------------------
      -- Rebuild_Free_List --
      -----------------------

      procedure Rebuild_Free_List
        (Nodes : Node_Array; Free : Count_Type'Base; Base, Cont : Count_Type)
      is
         M : constant Nodes_Type_Base := Memory (Nodes, Free)
         with Ghost => Static;
      begin
         for J in reverse Base .. Nodes'Last loop
            Lemma_Is_Acyclic_Def (J, M);
            Lemma_Reachable_Def (J, M);

            pragma Loop_Invariant (Static => Is_Acyclic (J, M));
            pragma
              Loop_Invariant
                (Static =>
                   (for all I of Reachable_Set (J, M) =>
                      I in J .. Nodes'Last
                      or else
                        Memory_Index_Sets.Contains
                          (Reachable_Set (Cont, M), I)));
            pragma
              Loop_Invariant
                (Static =>
                   (for all I of Reachable_Set (J, M) => Nodes (I).Prev = -1));
            pragma
              Loop_Invariant
                (Static =>
                   (for all I in J .. Nodes'Last =>
                      Memory_Index_Sets.Contains (Reachable_Set (J, M), I)));
            pragma
              Loop_Invariant
                (Static =>
                   (for all I of Reachable_Set (Cont, M) =>
                      Memory_Index_Sets.Contains (Reachable_Set (J, M), I)));
            pragma
              Loop_Invariant
                (Static =>
                   Memory_Index_Sets.Length (Reachable_Set (J, M))
                   = Big_Conversions.To_Big (Nodes'Last - J + 1)
                     + Memory_Index_Sets.Length (Reachable_Set (Cont, M)));
         end loop;
      end Rebuild_Free_List;

   begin
      --  Copy slices so the untouched source tail is carried without reading
      --  uninitialized scalar fields. The storage actual copies each payload.

      Target_Nodes (1 .. Source_Nodes'Last) := Source_Nodes;
      Copy_Elements
        (Target_Elements (1 .. Source_Nodes'Last),
         Source_Elements,
         Source_Nodes,
         Source_Free);

      Target_Length := Source_Length;
      Target_First := Source_First;
      Target_Last := Source_Last;

      if Source_Free < 0 or else Target_Nodes'Last = Source_Nodes'Last then
         Target_Free := Source_Free;

         Lemma_Free_List_Preserved
           (Source_Free,
            Memory (Source_Nodes, Source_Free),
            Memory (Target_Nodes, Target_Free));

      else
         --  Initialize the extra free cells before publishing their head.

         for N in Source_Nodes'Last + 1 .. Target_Nodes'Last loop
            Target_Nodes (N).Prev := -1;
            Target_Nodes (N).Next :=
              (if N = Target_Nodes'Last then Source_Free else N + 1);

            pragma
              Loop_Invariant (Static => Target_Free = Target_Free'Loop_Entry);
            pragma
              Loop_Invariant
                (Static =>
                   (for all K in Source_Nodes'Last + 1 .. N =>
                      Target_Nodes (K).Prev'Initialized
                      and then Target_Nodes (K).Next'Initialized
                      and then Target_Nodes (K).Prev = -1
                      and then
                        Target_Nodes (K).Next
                        = (if K = Target_Nodes'Last
                           then Source_Free
                           else K + 1)));
         end loop;

         Target_Free := Source_Nodes'Last + 1;

         Lemma_Free_List_Preserved
           (Source_Free,
            Memory (Source_Nodes, Source_Free),
            Memory (Target_Nodes, Target_Free));
         Rebuild_Free_List
           (Target_Nodes, Target_Free, Source_Nodes'Last + 1, Source_Free);
      end if;

      Lemma_Is_Acyclic_Preserved
        (Source_First,
         Memory (Source_Nodes, Source_Free),
         Memory (Target_Nodes, Target_Free));
      Lemma_Reachable_Preserved
        (Source_First,
         Memory (Source_Nodes, Source_Free),
         Memory (Target_Nodes, Target_Free));

      pragma
        Assert
          (Static =>
             Active_List_Valid
               (Target_Nodes,
                Target_Free,
                Target_First,
                Target_Last,
                Target_Length));
   end Copy;

   ------------
   -- Delete --
   ------------

   procedure Delete
     (Nodes    : in out Node_Array;
      Elements : in out Elements_Array;
      Free     : in out Count_Type'Base;
      First    : in out Count_Type;
      Last     : in out Count_Type;
      Length   : in out Count_Type;
      X        : Count_Type) is
   begin
      Detach_Node (Nodes, Free, First, Last, Length, X);
      Generic_List_Operations.Free
        (Nodes, Elements, Free, First, Last, Length, X);
   end Delete;

   procedure Delete
     (Nodes    : in out Node_Array;
      Elements : in out Elements_Array;
      Free     : in out Count_Type'Base;
      First    : in out Count_Type;
      Last     : in out Count_Type;
      Length   : in out Count_Type;
      Position : in out Count_Type;
      Count    : Count_Type)
   is
      X : Count_Type;
   begin
      if Position = First then
         Delete_First (Nodes, Elements, Free, First, Last, Length, Count);
         Position := 0;
         return;
      end if;

      if Count = 0 then
         Position := 0;
         return;
      end if;

      for Index in 1 .. Count loop
         pragma
           Loop_Invariant
             (Static =>
                Structural_Invariant (Nodes, Free, First, Last, Length));
         pragma
           Loop_Invariant (Static => Valid_Elements (Nodes, Elements, Free));
         pragma
           Loop_Invariant
             (Static =>
                Position /= 0
                and then
                  Memory_Index_Sets.Contains
                    (Active_Set (Nodes, Free, First), Position));
         pragma Loop_Invariant (Static => Position /= First);

         X := Position;

         if X = Last then
            Position := 0;

            --  A tail distinct from First has a predecessor

            Lemma_Reachable_Def (First, Memory (Nodes, Free));

            Unlink_Last_Node (Nodes, Free, First, Last, Length);
            Length := Length - 1;
            Generic_List_Operations.Free
              (Nodes, Elements, Free, First, Last, Length, X);
            return;
         end if;

         --  Advance before unlinking X; its successor remains active

         Lemma_Reachable_Closed_By_Next (First, Memory (Nodes, Free));
         Position := Nodes (X).Next;

         Lemma_Reachable_Is_Acyclic (First, X, Memory (Nodes, Free));
         Lemma_Reachable_Included (First, X, Memory (Nodes, Free));
         Lemma_Reachable_Def (X, Memory (Nodes, Free));

         pragma
           Assert
             (Static =>
                Memory_Index_Sets.Contains
                  (Active_Set (Nodes, Free, First), Position));
         pragma Assert (Static => Position /= X);

         Unlink_Interior_Node (Nodes, Free, First, Last, Length, X);
         Length := Length - 1;
         Generic_List_Operations.Free
           (Nodes, Elements, Free, First, Last, Length, X);
      end loop;

      Position := 0;
   end Delete;

   ------------------
   -- Delete_First --
   ------------------

   procedure Delete_First
     (Nodes    : in out Node_Array;
      Elements : in out Elements_Array;
      Free     : in out Count_Type'Base;
      First    : in out Count_Type;
      Last     : in out Count_Type;
      Length   : in out Count_Type;
      Count    : Count_Type)
   is
      X : Count_Type;
   begin
      if Count >= Length then
         Clear (Nodes, Elements, Free, First, Last, Length);
         return;
      end if;

      if Count = 0 then
         return;
      end if;

      --  At least one node survives each head removal

      for J in 1 .. Count loop
         pragma
           Loop_Invariant
             (Static =>
                Structural_Invariant (Nodes, Free, First, Last, Length));
         pragma
           Loop_Invariant (Static => Valid_Elements (Nodes, Elements, Free));
         pragma Loop_Invariant (Static => Length >= Count - J + 2);

         X := First;
         Unlink_First_Node (Nodes, Free, First, Last, Length);
         Length := Length - 1;
         Generic_List_Operations.Free
           (Nodes, Elements, Free, First, Last, Length, X);
      end loop;
   end Delete_First;

   -----------------
   -- Delete_Last --
   -----------------

   procedure Delete_Last
     (Nodes    : in out Node_Array;
      Elements : in out Elements_Array;
      Free     : in out Count_Type'Base;
      First    : in out Count_Type;
      Last     : in out Count_Type;
      Length   : in out Count_Type;
      Count    : Count_Type)
   is
      X : Count_Type;
   begin
      if Count >= Length then
         Clear (Nodes, Elements, Free, First, Last, Length);
         return;
      end if;

      if Count = 0 then
         return;
      end if;

      --  At least one node survives each tail removal

      for J in 1 .. Count loop
         pragma
           Loop_Invariant
             (Static =>
                Structural_Invariant (Nodes, Free, First, Last, Length));
         pragma
           Loop_Invariant (Static => Valid_Elements (Nodes, Elements, Free));
         pragma Loop_Invariant (Static => Length >= Count - J + 2);

         X := Last;
         Unlink_Last_Node (Nodes, Free, First, Last, Length);
         Length := Length - 1;
         Generic_List_Operations.Free
           (Nodes, Elements, Free, First, Last, Length, X);
      end loop;
   end Delete_Last;

   -----------------
   -- Detach_Node --
   -----------------

   procedure Detach_Node
     (Nodes  : in out Node_Array;
      Free   : Count_Type'Base;
      First  : in out Count_Type;
      Last   : in out Count_Type;
      Length : in out Count_Type;
      X      : Count_Type)
   is
      Old_Active : constant Memory_Index_Set := Active_Set (Nodes, Free, First)
      with Ghost => Static;
   begin
      if Length = 1 then
         --  The sole node is the whole active set

         Lemma_Reachable_Def (First, Memory (Nodes, Free));
         Unlink_Sole_Node (Nodes, Free, First, Last, Length);

         pragma
           Assert
             (Static =>
                Is_Add (Active_Set (Nodes, Free, First), Old_Active, X));

      elsif X = First then
         Unlink_First_Node (Nodes, Free, First, Last, Length);

      elsif X = Last then
         Unlink_Last_Node (Nodes, Free, First, Last, Length);

      else
         Unlink_Interior_Node (Nodes, Free, First, Last, Length, X);
      end if;

      Length := Length - 1;
   end Detach_Node;

   -------------
   -- Element --
   -------------

   function Element
     (Elements : Elements_Array; X : Count_Type) return Element_Type is
   begin
      return Constant_Access (Elements (X)).all;
   end Element;

   -----------
   -- Equal --
   -----------

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
   is
      LI : Count_Type;
      RI : Count_Type;

   begin
      if Left_Length /= Right_Length then
         return False;
      end if;

      LI := Left_First;
      RI := Right_First;

      while LI /= 0 loop
         --  Establish non-emptiness through cardinality before using it to
         --  show that the right-hand traversal has not reached its end.

         pragma
           Assert
             (Static =>
                not Memory_Index_Sets.Is_Empty
                      (Reachable_Set (LI, Memory (Left_Nodes, Left_Free))));
         pragma
           Assert
             (Static =>
                Memory_Index_Sets.Length
                  (Reachable_Set (RI, Memory (Right_Nodes, Right_Free)))
                > 0);

         --  LI and RI walk the two active lists in lockstep. Their remaining
         --  reachable sets have equal length (the lists have equal Length and
         --  each step drops one node), so LI and RI reach 0 together and RI is
         --  a valid index whenever LI is.

         pragma Warnings (Off, "condition is always True");
         pragma Loop_Invariant (Static => LI /= 0 and RI /= 0);
         pragma
           Loop_Invariant
             (Static =>
                Reachable (Left_First, Memory (Left_Nodes, Left_Free), LI));
         pragma
           Loop_Invariant
             (Static =>
                Reachable (Right_First, Memory (Right_Nodes, Right_Free), RI));
         pragma
           Loop_Invariant
             (Static =>
                Memory_Index_Sets.Length
                  (Reachable_Set (LI, Memory (Left_Nodes, Left_Free)))
                = Memory_Index_Sets.Length
                    (Reachable_Set (RI, Memory (Right_Nodes, Right_Free))));
         pragma
           Loop_Variant
             (Static =>
                (Decreases =>
                   Memory_Index_Sets.Length
                     (Reachable_Set (LI, Memory (Left_Nodes, Left_Free)))));
         pragma Warnings (On, "condition is always True");

         --  Both heads are reachable from an acyclic list head, so they head
         --  acyclic lists; unfolding Reachable_Set at each gives the length
         --  drop that advances the variant and preserves the equal-length
         --  invariant.

         Lemma_Reachable_Is_Acyclic
           (Left_First, LI, Memory (Left_Nodes, Left_Free));
         Lemma_Reachable_Is_Acyclic
           (Right_First, RI, Memory (Right_Nodes, Right_Free));
         Lemma_Reachable_Included
           (Left_First, LI, Memory (Left_Nodes, Left_Free));
         Lemma_Reachable_Included
           (Right_First, RI, Memory (Right_Nodes, Right_Free));
         Lemma_Reachable_Def (LI, Memory (Left_Nodes, Left_Free));
         Lemma_Reachable_Def (RI, Memory (Right_Nodes, Right_Free));

         if Constant_Access (Left_Elements (LI)).all
           /= Constant_Access (Right_Elements (RI)).all
         then
            return False;
         end if;

         LI := Left_Nodes (LI).Next;
         RI := Right_Nodes (RI).Next;
      end loop;

      return True;
   end Equal;

   ----------
   -- Find --
   ----------

   function Find
     (Nodes    : Node_Array;
      Elements : Elements_Array;
      Free     : Count_Type'Base;
      First    : Count_Type;
      Last     : Count_Type;
      Length   : Count_Type;
      Item     : Element_Type;
      Position : Count_Type) return Count_Type
   is
      From : Count_Type := Position;

   begin
      if From = 0 then
         From := First;
      end if;

      --  The active list is closed under Next, so once From is reachable from
      --  First its successor is reachable (or 0).

      Lemma_Reachable_Closed_By_Next (First, Memory (Nodes, Free));

      while From /= 0 loop
         pragma
           Loop_Invariant
             (Static => Reachable (First, Memory (Nodes, Free), From));
         pragma
           Loop_Variant
             (Static =>
                (Decreases =>
                   Memory_Index_Sets.Length
                     (Reachable_Set (From, Memory (Nodes, Free)))));

         Lemma_Reachable_Is_Acyclic (First, From, Memory (Nodes, Free));
         Lemma_Reachable_Def (From, Memory (Nodes, Free));

         if Constant_Access (Elements (From)).all = Item then
            return From;
         end if;

         From := Nodes (From).Next;
      end loop;

      return 0;
   end Find;

   ----------
   -- Free --
   ----------

   procedure Free
     (Nodes    : in out Node_Array;
      Elements : in out Elements_Array;
      Free     : in out Count_Type'Base;
      First    : Count_Type;
      Last     : Count_Type;
      Count    : Count_Type;
      X        : Count_Type) is
   begin
      Reclaim (Elements (X));
      Release_Node (Nodes, Free, First, Last, Count, X);
   end Free;

   -------------------
   -- Generic_Model --
   -------------------

   package body Generic_Model is

      function Element
        (S : M.Sequence; I : Positive_Count_Type) return Element_Type
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
            if M.Length (Container) = 0 then
               return True;
            end if;

            for I in 2 .. M.Last (Container) loop
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
         for Index in 1 .. M.Last (Container) loop
            declare
               Found : Boolean := False;
            begin
               for J in 1 .. M.Last (Left) loop
                  if M.Element_Logic_Equal
                       (Element (Container, Index), Element (Left, J))
                  then
                     Found := True;
                     exit;
                  end if;
               end loop;

               if not Found then
                  for J in 1 .. M.Last (Right) loop
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
         L_Fst : Positive_Count_Type := 1;
         L_Lst : Count_Type;
         Right : M.Sequence;
         R_Fst : Positive_Count_Type := 1;
         R_Lst : Count_Type) return Boolean
      with SPARK_Mode => Off
      is
      begin
         for I in L_Fst .. L_Lst loop
            declare
               Found : Boolean := False;
               J     : Count_Type := R_Fst - 1;

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

         for I in 1 .. L loop
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
        (Left, Right : M.Sequence; X, Y : Positive_Count_Type) return Boolean
      with SPARK_Mode => Off
      is
      begin
         if M.Last (Left) /= M.Last (Right)
           or else
             not M.Element_Logic_Equal (Element (Left, X), Element (Right, Y))
           or else
             not M.Element_Logic_Equal (Element (Left, Y), Element (Right, X))
         then
            return False;
         end if;

         for I in 1 .. M.Last (Left) loop
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

      -----------------------
      -- Mapping_Preserved --
      -----------------------

      function Mapping_Preserved
        (M_Left, M_Right : M.Sequence; P_Left, P_Right : P.Map) return Boolean
      with SPARK_Mode => Off
      is
      begin
         for C of P_Left loop
            if not P.Has_Key (P_Right, C)
              or else P.Get (P_Left, C) > M.Last (M_Left)
              or else P.Get (P_Right, C) > M.Last (M_Right)
              or else
                not M.Element_Logic_Equal
                      (M.Get (M_Left, P.Get (P_Left, C)),
                       M.Get (M_Right, P.Get (P_Right, C)))
            then
               return False;
            end if;
         end loop;

         for C of P_Right loop
            if not P.Has_Key (P_Left, C) then
               return False;
            end if;
         end loop;

         return True;
      end Mapping_Preserved;

      -----------
      -- Model --
      -----------

      function Model
        (Nodes    : Node_Array;
         Elements : Elements_Array;
         Free     : Count_Type'Base;
         First    : Count_Type;
         Last     : Count_Type;
         Length   : Count_Type) return M.Sequence
      is
         Position : Count_Type := First;
         R        : M.Sequence;

      begin
         --  The active list is closed under Next, so a reachable Position has
         --  a reachable successor (or 0).

         Lemma_Reachable_Closed_By_Next (First, Memory (Nodes, Free));

         while Position /= 0 loop
            pragma
              Loop_Variant
                (Static =>
                   (Decreases =>
                      Memory_Index_Sets.Length
                        (Reachable_Set (Position, Memory (Nodes, Free)))));
            pragma
              Loop_Invariant
                (Static => Reachable (First, Memory (Nodes, Free), Position));
            pragma
              Loop_Invariant
                (Static =>
                   M.Length (R)
                   + Memory_Index_Sets.Length
                       (Reachable_Set (Position, Memory (Nodes, Free)))
                   = M.Big (Length));

            Lemma_Reachable_Is_Acyclic (First, Position, Memory (Nodes, Free));
            Lemma_Reachable_Def (Position, Memory (Nodes, Free));

            R := M.Add (R, Constant_Access (Elements (Position)).all);
            Position := Nodes (Position).Next;
         end loop;

         return R;
      end Model;

      -------------------------
      -- P_Positions_Shifted --
      -------------------------

      function P_Positions_Shifted
        (Small, Big : P.Map;
         Cut        : Positive_Count_Type;
         Count      : Count_Type := 1) return Boolean
      with SPARK_Mode => Off
      is
      begin
         for Cu of P.Iterate (Small) loop
            if not P.Has_Key (Big, Cu) then
               return False;
            end if;
         end loop;

         for Cu of P.Iterate (Big) loop
            declare
               Pos : constant Positive_Count_Type := P.Get (Big, Cu);

            begin
               if Pos < Cut then
                  if not P.Has_Key (Small, Cu) or else Pos /= P.Get (Small, Cu)
                  then
                     return False;
                  end if;

               elsif Pos >= Cut + Count then
                  if not P.Has_Key (Small, Cu)
                    or else Pos /= P.Get (Small, Cu) + Count
                  then
                     return False;
                  end if;

               else
                  if P.Has_Key (Small, Cu) then
                     return False;
                  end if;
               end if;
            end;
         end loop;

         return True;
      end P_Positions_Shifted;

      -------------------------
      -- P_Positions_Swapped --
      -------------------------

      function P_Positions_Swapped
        (Left, Right : P.Map; X, Y : Cursor_Type) return Boolean
      with SPARK_Mode => Off
      is
      begin
         if not P.Has_Key (Left, X)
           or not P.Has_Key (Left, Y)
           or not P.Has_Key (Right, X)
           or not P.Has_Key (Right, Y)
         then
            return False;
         end if;

         if P.Get (Left, X) /= P.Get (Right, Y)
           or P.Get (Left, Y) /= P.Get (Right, X)
         then
            return False;
         end if;

         for C of P.Iterate (Left) loop
            if not P.Has_Key (Right, C) then
               return False;
            end if;
         end loop;

         for C of P.Iterate (Right) loop
            if not P.Has_Key (Left, C)
              or else
                (C /= X and C /= Y and P.Get (Left, C) /= P.Get (Right, C))
            then
               return False;
            end if;
         end loop;

         return True;
      end P_Positions_Swapped;

      ---------------------------
      -- P_Positions_Truncated --
      ---------------------------

      function P_Positions_Truncated
        (Small, Big : P.Map;
         Cut        : Positive_Count_Type;
         Count      : Count_Type := 1) return Boolean
      with SPARK_Mode => Off
      is
      begin
         for Cu of P.Iterate (Small) loop
            if not P.Has_Key (Big, Cu) then
               return False;
            end if;
         end loop;

         for Cu of P.Iterate (Big) loop
            declare
               Pos : constant Positive_Count_Type := P.Get (Big, Cu);

            begin
               if Pos < Cut then
                  if not P.Has_Key (Small, Cu) or else Pos /= P.Get (Small, Cu)
                  then
                     return False;
                  end if;

               elsif Pos >= Cut + Count then
                  return False;

               elsif P.Has_Key (Small, Cu) then
                  return False;
               end if;
            end;
         end loop;

         return True;
      end P_Positions_Truncated;

      ---------------
      -- Positions --
      ---------------

      function Positions
        (Nodes  : Node_Array;
         Free   : Count_Type'Base;
         First  : Count_Type;
         Last   : Count_Type;
         Length : Count_Type) return P.Map
      is
         I        : Count_Type := 0;
         Position : Count_Type := First;
         R        : P.Map;

      begin
         --  The active list is closed under Next; establish that once so the
         --  loop needs no per-iteration closure lemma.

         Lemma_Reachable_Closed_By_Next (First, Memory (Nodes, Free));

         while Position /= 0 loop
            pragma
              Loop_Variant
                (Static =>
                   (Decreases =>
                      Memory_Index_Sets.Length
                        (Reachable_Set (Position, Memory (Nodes, Free)))));
            pragma
              Loop_Invariant
                (Static => Reachable (First, Memory (Nodes, Free), Position));
            pragma Loop_Invariant (Static => M.Big (I) = P.Length (R));
            pragma
              Loop_Invariant
                (Static =>
                   P.Length (R)
                   + Memory_Index_Sets.Length
                       (Reachable_Set (Position, Memory (Nodes, Free)))
                   = M.Big (Length));
            pragma
              Loop_Invariant
                (Static =>
                   (for all C of R =>
                      Node (C) /= 0
                      and then
                        not Memory_Index_Sets.Contains
                              (Reachable_Set (Position, Memory (Nodes, Free)),
                               Node (C))));

            Lemma_Reachable_Is_Acyclic (First, Position, Memory (Nodes, Free));
            Lemma_Reachable_Def (Position, Memory (Nodes, Free));

            I := I + 1;
            R := P.Add (R, To_Cursor (Position), I);
            Position := Nodes (Position).Next;
         end loop;

         return R;
      end Positions;

   end Generic_Model;

   ---------------------
   -- Generic_Sorting --
   ---------------------

   package body Generic_Sorting is

      ---------------
      -- Is_Sorted --
      ---------------

      function Is_Sorted
        (Nodes    : Node_Array;
         Elements : Elements_Array;
         Free     : Count_Type'Base;
         First    : Count_Type;
         Last     : Count_Type;
         Length   : Count_Type) return Boolean
      is
         N    : Node_Array renames Nodes;
         Node : Count_Type := First;

      begin
         --  The active list is closed under Next, so once Node is reachable
         --  from First its successor is reachable (or 0).

         Lemma_Reachable_Closed_By_Next (First, Memory (Nodes, Free));

         for J in 2 .. Length loop

            --  Node is the (J - 1)th node of the active list, so the list it
            --  heads still holds Length - J + 2 nodes. Two or more of them
            --  means Node has a successor, which is what makes the reads
            --  below in range.

            pragma
              Loop_Invariant
                (Static => Reachable (First, Memory (Nodes, Free), Node));
            pragma
              Loop_Invariant
                (Static =>
                   Memory_Index_Sets.Length
                     (Reachable_Set (Node, Memory (Nodes, Free)))
                   = Big_Conversions.To_Big (Length - J + 2));

            Lemma_Reachable_Is_Acyclic (First, Node, Memory (Nodes, Free));
            Lemma_Reachable_Def (Node, Memory (Nodes, Free));

            if Constant_Access (Elements (N (Node).Next)).all
              < Constant_Access (Elements (Node)).all
            then
               return False;
            else
               Node := N (Node).Next;
            end if;
         end loop;

         return True;
      end Is_Sorted;

      -----------
      -- Merge --
      -----------

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
      is
         --  Merge assumes that "<" does not propagate exceptions, as required
         --  for SPARK callers. If it raises after a splice, array updates may
         --  persist without the scalar controls being copied back, leaving the
         --  lists inconsistent. Recovery for such Ada callers is intentionally
         --  unsupported, keeping scalar parameters passed by copy without
         --  additional exception-handling machinery.

         LI : Count_Type := Target_First;
         RI : Count_Type := Source_First;

         Orig_Sum : constant Count_Type := Target_Length + Source_Length
         with Ghost => Static;

      begin
         while RI /= 0 loop
            pragma Warnings (Off, "condition is always True");
            pragma
              Loop_Invariant
                (Static =>
                   Structural_Invariant
                     (Target_Nodes,
                      Target_Free,
                      Target_First,
                      Target_Last,
                      Target_Length));
            pragma
              Loop_Invariant
                (Static =>
                   Valid_Elements
                     (Target_Nodes, Target_Elements, Target_Free));
            pragma
              Loop_Invariant
                (Static =>
                   Structural_Invariant
                     (Source_Nodes,
                      Source_Free,
                      Source_First,
                      Source_Last,
                      Source_Length));
            pragma
              Loop_Invariant
                (Static =>
                   Valid_Elements
                     (Source_Nodes, Source_Elements, Source_Free));
            pragma
              Loop_Invariant
                (Static =>
                   RI /= 0
                   and then
                     Memory_Index_Sets.Contains
                       (Active_Set (Source_Nodes, Source_Free, Source_First),
                        RI));
            pragma
              Loop_Invariant
                (Static =>
                   LI = 0
                   or else
                     Memory_Index_Sets.Contains
                       (Active_Set (Target_Nodes, Target_Free, Target_First),
                        LI));
            pragma
              Loop_Invariant
                (Static => Target_Length + Source_Length = Orig_Sum);
            pragma Loop_Invariant (Static => Orig_Sum <= Target_Nodes'Last);
            pragma
              Loop_Variant
                (Static =>
                   (Decreases => Source_Length,
                    Decreases =>
                      Memory_Index_Sets.Length
                        (Reachable_Set
                           (LI, Memory (Target_Nodes, Target_Free)))));
            pragma Warnings (On, "condition is always True");

            if LI = 0 then
               Splice
                 (Target_Nodes,
                  Target_Elements,
                  Target_Free,
                  Target_First,
                  Target_Last,
                  Target_Length,
                  Source_Nodes,
                  Source_Elements,
                  Source_Free,
                  Source_First,
                  Source_Last,
                  Source_Length,
                  0);
               return;
            end if;

            if Constant_Access (Source_Elements (RI)).all
              < Constant_Access (Target_Elements (LI)).all
            then
               declare
                  RJ : Count_Type := RI;
               begin
                  Lemma_Reachable_Closed_By_Next
                    (Source_First, Memory (Source_Nodes, Source_Free));
                  Lemma_Reachable_Is_Acyclic
                    (Source_First, RI, Memory (Source_Nodes, Source_Free));
                  Lemma_Reachable_Def (RI, Memory (Source_Nodes, Source_Free));

                  pragma
                    Assert
                      (Static =>
                         not Memory_Index_Sets.Is_Empty
                               (Active_Set
                                  (Source_Nodes, Source_Free, Source_First)));

                  RI := Source_Nodes (RJ).Next;
                  Splice
                    (Target_Nodes,
                     Target_Elements,
                     Target_Free,
                     Target_First,
                     Target_Last,
                     Target_Length,
                     Source_Nodes,
                     Source_Elements,
                     Source_Free,
                     Source_First,
                     Source_Last,
                     Source_Length,
                     LI,
                     RJ);
               end;
            else
               Lemma_Reachable_Closed_By_Next
                 (Target_First, Memory (Target_Nodes, Target_Free));
               Lemma_Reachable_Is_Acyclic
                 (Target_First, LI, Memory (Target_Nodes, Target_Free));
               Lemma_Reachable_Def (LI, Memory (Target_Nodes, Target_Free));

               LI := Target_Nodes (LI).Next;
            end if;
         end loop;
      end Merge;

      ----------
      -- Sort --
      ----------

      procedure Sort
        (Nodes    : in out Node_Array;
         Elements : Elements_Array;
         Free     : Count_Type'Base;
         First    : in out Count_Type;
         Last     : in out Count_Type;
         Length   : Count_Type)
      is

         type List_Descriptor is record
            First  : Count_Type := 0;
            Last   : Count_Type := 0;
            Length : Count_Type := 0;
         end record;
         --  A detached segment of the list, given by its endpoints and its
         --  number of nodes

         No_Segment : constant List_Descriptor := (0, 0, 0);

         -----------------------------
         -- Ghost model of segments --
         -----------------------------

         function Segment_Valid
           (M        : Nodes_Type_Base;
            Elements : Elements_Array;
            D        : List_Descriptor) return Boolean
         is (M'First >= Elements'First
             and then M'Last <= Elements'Last
             and then Valid_Memory (M)
             and then (for all N of M => N.Prev'Initialized)
             and then D.First in M'Range | 0
             and then Is_Acyclic (D.First, M)
             and then
               Memory_Index_Sets.Length (Reachable_Set (D.First, M))
               = Big_Conversions.To_Big (D.Length)
             and then
               (if D.First = 0
                then D.Last = 0
                else
                  D.Last in M'Range
                  and then M (D.First).Prev = 0
                  and then M (D.Last).Next = 0
                  and then Reachable (D.First, M, D.Last))
             and then
               (for all I of Reachable_Set (D.First, M) =>
                  M (I).Prev in 0 .. M'Last
                  and then Is_Initialized (Elements (I))
                  and then (if M (I).Next = 0 then I = D.Last)
                  and then
                    (if M (I).Prev = 0
                     then I = D.First
                     else
                       Reachable (D.First, M, M (I).Prev)
                       and then M (M (I).Prev).Next = I)))
         with Ghost => Static;
         --  D is a well-formed doubly linked segment of M, with initialized
         --  values in Elements. Its D.Length allocated nodes form an acyclic
         --  chain from D.First to D.Last, with Prev links mirroring Next links
         --  inside the segment.

         function Untouched_Outside
           (M1, M2 : Nodes_Type_Base; S : Memory_Index_Set) return Boolean
         is (M1'First = M2'First
             and then M1'Last = M2'Last
             and then (for all N of M1 => N.Prev'Initialized)
             and then (for all N of M2 => N.Prev'Initialized)
             and then
               (for all I in M1'Range =>
                  (if not Memory_Index_Sets.Contains (S, I)
                   then
                     M1 (I).Prev = M2 (I).Prev
                     and then M1 (I).Next = M2 (I).Next)))
         with Ghost => Static;
         --  The links outside S are unchanged

         Whole : List_Descriptor :=
           (First => First, Last => Last, Length => Length);
         --  The whole list, as the segment handed to the sort

         M_Old : constant Nodes_Type_Base := Memory (Nodes, Free)
         with Ghost => Static;

         ------------------------
         -- Local subprograms  --
         ------------------------

         procedure Detach_First
           (Source : in out List_Descriptor; Detached : out Count_Type)
         with
           Modifies => (Nodes, Source, Detached),
           Pre      =>
             (Static =>
                Valid_Links (Nodes, Free)
                and then Valid_Elements (Nodes, Elements, Free)
                and then Segment_Valid (Memory (Nodes, Free), Elements, Source)
                and then Source.Length >= 1),
           Post     =>
             (Static =>
                Valid_Links (Nodes, Free)
                and then Valid_Elements (Nodes, Elements, Free)
                and then Segment_Valid (Memory (Nodes, Free), Elements, Source)
                and then Detached = Source'Old.First
                and then Detached in Memory (Nodes, Free)'Range
                and then Source.Length = Source'Old.Length - 1
                and then Memory (Nodes, Free) (Detached).Prev = 0
                and then Memory (Nodes, Free) (Detached).Next = 0
                and then Is_Initialized (Elements (Detached))
                and then
                  Is_Add
                    (Reachable_Set (Source.First, Memory (Nodes, Free)),
                     Reachable_Set
                       (Source'Old.First, Memory (Nodes'Old, Free)),
                     Detached)
                and then
                  Untouched_Outside
                    (Memory (Nodes'Old, Free),
                     Memory (Nodes, Free),
                     Reachable_Set
                       (Source'Old.First, Memory (Nodes'Old, Free))));
         --  Take the first node off a non-empty segment. The detached node is
         --  left as an isolated singleton (both its links null), as the merge
         --  loop expects.

         procedure Append_Node
           (Target : in out List_Descriptor; New_Node : Count_Type)
         with
           Modifies => (Nodes, Target),
           Pre      =>
             (Static =>
                Valid_Links (Nodes, Free)
                and then Valid_Elements (Nodes, Elements, Free)
                and then Segment_Valid (Memory (Nodes, Free), Elements, Target)
                and then New_Node in Memory (Nodes, Free)'Range
                and then Memory (Nodes, Free) (New_Node).Prev = 0
                and then Memory (Nodes, Free) (New_Node).Next = 0
                and then Is_Initialized (Elements (New_Node))
                and then
                  not Reachable
                        (Target.First, Memory (Nodes, Free), New_Node)),
           Post     =>
             (Static =>
                Valid_Links (Nodes, Free)
                and then Valid_Elements (Nodes, Elements, Free)
                and then Segment_Valid (Memory (Nodes, Free), Elements, Target)
                and then Target.Length = Target'Old.Length + 1
                and then
                  Is_Add
                    (Reachable_Set
                       (Target'Old.First, Memory (Nodes'Old, Free)),
                     Reachable_Set (Target.First, Memory (Nodes, Free)),
                     New_Node)
                and then
                  Untouched_Outside
                    (Memory (Nodes'Old, Free),
                     Memory (Nodes, Free),
                     Reachable_Set (Target.First, Memory (Nodes, Free))));
         --  Append a detached node to a list segment

         procedure Merge_Parts
           (Part1, Part2 : List_Descriptor; Merged : out List_Descriptor)
         with
           Pre  =>
             (Static =>
                Valid_Links (Nodes, Free)
                and then Valid_Elements (Nodes, Elements, Free)
                and then Segment_Valid (Memory (Nodes, Free), Elements, Part1)
                and then Segment_Valid (Memory (Nodes, Free), Elements, Part2)
                and then
                  Memory_Index_Sets.No_Overlap
                    (Reachable_Set (Part1.First, Memory (Nodes, Free)),
                     Reachable_Set (Part2.First, Memory (Nodes, Free)))
                and then Part1.Length <= Count_Type'Last - Part2.Length),
           Post =>
             (Static =>
                Valid_Links (Nodes, Free)
                and then Valid_Elements (Nodes, Elements, Free)
                and then Segment_Valid (Memory (Nodes, Free), Elements, Merged)
                and then Merged.Length = Part1.Length + Part2.Length
                and then
                  Memory_Index_Sets."="
                    (Reachable_Set (Merged.First, Memory (Nodes, Free)),
                     Memory_Index_Sets.Union
                       (Reachable_Set (Part1.First, Memory (Nodes'Old, Free)),
                        Reachable_Set (Part2.First, Memory (Nodes'Old, Free))))
                and then
                  Untouched_Outside
                    (Memory (Nodes'Old, Free),
                     Memory (Nodes, Free),
                     Memory_Index_Sets.Union
                       (Reachable_Set (Part1.First, Memory (Nodes'Old, Free)),
                        Reachable_Set
                          (Part2.First, Memory (Nodes'Old, Free)))));
         --  Merge two disjoint segments, preserving the sorted property. If
         --  the compared elements are equal the node of Part1 comes first, as
         --  stability requires.

         procedure Merge_Sort (Arg : in out List_Descriptor)
         with
           Subprogram_Variant => (Decreases => Arg.Length, Decreases => 1),
           Pre                =>
             (Static =>
                Valid_Links (Nodes, Free)
                and then Valid_Elements (Nodes, Elements, Free)
                and then Segment_Valid (Memory (Nodes, Free), Elements, Arg)),
           Post               =>
             (Static =>
                Valid_Links (Nodes, Free)
                and then Valid_Elements (Nodes, Elements, Free)
                and then Segment_Valid (Memory (Nodes, Free), Elements, Arg)
                and then Arg.Length = Arg'Old.Length
                and then
                  Memory_Index_Sets."="
                    (Reachable_Set (Arg.First, Memory (Nodes, Free)),
                     Reachable_Set (Arg'Old.First, Memory (Nodes'Old, Free)))
                and then
                  Untouched_Outside
                    (Memory (Nodes'Old, Free),
                     Memory (Nodes, Free),
                     Reachable_Set (Arg'Old.First, Memory (Nodes'Old, Free))));
         --  Sort a segment in place using MergeSort. As required by the RM,
         --  the sort is stable.

         procedure Sort_Parts (Part1, Part2 : in out List_Descriptor)
         with
           Inline,
           Subprogram_Variant =>
             (Decreases => Part1.Length + Part2.Length, Decreases => 0),
           Pre                =>
             (Static =>
                Valid_Links (Nodes, Free)
                and then Valid_Elements (Nodes, Elements, Free)
                and then Segment_Valid (Memory (Nodes, Free), Elements, Part1)
                and then Segment_Valid (Memory (Nodes, Free), Elements, Part2)
                and then Part1.Length >= 1
                and then Part2.Length >= 1
                and then Part1.Length <= Count_Type'Last - Part2.Length
                and then
                  Memory_Index_Sets.No_Overlap
                    (Reachable_Set (Part1.First, Memory (Nodes, Free)),
                     Reachable_Set (Part2.First, Memory (Nodes, Free)))),
           Post               =>
             (Static =>
                Valid_Links (Nodes, Free)
                and then Valid_Elements (Nodes, Elements, Free)
                and then Segment_Valid (Memory (Nodes, Free), Elements, Part1)
                and then Segment_Valid (Memory (Nodes, Free), Elements, Part2)
                and then Part1.Length = Part1'Old.Length
                and then Part2.Length = Part2'Old.Length
                and then
                  Memory_Index_Sets.No_Overlap
                    (Reachable_Set (Part1.First, Memory (Nodes, Free)),
                     Reachable_Set (Part2.First, Memory (Nodes, Free)))
                and then
                  Memory_Index_Sets."="
                    (Memory_Index_Sets.Union
                       (Reachable_Set (Part1.First, Memory (Nodes, Free)),
                        Reachable_Set (Part2.First, Memory (Nodes, Free))),
                     Memory_Index_Sets.Union
                       (Reachable_Set
                          (Part1'Old.First, Memory (Nodes'Old, Free)),
                        Reachable_Set
                          (Part2'Old.First, Memory (Nodes'Old, Free))))
                and then
                  Untouched_Outside
                    (Memory (Nodes'Old, Free),
                     Memory (Nodes, Free),
                     Memory_Index_Sets.Union
                       (Reachable_Set
                          (Part1'Old.First, Memory (Nodes'Old, Free)),
                        Reachable_Set
                          (Part2'Old.First, Memory (Nodes'Old, Free)))));
         --  Sort two disjoint non-empty segments while preserving their
         --  combined node set and all links outside it.

         procedure Split_List
           (Unsplit : List_Descriptor; Part1, Part2 : out List_Descriptor)
         with
           Pre  =>
             (Static =>
                Valid_Links (Nodes, Free)
                and then Valid_Elements (Nodes, Elements, Free)
                and then
                  Segment_Valid (Memory (Nodes, Free), Elements, Unsplit)
                and then Unsplit.Length >= 2),
           Post =>
             (Static =>
                Valid_Links (Nodes, Free)
                and then Valid_Elements (Nodes, Elements, Free)
                and then Segment_Valid (Memory (Nodes, Free), Elements, Part1)
                and then Segment_Valid (Memory (Nodes, Free), Elements, Part2)
                and then Part1.Length >= 1
                and then Part2.Length >= 1
                and then Part1.Length + Part2.Length = Unsplit.Length
                and then
                  Memory_Index_Sets.No_Overlap
                    (Reachable_Set (Part1.First, Memory (Nodes, Free)),
                     Reachable_Set (Part2.First, Memory (Nodes, Free)))
                and then
                  Memory_Index_Sets."="
                    (Memory_Index_Sets.Union
                       (Reachable_Set (Part1.First, Memory (Nodes, Free)),
                        Reachable_Set (Part2.First, Memory (Nodes, Free))),
                     Reachable_Set (Unsplit.First, Memory (Nodes'Old, Free)))
                and then
                  Untouched_Outside
                    (Memory (Nodes'Old, Free),
                     Memory (Nodes, Free),
                     Reachable_Set (Unsplit.First, Memory (Nodes'Old, Free))));
         --  Split a segment of two nodes or more into two non-empty parts for
         --  divide-and-conquer

         -----------------
         -- Append_Node --
         -----------------

         procedure Append_Node
           (Target : in out List_Descriptor; New_Node : Count_Type)
         is
            M_Old : constant Nodes_Type_Base := Memory (Nodes, Free)
            with Ghost => Static;
         begin
            --  The new node is an isolated singleton

            Lemma_Is_Acyclic_Def (New_Node, Memory (Nodes, Free));
            Lemma_Reachable_Def (New_Node, Memory (Nodes, Free));

            if Target.Length = 0 then
               Target := (First | Last => New_Node, Length => 1);

            else
               --  The tail of the merged list is its own last node, so
               --  appending the singleton headed by New_Node adds exactly one
               --  node.

               Lemma_Reachable_Is_Acyclic
                 (Target.First, Target.Last, Memory (Nodes, Free));
               Lemma_Reachable_Def (Target.Last, Memory (Nodes, Free));

               Nodes (New_Node).Prev := Target.Last;
               Nodes (Target.Last).Next := New_Node;

               --  Only the Next link of the old tail changed, so the three
               --  lists are reconstructed on the final memory in one step
               --  each: neither part goes through that node.

               Lemma_Reachable_After_Set
                 (Target.First,
                  Target.Last,
                  New_Node,
                  M_Old,
                  Memory (Nodes, Free));
               Lemma_Is_Acyclic_After_Set
                 (Target.First,
                  Target.Last,
                  New_Node,
                  M_Old,
                  Memory (Nodes, Free));

               pragma
                 Assert
                   (Static =>
                      Memory_Index_Sets."<="
                        (Reachable_Set (Target.First, M_Old),
                         Reachable_Set (Target.First, Memory (Nodes, Free))));

               Target.Last := New_Node;
               Target.Length := Target.Length + 1;
            end if;
         end Append_Node;

         ------------------
         -- Detach_First --
         ------------------

         procedure Detach_First
           (Source : in out List_Descriptor; Detached : out Count_Type)
         is
            M_Old : constant Nodes_Type_Base := Memory (Nodes, Free)
            with Ghost => Static;
            S_Old : constant List_Descriptor := Source
            with Ghost => Static;
         begin
            Detached := Source.First;

            if Source.Length = 1 then

               --  The sole node of the segment is both its head and its tail,
               --  so it is already isolated.

               Lemma_Reachable_Def (Detached, Memory (Nodes, Free));
               Source := No_Segment;

            else
               Source :=
                 (First  => Nodes (Detached).Next,
                  Last   => Source.Last,
                  Length => Source.Length - 1);

               Lemma_Reachable_Def (Detached, Memory (Nodes, Free));
               Lemma_Is_Acyclic_Def (Detached, Memory (Nodes, Free));

               Nodes (Source.First).Prev := 0;

               Lemma_Reachable_Preserved
                 (Source.First, M_Old, Memory (Nodes, Free));
               Lemma_Is_Acyclic_Preserved
                 (Source.First, M_Old, Memory (Nodes, Free));

               declare
                  M_Interm : constant Nodes_Type_Base := Memory (Nodes, Free)
                  with Ghost => Static;
               begin
                  Nodes (Detached).Next := 0;

                  Lemma_Reachable_Preserved
                    (Source.First, M_Interm, Memory (Nodes, Free));
                  Lemma_Is_Acyclic_Preserved
                    (Source.First, M_Interm, Memory (Nodes, Free));
               end;

               pragma
                 Assert
                   (Static =>
                      Is_Add
                        (Reachable_Set (Source.First, Memory (Nodes, Free)),
                         Reachable_Set (S_Old.First, M_Old),
                         Detached));
            end if;
         end Detach_First;

         -----------------
         -- Merge_Parts --
         -----------------

         procedure Merge_Parts
           (Part1, Part2 : List_Descriptor; Merged : out List_Descriptor)
         is
            M_Old : constant Nodes_Type_Base := Memory (Nodes, Free)
            with Ghost => Static;

            All_Cells : constant Memory_Index_Set :=
              Memory_Index_Sets.Union
                (Reachable_Set (Part1.First, Memory (Nodes, Free)),
                 Reachable_Set (Part2.First, Memory (Nodes, Free)))
            with Ghost => Static;

            Total : constant Count_Type := Part1.Length + Part2.Length;

            P1 : List_Descriptor := Part1;
            P2 : List_Descriptor := Part2;

            Take_From_P2 : Boolean;
            Detached     : Count_Type;

            M_Entry                          : Nodes_Type_Base := M_Old
            with Ghost => Static;
            P1_Entry, P2_Entry, Merged_Entry : List_Descriptor
            with Ghost => Static;
            --  The memory and the three descriptors at the start of the
            --  current iteration.

            procedure Lemma_Equal_Transitive (S1, S2, S3 : Memory_Index_Set)
            with
              Ghost => Static,
              Pre   =>
                Memory_Index_Sets."=" (S1, S2)
                and then Memory_Index_Sets."=" (S2, S3),
              Post  => Memory_Index_Sets."=" (S1, S3);
            --  Compose extensional equality outside the merge loop's context

            procedure Lemma_Segment_Preserved
              (M1, M2   : Nodes_Type_Base;
               Elements : Elements_Array;
               D        : List_Descriptor)
            with
              Ghost => Static,
              Pre   =>
                M1'First = M2'First
                and then M1'Last = M2'Last
                and then Segment_Valid (M1, Elements, D)
                and then Valid_Memory (M2)
                and then (for all N of M2 => N.Prev'Initialized)
                and then
                  (for all I of Reachable_Set (D.First, M1) =>
                     M1 (I).Prev = M2 (I).Prev
                     and then M1 (I).Next = M2 (I).Next),
              Post  =>
                Segment_Valid (M2, Elements, D)
                and then
                  Memory_Index_Sets."="
                    (Reachable_Set (D.First, M1), Reachable_Set (D.First, M2))
                and then
                  Memory_Index_Sets.Length (Reachable_Set (D.First, M1))
                  = Memory_Index_Sets.Length (Reachable_Set (D.First, M2));
            --  Preserve a segment whose links are unchanged

            procedure Lemma_Still_Covered
              (Old_Merged, Old_P1, Old_P2 : Memory_Index_Set;
               New_Merged, New_P1, New_P2 : Memory_Index_Set;
               Moved                      : Positive_Count_Type)
            with
              Ghost => Static,
              Pre   =>
                Memory_Index_Sets."<=" (Old_P1, All_Cells)
                and then Memory_Index_Sets."<=" (Old_P2, All_Cells)
                and then Memory_Index_Sets."<=" (Old_Merged, All_Cells)
                and then Memory_Index_Sets.No_Overlap (Old_P1, Old_P2)
                and then Memory_Index_Sets.No_Overlap (Old_Merged, Old_P1)
                and then Memory_Index_Sets.No_Overlap (Old_Merged, Old_P2)
                and then
                  (for all I of All_Cells =>
                     Memory_Index_Sets.Contains (Old_Merged, I)
                     or else Memory_Index_Sets.Contains (Old_P1, I)
                     or else Memory_Index_Sets.Contains (Old_P2, I))
                and then Is_Add (Old_Merged, New_Merged, Moved)
                and then
                  (if Take_From_P2
                   then
                     Memory_Index_Sets."=" (Old_P1, New_P1)
                     and then Is_Add (New_P2, Old_P2, Moved)
                   else
                     Memory_Index_Sets."=" (Old_P2, New_P2)
                     and then Is_Add (New_P1, Old_P1, Moved)),
              Post  =>
                Memory_Index_Sets."<=" (New_P1, All_Cells)
                and then Memory_Index_Sets."<=" (New_P2, All_Cells)
                and then Memory_Index_Sets."<=" (New_Merged, All_Cells)
                and then Memory_Index_Sets.No_Overlap (New_P1, New_P2)
                and then Memory_Index_Sets.No_Overlap (New_Merged, New_P1)
                and then Memory_Index_Sets.No_Overlap (New_Merged, New_P2)
                and then
                  (for all I of All_Cells =>
                     Memory_Index_Sets.Contains (New_Merged, I)
                     or else Memory_Index_Sets.Contains (New_P1, I)
                     or else Memory_Index_Sets.Contains (New_P2, I));
            --  A merge step keeps the three lists covering the whole node
            --  set: the merged list only grows, and each part loses at most
            --  the moved node, which the merged list gains. Isolated in a
            --  lemma so that this set reasoning does not run in the merge
            --  loop's context.

            ----------------------------
            -- Lemma_Equal_Transitive --
            ----------------------------

            procedure Lemma_Equal_Transitive (S1, S2, S3 : Memory_Index_Set) is
            begin
               null;
            end Lemma_Equal_Transitive;

            -----------------------------
            -- Lemma_Segment_Preserved --
            -----------------------------

            procedure Lemma_Segment_Preserved
              (M1, M2   : Nodes_Type_Base;
               Elements : Elements_Array;
               D        : List_Descriptor) is
            begin
               Lemma_Reachable_Preserved (D.First, M1, M2);
               Lemma_Is_Acyclic_Preserved (D.First, M1, M2);
            end Lemma_Segment_Preserved;

            -------------------------
            -- Lemma_Still_Covered --
            -------------------------

            procedure Lemma_Still_Covered
              (Old_Merged, Old_P1, Old_P2 : Memory_Index_Set;
               New_Merged, New_P1, New_P2 : Memory_Index_Set;
               Moved                      : Positive_Count_Type) is
            begin
               null;
            end Lemma_Still_Covered;

         begin
            Merged := No_Segment;

            while P1.Length /= 0 or else P2.Length /= 0 loop
               pragma Loop_Invariant (Static => Valid_Links (Nodes, Free));
               pragma
                 Loop_Invariant
                   (Static => Valid_Elements (Nodes, Elements, Free));
               pragma
                 Loop_Invariant
                   (Static =>
                      Segment_Valid (Memory (Nodes, Free), Elements, P1));
               pragma
                 Loop_Invariant
                   (Static =>
                      Segment_Valid (Memory (Nodes, Free), Elements, P2));
               pragma
                 Loop_Invariant
                   (Static =>
                      Segment_Valid (Memory (Nodes, Free), Elements, Merged));
               pragma
                 Loop_Invariant
                   (Static =>
                      Memory_Index_Sets.No_Overlap
                        (Reachable_Set (P1.First, Memory (Nodes, Free)),
                         Reachable_Set (P2.First, Memory (Nodes, Free))));
               pragma
                 Loop_Invariant
                   (Static =>
                      Memory_Index_Sets.No_Overlap
                        (Reachable_Set (Merged.First, Memory (Nodes, Free)),
                         Reachable_Set (P1.First, Memory (Nodes, Free))));
               pragma
                 Loop_Invariant
                   (Static =>
                      Memory_Index_Sets.No_Overlap
                        (Reachable_Set (Merged.First, Memory (Nodes, Free)),
                         Reachable_Set (P2.First, Memory (Nodes, Free))));
               pragma
                 Loop_Invariant
                   (Static =>
                      Memory_Index_Sets."<="
                        (Reachable_Set (Merged.First, Memory (Nodes, Free)),
                         All_Cells));
               pragma
                 Loop_Invariant
                   (Static =>
                      Memory_Index_Sets."<="
                        (Reachable_Set (P1.First, Memory (Nodes, Free)),
                         All_Cells));
               pragma
                 Loop_Invariant
                   (Static =>
                      Memory_Index_Sets."<="
                        (Reachable_Set (P2.First, Memory (Nodes, Free)),
                         All_Cells));
               pragma
                 Loop_Invariant
                   (Static =>
                      (for all I of All_Cells =>
                         Memory_Index_Sets.Contains
                           (Reachable_Set (Merged.First, Memory (Nodes, Free)),
                            I)
                         or else
                           Memory_Index_Sets.Contains
                             (Reachable_Set (P1.First, Memory (Nodes, Free)),
                              I)
                         or else
                           Memory_Index_Sets.Contains
                             (Reachable_Set (P2.First, Memory (Nodes, Free)),
                              I)));
               pragma
                 Loop_Invariant
                   (Static => Merged.Length + P1.Length + P2.Length = Total);
               pragma
                 Loop_Invariant
                   (Static =>
                      Untouched_Outside
                        (M_Old, Memory (Nodes, Free), All_Cells));
               pragma
                 Loop_Variant (Static => (Decreases => P1.Length + P2.Length));

               M_Entry := Memory (Nodes, Free);
               P1_Entry := P1;
               P2_Entry := P2;
               Merged_Entry := Merged;

               if P1.Length = 0 then
                  Take_From_P2 := True;
               elsif P2.Length = 0 then
                  Take_From_P2 := False;
               else
                  --  If the compared elements are equal then Take_From_P2
                  --  must be False in order to ensure stability.

                  Take_From_P2 :=
                    Constant_Access (Elements (P2.First)).all
                    < Constant_Access (Elements (P1.First)).all;
               end if;

               --  The other part and the merged list lie outside the part the
               --  node is taken from, so the detach leaves them alone.

               if Take_From_P2 then
                  Detach_First (P2, Detached);

                  Lemma_Reachable_Preserved
                    (P1.First, M_Entry, Memory (Nodes, Free));
                  Lemma_Is_Acyclic_Preserved
                    (P1.First, M_Entry, Memory (Nodes, Free));
               else
                  Detach_First (P1, Detached);

                  Lemma_Reachable_Preserved
                    (P2.First, M_Entry, Memory (Nodes, Free));
                  Lemma_Is_Acyclic_Preserved
                    (P2.First, M_Entry, Memory (Nodes, Free));
               end if;

               Lemma_Reachable_Preserved
                 (Merged.First, M_Entry, Memory (Nodes, Free));
               Lemma_Is_Acyclic_Preserved
                 (Merged.First, M_Entry, Memory (Nodes, Free));

               declare
                  M_Det : constant Nodes_Type_Base := Memory (Nodes, Free)
                  with Ghost => Static;

               begin
                  pragma
                    Assert (Static => Segment_Valid (M_Det, Elements, P1));
                  pragma
                    Assert (Static => Segment_Valid (M_Det, Elements, P2));

                  Lemma_Segment_Preserved (M_Entry, M_Det, Elements, Merged);

                  Append_Node (Merged, Detached);

                  pragma
                    Assert
                      (Static =>
                         Memory_Index_Sets.No_Overlap
                           (Reachable_Set (P1.First, M_Det),
                            Reachable_Set
                              (Merged.First, Memory (Nodes, Free))));

                  Lemma_Segment_Preserved
                    (M_Det, Memory (Nodes, Free), Elements, P1);
                  Lemma_Segment_Preserved
                    (M_Det, Memory (Nodes, Free), Elements, P2);

                  Lemma_Equal_Transitive
                    (Reachable_Set
                       ((if Take_From_P2
                         then P1_Entry.First
                         else P2_Entry.First),
                        M_Entry),
                     Reachable_Set
                       ((if Take_From_P2 then P1.First else P2.First), M_Det),
                     Reachable_Set
                       ((if Take_From_P2 then P1.First else P2.First),
                        Memory (Nodes, Free)));
               end;

               --  Every node the three lists held on entry is still on one of
               --  them: the merged list only grew, and each part lost at most
               --  the detached node, which the merged list took.

               Lemma_Still_Covered
                 (Reachable_Set (Merged_Entry.First, M_Entry),
                  Reachable_Set (P1_Entry.First, M_Entry),
                  Reachable_Set (P2_Entry.First, M_Entry),
                  Reachable_Set (Merged.First, Memory (Nodes, Free)),
                  Reachable_Set (P1.First, Memory (Nodes, Free)),
                  Reachable_Set (P2.First, Memory (Nodes, Free)),
                  Detached);

               pragma
                 Assert
                   (Static =>
                      Untouched_Outside
                        (M_Entry, Memory (Nodes, Free), All_Cells));
            end loop;

            --  Both parts are exhausted, so the merged list holds every node

            pragma
              Assert
                (Static =>
                   Memory_Index_Sets.Is_Empty
                     (Reachable_Set (P1.First, Memory (Nodes, Free))));
            pragma
              Assert
                (Static =>
                   Memory_Index_Sets.Is_Empty
                     (Reachable_Set (P2.First, Memory (Nodes, Free))));
            pragma
              Assert
                (Static =>
                   Memory_Index_Sets."="
                     (Reachable_Set (Merged.First, Memory (Nodes, Free)),
                      All_Cells));
         end Merge_Parts;

         ----------------
         -- Merge_Sort --
         ----------------

         procedure Merge_Sort (Arg : in out List_Descriptor) is
            Part1, Part2 : List_Descriptor;

         begin
            if Arg.Length < 2 then

               --  Already sorted

               return;
            end if;

            Split_List (Arg, Part1, Part2);
            Sort_Parts (Part1, Part2);
            Merge_Parts (Part1, Part2, Arg);
         end Merge_Sort;

         ----------------
         -- Sort_Parts --
         ----------------

         procedure Sort_Parts (Part1, Part2 : in out List_Descriptor) is
            M_Split : constant Nodes_Type_Base := Memory (Nodes, Free)
            with Ghost => Static;

         begin
            Merge_Sort (Part1);

            --  Part2 lies outside Part1, so sorting Part1 left it alone.
            --  Part2 being closed under Next is what places the successor
            --  of each of its nodes outside Part1 too.

            Lemma_Reachable_Preserved
              (Part2.First, M_Split, Memory (Nodes, Free));
            Lemma_Is_Acyclic_Preserved
              (Part2.First, M_Split, Memory (Nodes, Free));
            Lemma_Reachable_Closed_By_Next (Part2.First, M_Split);

            declare
               M_Sorted1 : constant Nodes_Type_Base := Memory (Nodes, Free)
               with Ghost => Static;
            begin
               Merge_Sort (Part2);

               Lemma_Reachable_Preserved
                 (Part1.First, M_Sorted1, Memory (Nodes, Free));
               Lemma_Is_Acyclic_Preserved
                 (Part1.First, M_Sorted1, Memory (Nodes, Free));
               Lemma_Reachable_Closed_By_Next (Part1.First, M_Sorted1);
            end;
         end Sort_Parts;

         ----------------
         -- Split_List --
         ----------------

         procedure Split_List
           (Unsplit : List_Descriptor; Part1, Part2 : out List_Descriptor)
         is
            M_Old : constant Nodes_Type_Base := Memory (Nodes, Free)
            with Ghost => Static;

            Rover      : Count_Type := Unsplit.First;
            Bump_Count : constant Count_Type := (Unsplit.Length - 1) / 2;

         begin
            for Iter in 1 .. Bump_Count loop
               pragma
                 Loop_Invariant
                   (Static => Rover in Memory (Nodes, Free)'Range);
               pragma
                 Loop_Invariant
                   (Static =>
                      Reachable (Unsplit.First, Memory (Nodes, Free), Rover));
               pragma
                 Loop_Invariant
                   (Static =>
                      Memory_Index_Sets.Length
                        (Reachable_Set (Rover, Memory (Nodes, Free)))
                      = Big_Conversions.To_Big (Unsplit.Length - Iter + 1));

               Lemma_Reachable_Is_Acyclic
                 (Unsplit.First, Rover, Memory (Nodes, Free));
               Lemma_Reachable_Def (Rover, Memory (Nodes, Free));
               Lemma_Reachable_Closed_By_Next
                 (Unsplit.First, Memory (Nodes, Free));

               Rover := Nodes (Rover).Next;
            end loop;

            Lemma_Reachable_Is_Acyclic
              (Unsplit.First, Rover, Memory (Nodes, Free));
            Lemma_Reachable_Def (Rover, Memory (Nodes, Free));
            Lemma_Reachable_Closed_By_Next
              (Unsplit.First, Memory (Nodes, Free));

            Part1 :=
              (First  => Unsplit.First,
               Last   => Rover,
               Length => Bump_Count + 1);

            Part2 :=
              (First  => Nodes (Rover).Next,
               Last   => Unsplit.Last,
               Length => Unsplit.Length - Part1.Length);

            pragma
              Assert (Static => Part2.First in Memory (Nodes, Free)'Range);
            pragma
              Assert
                (Static =>
                   Memory_Index_Sets.Length
                     (Reachable_Set (Part2.First, Memory (Nodes, Free)))
                   = Big_Conversions.To_Big (Part2.Length));

            Lemma_Reachable_Is_Acyclic
              (Unsplit.First, Part2.First, Memory (Nodes, Free));
            Lemma_Reachable_Included
              (Unsplit.First, Part2.First, Memory (Nodes, Free));

            --  The tail of the segment belongs to the second part: Rover
            --  heads two nodes or more, so it is not the tail itself, and the
            --  two are ordered along the chain.

            Lemma_Reachable_Is_Acyclic
              (Unsplit.First, Unsplit.Last, Memory (Nodes, Free));
            Lemma_Reachable_Def (Unsplit.Last, Memory (Nodes, Free));
            Lemma_Reachable_Ordered
              (Unsplit.First, Rover, Unsplit.Last, Memory (Nodes, Free));

            pragma
              Assert
                (Static =>
                   Reachable
                     (Part2.First, Memory (Nodes, Free), Unsplit.Last));

            --  Detach

            Nodes (Part1.Last).Next := 0;
            Nodes (Part2.First).Prev := 0;

            Lemma_Reachable_After_Set
              (Part1.First, Part1.Last, 0, M_Old, Memory (Nodes, Free));
            Lemma_Is_Acyclic_After_Set
              (Part1.First, Part1.Last, 0, M_Old, Memory (Nodes, Free));
            Lemma_Reachable_Preserved
              (Part2.First, M_Old, Memory (Nodes, Free));
            Lemma_Is_Acyclic_Preserved
              (Part2.First, M_Old, Memory (Nodes, Free));

            Lemma_Reachable_Closed_By_Next (Part1.First, Memory (Nodes, Free));
            Lemma_Reachable_Closed_By_Next (Part2.First, Memory (Nodes, Free));

            --  Establish backward links before membership in the first part,
            --  so that closure by Next can exclude the second part.

            pragma
              Assert
                (Static =>
                   (for all I of
                      Reachable_Set (Part1.First, Memory (Nodes, Free)) =>
                      (if Memory (Nodes, Free) (I).Prev /= 0
                       then
                         Memory (Nodes, Free) (Memory (Nodes, Free) (I).Prev)
                           .Next
                         = I)));
            pragma
              Assert
                (Static =>
                   (for all I of
                      Reachable_Set (Part1.First, Memory (Nodes, Free)) =>
                      (if Memory (Nodes, Free) (I).Prev /= 0
                       then
                         Reachable
                           (Part1.First,
                            Memory (Nodes, Free),
                            Memory (Nodes, Free) (I).Prev))));
         end Split_List;

      begin
         if Length <= 1 then
            return;
         end if;

         Merge_Sort (Whole);

         First := Whole.First;
         Last := Whole.Last;

         pragma
           Assert
             (Static => Active_List_Valid (Nodes, Free, First, Last, Length));

         --  The sort permutes the links of the active nodes and leaves every
         --  other node alone, so the free store is untouched and the active
         --  set is the same as on entry.

         Lemma_Free_List_Preserved (Free, M_Old, Memory (Nodes, Free));

         pragma Assert (Static => Covered (Nodes, Free, First, 0));
         pragma
           Assert
             (Static =>
                Structural_Invariant (Nodes, Free, First, Last, Length));
      end Sort;

   end Generic_Sorting;

   ------------
   -- Insert --
   ------------

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
   is
      J  : Count_Type;
      L0 : constant Count_Type := Length
      with Ghost => Static;

   begin
      Allocate
        (Nodes, Elements, Free, First, Last, Length, New_Item, New_Node => J);
      Insert_Internal
        (Nodes, Free, First, Last, Length, Before, New_Node => J);
      Position := J;

      for Index in 2 .. Count loop
         pragma
           Loop_Invariant
             (Static =>
                Structural_Invariant (Nodes, Free, First, Last, Length));
         pragma
           Loop_Invariant (Static => Valid_Elements (Nodes, Elements, Free));
         pragma Loop_Invariant (Static => Length = L0 + (Index - 1));
         pragma
           Loop_Invariant
             (Static => Length + (Count - Index + 1) <= Nodes'Last);
         pragma
           Loop_Invariant
             (Static =>
                Before = 0
                or else
                  Memory_Index_Sets.Contains
                    (Active_Set (Nodes, Free, First), Before));

         Allocate
           (Nodes,
            Elements,
            Free,
            First,
            Last,
            Length,
            New_Item,
            New_Node => J);
         Insert_Internal
           (Nodes, Free, First, Last, Length, Before, New_Node => J);
      end loop;
   end Insert;

   -----------------------
   -- Insert_First_Node --
   -----------------------

   procedure Insert_First_Node
     (Nodes    : in out Node_Array;
      Free     : Count_Type'Base;
      First    : in out Count_Type;
      Last     : Count_Type;
      New_Node : Count_Type;
      Count    : Count_Type)
   is
      M_Old : constant Nodes_Type_Base := Memory (Nodes, Free)
      with Ghost => Static;
      F_Old : constant Count_Type := First
      with Ghost => Static;
   begin
      Nodes (New_Node).Next := First;
      Nodes (First).Prev := New_Node;
      First := New_Node;
      Nodes (First).Prev := 0;

      Lemma_Reachable_Preserved (F_Old, M_Old, Memory (Nodes, Free));
      Lemma_Is_Acyclic_Preserved (F_Old, M_Old, Memory (Nodes, Free));
      Lemma_Is_Acyclic_Def (New_Node, Memory (Nodes, Free));
      Lemma_Reachable_Def (New_Node, Memory (Nodes, Free));

      pragma
        Assert
          (Static => Active_List_Valid (Nodes, Free, First, Last, Count + 1));
      Lemma_Free_List_Preserved (Free, M_Old, Memory (Nodes, Free));
   end Insert_First_Node;

   --------------------------
   -- Insert_Interior_Node --
   --------------------------

   procedure Insert_Interior_Node
     (Nodes    : in out Node_Array;
      Free     : Count_Type'Base;
      First    : Count_Type;
      Last     : Count_Type;
      Before   : Count_Type;
      New_Node : Count_Type;
      Count    : Count_Type)
   is
      P     : constant Count_Type := Nodes (Before).Prev;
      M_Old : constant Nodes_Type_Base := Memory (Nodes, Free)
      with Ghost => Static;
   begin
      Nodes (New_Node).Next := Before;
      Nodes (New_Node).Prev := P;

      declare
         M1 : constant Nodes_Type_Base := Memory (Nodes, Free)
         with Ghost => Static;
      begin
         Lemma_Reachable_Preserved (First, M_Old, M1);
         Lemma_Is_Acyclic_Preserved (First, M_Old, M1);

         Lemma_Reachable_Is_Acyclic (First, Before, M_Old);
         Lemma_Reachable_Included (First, Before, M_Old);
         Lemma_Reachable_Preserved (Before, M_Old, M1);
         Lemma_Is_Acyclic_Preserved (Before, M_Old, M1);
         Lemma_Is_Acyclic_Def (New_Node, M1);
         Lemma_Reachable_Def (New_Node, M1);
         Lemma_Is_Acyclic_Def (P, M1);
         Lemma_Reachable_Def (P, M1);
         Lemma_Reachable_Antisymmetric (First, Before, M1);

         Nodes (P).Next := New_Node;
         Nodes (Before).Prev := New_Node;

         Lemma_Reachable_After_Set
           (First, P, New_Node, M1, Memory (Nodes, Free));
         Lemma_Is_Acyclic_After_Set
           (First, P, New_Node, M1, Memory (Nodes, Free));
         Lemma_Reachable_Preserved (New_Node, M1, Memory (Nodes, Free));
         Lemma_Is_Acyclic_Preserved (New_Node, M1, Memory (Nodes, Free));
      end;

      Lemma_Add_Length
        (S1 => Reachable_Set (First, M_Old),
         S2 => Reachable_Set (First, Memory (Nodes, Free)),
         E  => New_Node);
      pragma
        Assert
          (Static => Active_List_Valid (Nodes, Free, First, Last, Count + 1));
      Lemma_Free_List_Preserved (Free, M_Old, Memory (Nodes, Free));
   end Insert_Interior_Node;

   ---------------------
   -- Insert_Internal --
   ---------------------

   procedure Insert_Internal
     (Nodes    : in out Node_Array;
      Free     : Count_Type'Base;
      First    : in out Count_Type;
      Last     : in out Count_Type;
      Count    : in out Count_Type;
      Before   : Count_Type;
      New_Node : Count_Type)
   is
      M_Old : constant Nodes_Type_Base := Memory (Nodes, Free)
      with Ghost => Static;
   begin
      if Count = 0 then
         pragma
           Assert
             (Static =>
                Memory_Index_Sets.Is_Empty (Active_Set (Nodes, Free, First)));
         First := New_Node;
         Last := New_Node;
         Nodes (First).Prev := 0;
         Nodes (Last).Next := 0;

         Lemma_Is_Acyclic_Def (New_Node, Memory (Nodes, Free));
         Lemma_Reachable_Def (New_Node, Memory (Nodes, Free));
         Lemma_Free_List_Preserved (Free, M_Old, Memory (Nodes, Free));
         pragma
           Assert
             (Static => Structural_Invariant (Nodes, Free, First, Last, 1));

      elsif Before = 0 then
         Insert_Last_Node (Nodes, Free, First, Last, New_Node, Count);

      elsif Before = First then
         Insert_First_Node (Nodes, Free, First, Last, New_Node, Count);

      else
         Insert_Interior_Node
           (Nodes, Free, First, Last, Before, New_Node, Count);
      end if;

      Count := Count + 1;
      pragma
        Assert
          (Static => Structural_Invariant (Nodes, Free, First, Last, Count));
   end Insert_Internal;

   ----------------------
   -- Insert_Last_Node --
   ----------------------

   procedure Insert_Last_Node
     (Nodes    : in out Node_Array;
      Free     : Count_Type'Base;
      First    : Count_Type;
      Last     : in out Count_Type;
      New_Node : Count_Type;
      Count    : Count_Type)
   is
      L_Old : constant Count_Type := Last
      with Ghost => Static;
      M_Old : constant Nodes_Type_Base := Memory (Nodes, Free)
      with Ghost => Static;
   begin
      Nodes (New_Node).Next := 0;
      Nodes (New_Node).Prev := Last;

      declare
         M1 : constant Nodes_Type_Base := Memory (Nodes, Free)
         with Ghost => Static;
      begin
         Lemma_Reachable_Preserved (First, M_Old, M1);
         Lemma_Is_Acyclic_Preserved (First, M_Old, M1);
         Lemma_Is_Acyclic_Def (New_Node, M1);
         Lemma_Reachable_Def (New_Node, M1);

         Nodes (Last).Next := New_Node;
         Last := New_Node;

         Lemma_Reachable_After_Set
           (First, L_Old, New_Node, M1, Memory (Nodes, Free));
         Lemma_Is_Acyclic_After_Set
           (First, L_Old, New_Node, M1, Memory (Nodes, Free));
      end;

      Lemma_Add_Length
        (S1 => Reachable_Set (First, M_Old),
         S2 => Reachable_Set (First, Memory (Nodes, Free)),
         E  => New_Node);
      Lemma_Free_List_Preserved (Free, M_Old, Memory (Nodes, Free));
      pragma
        Assert
          (Static => Active_List_Valid (Nodes, Free, First, Last, Count + 1));
   end Insert_Last_Node;

   ------------------
   -- Insert_Moved --
   ------------------

   procedure Insert_Moved
     (Nodes       : in out Node_Array;
      Elements    : in out Elements_Array;
      Free        : in out Count_Type'Base;
      First       : in out Count_Type;
      Last        : in out Count_Type;
      Length      : in out Count_Type;
      Before      : Count_Type;
      Source_Item : in out Holder_Type;
      Position    : out Count_Type) is
   begin
      Position := (if Free >= 0 then Free else -Free);
      Reserve_Node (Nodes, Free, First, Last, Length, Position);
      Move_Element (Source_Item, Elements (Position));
      Insert_Internal (Nodes, Free, First, Last, Length, Before, Position);
   end Insert_Moved;

   ----------------------
   -- Lemma_Add_Length --
   ----------------------

   procedure Lemma_Add_Length
     (S1, S2 : Memory_Index_Set; E : Positive_Count_Type)
   is
      S3 : constant Memory_Index_Set := Memory_Index_Sets.Add (S1, E)
      with Ghost => Static;
   begin
      pragma Assert (Memory_Index_Sets."<=" (S3, S2));
      pragma Assert (Memory_Index_Sets."<=" (S2, S3));
      pragma
        Assert
          (Memory_Index_Sets.Num_Overlaps (S2, S3)
           = Memory_Index_Sets.Length (S2));
      pragma
        Assert
          (Memory_Index_Sets.Num_Overlaps (S2, S3)
           = Memory_Index_Sets.Length (S3));
   end Lemma_Add_Length;

   ----------
   -- Move --
   ----------

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
      Source_Length   : in out Count_Type) is
   begin
      Clear
        (Target_Nodes,
         Target_Elements,
         Target_Free,
         Target_First,
         Target_Last,
         Target_Length);
      Splice
        (Target_Nodes,
         Target_Elements,
         Target_Free,
         Target_First,
         Target_Last,
         Target_Length,
         Source_Nodes,
         Source_Elements,
         Source_Free,
         Source_First,
         Source_Last,
         Source_Length,
         Before => 0);
   end Move;

   ------------------
   -- Release_Node --
   ------------------

   procedure Release_Node
     (Nodes : in out Node_Array;
      Free  : in out Count_Type'Base;
      First : Count_Type;
      Last  : Count_Type;
      Count : Count_Type;
      X     : Count_Type)
   is
      procedure Rebuild_Free_List (N : Node_Array; Head, Base : Count_Type)
      with
        Ghost => Static,
        Pre   =>
          Valid_Links (N, Head)
          and then Valid_Memory (Memory (N, Head))
          and then Head in N'Range
          and then Base in N'Range
          and then Head < Base
          and then N (Head).Next = Base
          and then N (Head).Prev = -1
          and then (for all J in Base .. N'Last - 1 => N (J).Next = J + 1)
          and then N (N'Last).Next = 0
          and then (for all J in Base .. N'Last => N (J).Prev = -1),
        Post  =>
          Is_Acyclic (Head, Memory (N, Head))
          and then
            Memory_Index_Sets.Contains
              (Reachable_Set (Head, Memory (N, Head)), Head)
          and then
            (for all I of Reachable_Set (Head, Memory (N, Head)) =>
               I = Head or else I in Base .. N'Last)
          and then
            (for all I of Reachable_Set (Head, Memory (N, Head)) =>
               N (I).Prev = -1)
          and then
            (for all I in Base .. N'Last =>
               Memory_Index_Sets.Contains
                 (Reachable_Set (Head, Memory (N, Head)), I))
          and then
            Memory_Index_Sets.Length (Reachable_Set (Head, Memory (N, Head)))
            = Big_Conversions.To_Big (N'Last - Base + 2);
      --  Reconstruct the explicit chain Head -> Base -> ... -> Capacity

      -----------------------
      -- Rebuild_Free_List --
      -----------------------

      procedure Rebuild_Free_List (N : Node_Array; Head, Base : Count_Type) is
         M : constant Nodes_Type_Base := Memory (N, Head)
         with Ghost => Static;
      begin
         for J in reverse Base .. N'Last loop
            Lemma_Is_Acyclic_Def (J, M);
            Lemma_Reachable_Def (J, M);

            pragma Loop_Invariant (Static => Is_Acyclic (J, M));
            pragma
              Loop_Invariant
                (Static =>
                   (for all I of Reachable_Set (J, M) => I in J .. N'Last));
            pragma
              Loop_Invariant
                (Static =>
                   (for all I in J .. N'Last =>
                      Memory_Index_Sets.Contains (Reachable_Set (J, M), I)));
            pragma
              Loop_Invariant
                (Static =>
                   Memory_Index_Sets.Length (Reachable_Set (J, M))
                   = Big_Conversions.To_Big (N'Last - J + 1));
         end loop;

         Lemma_Is_Acyclic_Def (Head, M);
         Lemma_Reachable_Def (Head, M);
      end Rebuild_Free_List;

      M_Old : constant Nodes_Type_Base := Memory (Nodes, Free)
      with Ghost => Static;
   begin
      Nodes (X).Prev := -1;

      if Free >= 0 then
         Nodes (X).Next := Free;

         Lemma_Reachable_Preserved (First, M_Old, Memory (Nodes, Free));
         Lemma_Is_Acyclic_Preserved (First, M_Old, Memory (Nodes, Free));
         pragma
           Assert
             (Static => Active_List_Valid (Nodes, Free, First, Last, Count));

         Lemma_Reachable_Preserved (Free, M_Old, Memory (Nodes, Free));
         Lemma_Is_Acyclic_Preserved (Free, M_Old, Memory (Nodes, Free));
         Lemma_Is_Acyclic_Def (X, Memory (Nodes, Free));
         Lemma_Reachable_Def (X, Memory (Nodes, Free));

         Free := X;
         pragma
           Assert
             (Static =>
                Structural_Invariant (Nodes, Free, First, Last, Count));

      elsif Free = -X - 1 then
         Lemma_Reachable_Closed_By_Next (First, M_Old);

         Nodes (X).Next := 0;
         Free := Free + 1;

         Lemma_Reachable_Preserved (First, M_Old, Memory (Nodes, Free));
         Lemma_Is_Acyclic_Preserved (First, M_Old, Memory (Nodes, Free));
         pragma
           Assert
             (Static => Active_List_Valid (Nodes, Free, First, Last, Count));
         pragma
           Assert
             (Static =>
                Structural_Invariant (Nodes, Free, First, Last, Count));

      elsif Free = -Nodes'Last - 1 then
         Nodes (X).Next := 0;
         Free := X;

         Lemma_Reachable_Preserved (First, M_Old, Memory (Nodes, Free));
         Lemma_Is_Acyclic_Preserved (First, M_Old, Memory (Nodes, Free));
         pragma
           Assert
             (Static => Active_List_Valid (Nodes, Free, First, Last, Count));

         Lemma_Is_Acyclic_Def (X, Memory (Nodes, Free));
         Lemma_Reachable_Def (X, Memory (Nodes, Free));
         pragma
           Assert
             (Static =>
                Structural_Invariant (Nodes, Free, First, Last, Count));

      else
         declare
            Base : constant Count_Type := -Free;
         begin
            for J in Base .. Nodes'Last - 1 loop
               Nodes (J).Next := J + 1;
               Nodes (J).Prev := -1;

               pragma Loop_Invariant (Static => Free = Free'Loop_Entry);
               pragma Loop_Invariant (Static => Valid_Links (Nodes, Free));
               pragma
                 Loop_Invariant
                   (Static =>
                      (for all K in Base .. J =>
                         Nodes (K).Prev'Initialized
                         and then Nodes (K).Next'Initialized
                         and then Nodes (K).Prev = -1
                         and then Nodes (K).Next = K + 1));
            end loop;

            Nodes (Nodes'Last).Next := 0;
            Nodes (Nodes'Last).Prev := -1;

            Free := X;
            Nodes (X).Next := Base;

            pragma
              Assert
                (Static =>
                   (for all I of Reachable_Set (First, M_Old) =>
                      I <= Memory (Nodes, Free)'Last
                      and then
                        Next_Link (M_Old (I))
                        = Next_Link (Memory (Nodes, Free) (I))));

            Lemma_Reachable_Preserved (First, M_Old, Memory (Nodes, Free));
            Lemma_Is_Acyclic_Preserved (First, M_Old, Memory (Nodes, Free));
            pragma
              Assert
                (Static =>
                   Active_List_Valid (Nodes, Free, First, Last, Count));

            Rebuild_Free_List (Nodes, X, Base);
            pragma
              Assert
                (Static =>
                   Structural_Invariant (Nodes, Free, First, Last, Count));
         end;
      end if;
   end Release_Node;

   ---------------------
   -- Replace_Element --
   ---------------------

   procedure Replace_Element (H : in out Holder_Type; New_Item : Element_Type)
   is
   begin
      Reclaim (H);
      Fill (H, New_Item);
   end Replace_Element;

   ------------------
   -- Reserve_Node --
   ------------------

   procedure Reserve_Node
     (Nodes    : in out Node_Array;
      Free     : in out Count_Type'Base;
      First    : Count_Type;
      Last     : Count_Type;
      Count    : Count_Type;
      New_Node : Count_Type)
   is
      M_Old : constant Nodes_Type_Base := Memory (Nodes, Free)
      with Ghost => Static;
   begin
      Disclose_Reachable;
      Disclose_Is_Acyclic;

      if Free >= 0 then
         Free := Nodes (New_Node).Next;
      else
         Nodes (New_Node).Prev := -1;
         Nodes (New_Node).Next := 0;
         Free := Free - 1;
      end if;

      Lemma_Reachable_Preserved (First, M_Old, Memory (Nodes, Free));
      Lemma_Is_Acyclic_Preserved (First, M_Old, Memory (Nodes, Free));
      Lemma_Free_List_Preserved (Free, M_Old, Memory (Nodes, Free));
      pragma
        Assert (Static => Active_List_Valid (Nodes, Free, First, Last, Count));
   end Reserve_Node;

   ----------------------
   -- Reverse_Elements --
   ----------------------

   procedure Reverse_Elements
     (Nodes : in out Node_Array;
      Free  : Count_Type'Base;
      First : in out Count_Type;
      Last  : in out Count_Type;
      Count : Count_Type)
   is
      N : Node_Array renames Nodes;

      Done : Count_Type := 0;
      Rest : Count_Type := First;
      Nxt  : Count_Type;

      M_Old : constant Nodes_Type_Base := Memory (Nodes, Free)
      with Ghost => Static;
      F_Old : constant Count_Type := First
      with Ghost => Static;
      L_Old : constant Count_Type := Last
      with Ghost => Static;

      function Cells_Partitioned
        (M          : Nodes_Type_Base;
         Done, Rest : Count_Type;
         All_Cells  : Memory_Index_Sets.Set) return Boolean
      is (Done in M'Range | 0
          and then Rest in M'Range | 0
          and then Is_Acyclic (Done, M)
          and then Is_Acyclic (Rest, M)
          and then
            Memory_Index_Sets.No_Overlap
              (Reachable_Set (Done, M), Reachable_Set (Rest, M))
          and then Memory_Index_Sets."<=" (Reachable_Set (Done, M), All_Cells)
          and then Memory_Index_Sets."<=" (Reachable_Set (Rest, M), All_Cells)
          and then
            (for all I of All_Cells =>
               Reachable (Done, M, I) or else Reachable (Rest, M, I))
          and then
            Memory_Index_Sets.Length (Reachable_Set (Done, M))
            + Memory_Index_Sets.Length (Reachable_Set (Rest, M))
            = Memory_Index_Sets.Length (All_Cells))
      with
        Ghost => Static,
        Pre   =>
          Valid_Memory (M) and then (for all I of All_Cells => I in M'Range);
      --  The lists starting at Done and Rest in M partition the set All_Cells

      function Valid_Segment
        (M : Nodes_Type_Base; F, L : Positive_Count_Type) return Boolean
      is (F in M'Range
          and then L in M'Range
          and then Reachable (F, M, L)
          and then M (L).Next = 0
          and then
            (for all I of Reachable_Set (F, M) =>
               M (I).Prev /= -1
               and then (if M (I).Next = 0 then I = L)
               and then
                 (if I /= F
                  then
                    M (I).Prev in M'Range
                    and then Reachable (F, M, M (I).Prev)
                    and then M (M (I).Prev).Next = I)))
      with
        Ghost => Static,
        Pre   =>
          Valid_Memory (M) and then (for all N of M => N.Prev'Initialized);
      --  There is a valid list segment starting at F and ending at L in M

      procedure Lemma_Reverse_Step
        (M1, M2 : Nodes_Type_Base; Done, Rest, Nxt : Count_Type)
      with
        Ghost => Static,
        Pre   =>
          Rest /= 0
          and then Valid_Memory (M_Old)
          and then (for all N of M_Old => N.Prev'Initialized)
          and then F_Old in M_Old'Range | 0
          and then
            (for all I of Reachable_Set (F_Old, M_Old) =>
               (if M_Old (I).Next = 0 then I = L_Old))

          and then Valid_Memory (M1)
          and then (for all N of M1 => N.Prev'Initialized)
          and then Valid_Memory (M2)
          and then (for all N of M2 => N.Prev'Initialized)
          and then M1'Last = M2'Last
          and then M1'Last = M_Old'Last
          and then Done in M1'Range | 0
          and then Rest in M1'Range
          and then Nxt = M1 (Rest).Next

          --  M2 is M1 with only Rest's links changed (Next -> Done)

          and then
            (for all I in M1'Range =>
               (if I /= Rest
                then
                  M1 (I).Next = M2 (I).Next
                  and then M1 (I).Prev = M2 (I).Prev))
          and then M2 (Rest).Next = Done
          and then M2 (Rest).Prev = Nxt

          and then
            Cells_Partitioned (M1, Done, Rest, Reachable_Set (F_Old, M_Old))

          --  Done heads a valid reversed doubly-linked list segment: F_Old is
          --  its tail (Next = 0), the head's Prev points at Rest, and every
          --  node is allocated and backward-consistent within the segment.

          and then
            (if Done = 0
             then Rest = F_Old
             else
               M1 (Done).Prev = Rest and then Valid_Segment (M1, Done, F_Old))

          --  Rest heads the untouched suffix; other nodes are unchanged

          and then
            (for all I of Reachable_Set (Rest, M1) =>
               M1 (I).Next = M_Old (I).Next
               and then M1 (I).Prev = M_Old (I).Prev)
          and then
            (for all I in M1'Range =>
               (if not Reachable (F_Old, M_Old, I)
                then
                  M1 (I).Next = M_Old (I).Next
                  and then M1 (I).Prev = M_Old (I).Prev)),
        Post  =>
          Cells_Partitioned (M2, Rest, Nxt, Reachable_Set (F_Old, M_Old))

          --  The suffix shrinks by one node (the loop variant)

          and then
            Memory_Index_Sets.Length (Reachable_Set (Nxt, M2))
            < Memory_Index_Sets.Length (Reachable_Set (Rest, M1))

          --  Rest now heads a valid reversed segment (Done := Rest /= 0)

          and then (if Nxt = 0 then Rest = L_Old)
          and then M2 (Rest).Prev = Nxt
          and then Valid_Segment (M2, Rest, F_Old)

          --  Rest heads the untouched suffix; other nodes are unchanged

          and then
            (for all I of Reachable_Set (Nxt, M2) =>
               M2 (I).Next = M_Old (I).Next
               and then M2 (I).Prev = M_Old (I).Prev)
          and then
            (for all I in M2'Range =>
               (if not Reachable (F_Old, M_Old, I)
                then
                  M2 (I).Next = M_Old (I).Next
                  and then M2 (I).Prev = M_Old (I).Prev));

      ------------------------
      -- Lemma_Reverse_Step --
      ------------------------

      procedure Lemma_Reverse_Step
        (M1, M2 : Nodes_Type_Base; Done, Rest, Nxt : Count_Type) is
      begin
         --  Split Rest off its suffix in M1, and get Is_Acyclic (Nxt, M1)

         Lemma_Reachable_Def (Rest, M1);
         Lemma_Is_Acyclic_Def (Rest, M1);

         --  Rest is on neither the Done list nor the Nxt suffix, so the single
         --  Next change at Rest preserves both lists across M1 -> M2.

         Lemma_Reachable_Preserved (Done, M1, M2);
         Lemma_Is_Acyclic_Preserved (Done, M1, M2);
         Lemma_Reachable_Preserved (Nxt, M1, M2);
         Lemma_Is_Acyclic_Preserved (Nxt, M1, M2);

         --  Rest now heads the acyclic list {Rest} + Done in M2

         Lemma_Is_Acyclic_Def (Rest, M2);
         Lemma_Reachable_Def (Rest, M2);
      end Lemma_Reverse_Step;

   begin
      if Count <= 1 then
         return;
      end if;

      --  Single-pass link reversal: walk front to back, moving each node from
      --  the head of the untouched suffix (Rest) to the head of the reversed
      --  prefix (Done), flipping its links. Done and Rest head two disjoint
      --  acyclic lists whose union is the active set; when Rest reaches 0 the
      --  list is reversed. Same final memory as an outside-in node swap, in
      --  O (Length).

      while Rest /= 0 loop
         pragma Loop_Invariant (Static => Valid_Links (Nodes, Free));
         pragma
           Loop_Variant
             (Static =>
                (Decreases =>
                   Memory_Index_Sets.Length
                     (Reachable_Set (Rest, Memory (Nodes, Free)))));

         pragma Loop_Invariant (Static => Valid_Memory (Memory (Nodes, Free)));
         pragma
           Loop_Invariant
             (Static =>
                Done in Memory (Nodes, Free)'Range | 0
                and then Rest in Memory (Nodes, Free)'Range | 0);
         pragma
           Loop_Invariant
             (Static =>
                Cells_Partitioned
                  (Memory (Nodes, Free),
                   Done,
                   Rest,
                   Reachable_Set (F_Old, M_Old)));
         pragma Loop_Invariant (Static => (if Done = 0 then Rest = F_Old));
         pragma Loop_Invariant (Static => (if Rest = 0 then Done = L_Old));
         pragma
           Loop_Invariant
             (Static =>
                (if Done /= 0
                 then
                   Memory (Nodes, Free) (Done).Prev = Rest
                   and Valid_Segment (Memory (Nodes, Free), Done, F_Old)));
         pragma
           Loop_Invariant
             (Static =>
                (for all I of Reachable_Set (Rest, Memory (Nodes, Free)) =>
                   Memory (Nodes, Free) (I).Next = M_Old (I).Next
                   and then Memory (Nodes, Free) (I).Prev = M_Old (I).Prev));
         pragma
           Loop_Invariant
             (Static =>
                (for all I in Memory (Nodes, Free)'Range =>
                   (if not Reachable (F_Old, M_Old, I)
                    then
                      Memory (Nodes, Free) (I).Next = M_Old (I).Next
                      and then
                        Memory (Nodes, Free) (I).Prev = M_Old (I).Prev)));

         declare
            M1 : constant Nodes_Type_Base := Memory (Nodes, Free)
            with Ghost => Static;
         begin
            --  Move Rest (head of the untouched suffix) to the head of the
            --  reversed list by pointing its Next at Done; the step lemma
            --  carries the whole invariant across the single link change.

            Nxt := N (Rest).Next;

            N (Rest).Next := Done;
            N (Rest).Prev := Nxt;

            Lemma_Reverse_Step (M1, Memory (Nodes, Free), Done, Rest, Nxt);
         end;

         Done := Rest;
         Rest := Nxt;
      end loop;

      --  Rest = 0: the suffix is empty and every active node is on the
      --  reversed list, now headed by Done = L_Old.

      pragma Assert (Static => Done = L_Old);

      Last := First;
      First := Done;

      --  The whole (reversed) active set is now RS (Done); its self-contained
      --  consistency gives Active_List_Valid directly.

      pragma
        Assert
          (Static =>
             Memory_Index_Sets."="
               (Reachable_Set (First, Memory (Nodes, Free)),
                Reachable_Set (F_Old, M_Old)));
      pragma
        Assert (Static => Active_List_Valid (Nodes, Free, First, Last, Count));

      --  The free store was never touched (only active nodes were relinked),
      --  so its chain (Next links) is preserved from M_Old.

      Lemma_Free_List_Preserved (Free, M_Old, Memory (Nodes, Free));

      pragma
        Assert
          (Static => Structural_Invariant (Nodes, Free, First, Last, Count));
   end Reverse_Elements;

   ------------------
   -- Reverse_Find --
   ------------------

   function Reverse_Find
     (Nodes    : Node_Array;
      Elements : Elements_Array;
      Free     : Count_Type'Base;
      First    : Count_Type;
      Last     : Count_Type;
      Length   : Count_Type;
      Item     : Element_Type;
      Position : Count_Type) return Count_Type
   is
      CFirst : Count_Type := Position;

   begin
      if CFirst = 0 then
         CFirst := Last;
      end if;

      if Length = 0 then
         return 0;

      else
         while CFirst /= 0 loop
            Lemma_Reachable_Is_Acyclic (First, CFirst, Memory (Nodes, Free));
            Lemma_Reachable_Def (CFirst, Memory (Nodes, Free));
            Lemma_Reachable_Included (First, CFirst, Memory (Nodes, Free));
            pragma
              Assert
                (Static =>
                   Memory_Index_Sets.Num_Overlaps
                     (Reachable_Set (CFirst, Memory (Nodes, Free)),
                      Reachable_Set (First, Memory (Nodes, Free)))
                   = Memory_Index_Sets.Length
                       (Reachable_Set (CFirst, Memory (Nodes, Free))));

            pragma Warnings (Off, "condition is always True");
            pragma Loop_Invariant (Static => CFirst /= 0);
            pragma
              Loop_Invariant
                (Static => Reachable (First, Memory (Nodes, Free), CFirst));
            pragma
              Loop_Variant
                (Static =>
                   (Decreases =>
                      Memory_Index_Sets.Length
                        (Reachable_Set (First, Memory (Nodes, Free)))
                      - Memory_Index_Sets.Length
                          (Reachable_Set (CFirst, Memory (Nodes, Free)))));
            pragma Warnings (On, "condition is always True");

            if Constant_Access (Elements (CFirst)).all = Item then
               return CFirst;
            else
               CFirst := Nodes (CFirst).Prev;
            end if;
         end loop;

         return 0;
      end if;
   end Reverse_Find;

   ------------
   -- Splice --
   ------------

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
   is
      Orig_Sum : constant Count_Type := Target_Length + Source_Length
      with Ghost => Static;
      --  The invariant sum of both lengths bounds the target below capacity

      Position : Count_Type;

   begin
      --  Transfer each payload before unlinking and releasing its source node

      while Source_Length > 1 loop
         pragma
           Loop_Invariant
             (Static =>
                Structural_Invariant
                  (Target_Nodes,
                   Target_Free,
                   Target_First,
                   Target_Last,
                   Target_Length));
         pragma
           Loop_Invariant
             (Static =>
                Valid_Elements (Target_Nodes, Target_Elements, Target_Free));
         pragma
           Loop_Invariant
             (Static =>
                Structural_Invariant
                  (Source_Nodes,
                   Source_Free,
                   Source_First,
                   Source_Last,
                   Source_Length));
         pragma
           Loop_Invariant
             (Static =>
                Valid_Elements (Source_Nodes, Source_Elements, Source_Free));
         pragma
           Loop_Invariant
             (Static =>
                (Before = 0
                 or else
                   Memory_Index_Sets.Contains
                     (Active_Set (Target_Nodes, Target_Free, Target_First),
                      Before)));
         pragma
           Loop_Invariant (Static => Target_Length + Source_Length = Orig_Sum);
         pragma Loop_Invariant (Static => Orig_Sum <= Target_Nodes'Last);
         pragma Loop_Variant (Static => (Decreases => Source_Length));

         Insert_Moved
           (Target_Nodes,
            Target_Elements,
            Target_Free,
            Target_First,
            Target_Last,
            Target_Length,
            Before,
            Source_Elements (Source_First),
            Position);
         declare
            X : constant Count_Type := Source_First;
         begin
            Unlink_First_Node
              (Source_Nodes,
               Source_Free,
               Source_First,
               Source_Last,
               Source_Length);
            Source_Length := Source_Length - 1;
            Release_Node
              (Source_Nodes,
               Source_Free,
               Source_First,
               Source_Last,
               Source_Length,
               X);
         end;
      end loop;

      if Source_Length = 1 then

         --  Transfer the last payload, then drop the sole node in the source

         Insert_Moved
           (Target_Nodes,
            Target_Elements,
            Target_Free,
            Target_First,
            Target_Last,
            Target_Length,
            Before,
            Source_Elements (Source_First),
            Position);
         declare
            X : constant Count_Type := Source_First;
         begin
            Unlink_Sole_Node
              (Source_Nodes,
               Source_Free,
               Source_First,
               Source_Last,
               Source_Length);
            Source_Length := Source_Length - 1;
            Release_Node
              (Source_Nodes,
               Source_Free,
               Source_First,
               Source_Last,
               Source_Length,
               X);
         end;
      end if;
   end Splice;

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
   is
      Target_Position : Count_Type;

   begin
      Insert_Moved
        (Target_Nodes,
         Target_Elements,
         Target_Free,
         Target_First,
         Target_Last,
         Target_Length,
         Before,
         Source_Elements (Position),
         Target_Position);

      --  Release the source node, then return the new target position.

      Detach_Node
        (Source_Nodes,
         Source_Free,
         Source_First,
         Source_Last,
         Source_Length,
         Position);
      Release_Node
        (Source_Nodes,
         Source_Free,
         Source_First,
         Source_Last,
         Source_Length,
         Position);

      Position := Target_Position;
   end Splice;

   procedure Splice
     (Nodes    : in out Node_Array;
      Free     : Count_Type'Base;
      First    : in out Count_Type;
      Last     : in out Count_Type;
      Count    : Count_Type;
      Before   : Count_Type;
      Position : Count_Type)
   is
      X : constant Count_Type := Position;

      procedure Lemma_Length_Ge_2
        (Nodes    : Node_Array;
         Free     : Count_Type'Base;
         First    : Count_Type;
         Last     : Count_Type;
         Count    : Count_Type;
         Before   : Count_Type;
         Position : Count_Type)
      with
        Ghost => Static,
        Pre   =>
          Structural_Invariant (Nodes, Free, First, Last, Count)
          and then Position in Memory (Nodes, Free)'Range
          and then
            Memory_Index_Sets.Contains
              (Active_Set (Nodes, Free, First), Position)
          and then Before in Memory (Nodes, Free)'Range | 0
          and then
            (Before = 0
             or else
               Memory_Index_Sets.Contains
                 (Active_Set (Nodes, Free, First), Before))
          and then Position /= Before
          and then Nodes (Position).Next /= Before,
        Post  => Count >= 2;
      --  A nontrivial relink has two distinct active nodes

      -----------------------
      -- Lemma_Length_Ge_2 --
      -----------------------

      procedure Lemma_Length_Ge_2
        (Nodes    : Node_Array;
         Free     : Count_Type'Base;
         First    : Count_Type;
         Last     : Count_Type;
         Count    : Count_Type;
         Before   : Count_Type;
         Position : Count_Type)
      is
         use Memory_Index_Sets;
         X : constant Positive_Count_Type := Position;
         Y : constant Positive_Count_Type :=
           (if Before = 0 then Nodes (X).Next else Before);
      begin
         if Before = 0 then
            Lemma_Reachable_Is_Acyclic (First, X, Memory (Nodes, Free));
            Lemma_Reachable_Included (First, X, Memory (Nodes, Free));
            Lemma_Reachable_Def (X, Memory (Nodes, Free));
         end if;
         pragma
           Assert
             (Num_Overlaps
                (Add (Add (Empty_Set, X), Y), Active_Set (Nodes, Free, First))
              = 2);
      end Lemma_Length_Ge_2;

   begin
      if Position = Before or else Nodes (X).Next = Before then
         return;
      end if;

      Lemma_Length_Ge_2 (Nodes, Free, First, Last, Count, Before, Position);

      --  Unlink X without changing the stored count

      if X = First then
         Unlink_First_Node (Nodes, Free, First, Last, Count);
      elsif X = Last then
         Unlink_Last_Node (Nodes, Free, First, Last, Count);
      else
         Unlink_Interior_Node (Nodes, Free, First, Last, Count, X);
      end if;

      --  X is detached; relink it into the remaining Count - 1 nodes

      if Before = 0 then
         Insert_Last_Node (Nodes, Free, First, Last, X, Count - 1);
      elsif Before = First then
         Insert_First_Node (Nodes, Free, First, Last, X, Count - 1);
      else
         Insert_Interior_Node (Nodes, Free, First, Last, Before, X, Count - 1);
      end if;
   end Splice;

   ----------
   -- Swap --
   ----------

   procedure Swap
     (Nodes    : Node_Array;
      Elements : in out Elements_Array;
      Free     : Count_Type'Base;
      I, J     : Count_Type) is
   begin
      Exchange (Elements, I, J);
   end Swap;

   ----------------
   -- Swap_Links --
   ----------------

   procedure Swap_Links
     (Nodes : in out Node_Array;
      Free  : Count_Type'Base;
      First : in out Count_Type;
      Last  : in out Count_Type;
      Count : Count_Type;
      I     : Count_Type;
      J     : Count_Type)
   is
      I_Next : Count_Type;
      J_Next : Count_Type;
   begin
      if I = J then
         return;
      end if;

      Lemma_Reachable_Closed_By_Next (First, Memory (Nodes, Free));

      I_Next := Nodes (I).Next;

      if I_Next = J then
         Splice (Nodes, Free, First, Last, Count, Before => I, Position => J);

      else
         J_Next := Nodes (J).Next;

         if J_Next = I then
            Splice
              (Nodes, Free, First, Last, Count, Before => J, Position => I);

         else
            Splice
              (Nodes,
               Free,
               First,
               Last,
               Count,
               Before   => I_Next,
               Position => J);
            Splice
              (Nodes,
               Free,
               First,
               Last,
               Count,
               Before   => J_Next,
               Position => I);
         end if;
      end if;
   end Swap_Links;

   -----------------------
   -- Unlink_First_Node --
   -----------------------

   procedure Unlink_First_Node
     (Nodes : in out Node_Array;
      Free  : Count_Type'Base;
      First : in out Count_Type;
      Last  : Count_Type;
      Count : Count_Type)
   is
      X     : constant Count_Type := First;
      M_Old : constant Nodes_Type_Base := Memory (Nodes, Free)
      with Ghost => Static;
   begin
      --  The successor heads a shorter acyclic list that no longer contains X

      Lemma_Is_Acyclic_Def (X, M_Old);
      Lemma_Reachable_Def (X, M_Old);

      First := Nodes (X).Next;
      Nodes (First).Prev := 0;

      --  Only Prev changed, so the active and free Next chains are preserved

      Lemma_Reachable_Preserved (First, M_Old, Memory (Nodes, Free));
      Lemma_Is_Acyclic_Preserved (First, M_Old, Memory (Nodes, Free));

      Lemma_Free_List_Preserved (Free, M_Old, Memory (Nodes, Free));

      pragma
        Assert
          (Static => Active_List_Valid (Nodes, Free, First, Last, Count - 1));
   end Unlink_First_Node;

   --------------------------
   -- Unlink_Interior_Node --
   --------------------------

   procedure Unlink_Interior_Node
     (Nodes : in out Node_Array;
      Free  : Count_Type'Base;
      First : Count_Type;
      Last  : Count_Type;
      Count : Count_Type;
      X     : Count_Type)
   is
      P     : constant Count_Type := Nodes (X).Prev;
      Q     : constant Count_Type := Nodes (X).Next;
      M_Old : constant Nodes_Type_Base := Memory (Nodes, Free)
      with Ghost => Static;
   begin
      --  X lies between active neighbours P and Q on the acyclic list

      Lemma_Reachable_Is_Acyclic (First, X, M_Old);
      Lemma_Reachable_Included (First, X, M_Old);
      Lemma_Reachable_Def (X, M_Old);
      Lemma_Is_Acyclic_Def (X, M_Old);

      pragma
        Assert
          (Static =>
             not Memory_Index_Sets.Is_Empty (Active_Set (Nodes, Free, First)));

      --  P reaches X, but neither X nor its successor Q reaches P

      Lemma_Reachable_Is_Acyclic (First, P, M_Old);
      Lemma_Reachable_Def (P, M_Old);
      Lemma_Reachable_Antisymmetric (X, P, M_Old);

      Nodes (Q).Prev := P;
      Nodes (P).Next := Q;

      --  Redirecting P to Q removes exactly X from the active chain

      Lemma_Reachable_After_Set (First, P, Q, M_Old, Memory (Nodes, Free));
      Lemma_Is_Acyclic_After_Set (First, P, Q, M_Old, Memory (Nodes, Free));

      Lemma_Add_Length
        (S1 => Reachable_Set (First, Memory (Nodes, Free)),
         S2 => Reachable_Set (First, M_Old),
         E  => X);

      pragma
        Assert
          (Static => Active_List_Valid (Nodes, Free, First, Last, Count - 1));

      Lemma_Free_List_Preserved (Free, M_Old, Memory (Nodes, Free));
   end Unlink_Interior_Node;

   ----------------------
   -- Unlink_Last_Node --
   ----------------------

   procedure Unlink_Last_Node
     (Nodes : in out Node_Array;
      Free  : Count_Type'Base;
      First : Count_Type;
      Last  : in out Count_Type;
      Count : Count_Type)
   is
      X     : constant Count_Type := Last;
      Y     : constant Count_Type := Nodes (X).Prev;
      M_Old : constant Nodes_Type_Base := Memory (Nodes, Free)
      with Ghost => Static;
   begin
      --  At least two nodes remain before the cut, so X has a predecessor Y

      Lemma_Reachable_Def (First, M_Old);

      Last := Y;
      Nodes (Y).Next := 0;

      Lemma_Reachable_After_Set (First, Y, 0, M_Old, Memory (Nodes, Free));
      Lemma_Is_Acyclic_After_Set (First, Y, 0, M_Old, Memory (Nodes, Free));

      --  X is the old tail, so its reachable set is the singleton {X}

      Lemma_Reachable_Is_Acyclic (First, X, M_Old);
      Lemma_Reachable_Def (X, M_Old);
      Lemma_Add_Length
        (S1 => Reachable_Set (First, Memory (Nodes, Free)),
         S2 => Reachable_Set (First, M_Old),
         E  => X);

      Lemma_Free_List_Preserved (Free, M_Old, Memory (Nodes, Free));

      pragma
        Assert
          (Static => Active_List_Valid (Nodes, Free, First, Last, Count - 1));
   end Unlink_Last_Node;

   ----------------------
   -- Unlink_Sole_Node --
   ----------------------

   procedure Unlink_Sole_Node
     (Nodes : Node_Array;
      Free  : Count_Type'Base;
      First : in out Count_Type;
      Last  : in out Count_Type;
      Count : Count_Type)
   is
      X : constant Count_Type := First;
   begin
      --  The active set is {X}; every other touched node is free

      Lemma_Reachable_Def (X, Memory (Nodes, Free));

      First := 0;
      Last := 0;

      pragma
        Assert (Static => Active_List_Valid (Nodes, Free, First, Last, 0));
   end Unlink_Sole_Node;

end SPARK.Containers.Formal.Generic_List_Operations;
