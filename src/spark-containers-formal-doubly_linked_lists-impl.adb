--
--  Copyright (C) 2004-2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

package body SPARK.Containers.Formal.Doubly_Linked_Lists.Impl
  with SPARK_Mode => On
is

   package Address_Comparisons is new
     SPARK.Containers.Formal.Impl.Address_Space.Address_Comparison (List);

   function Same_Object (Left, Right : List) return Boolean
   renames Address_Comparisons.Same_Object;

   function Limbo_State
     (Container : List; New_Node : Count_Type; Count : Count_Type)
      return Boolean
   is (Valid_Memory (Memory (Container))
       and then Container.First in Memory (Container)'Range | 0
       and then New_Node in Memory (Container)'Range
       and then Count < Container.Capacity
       and then Container.Nodes (New_Node).Prev'Initialized
       and then Container.Nodes (New_Node).Next'Initialized
       and then Container.Nodes (New_Node).Element'Initialized
       and then
         not Memory_Index_Sets.Contains (Active_Set (Container), New_Node)
       and then Active_List_Valid (Container, Count)
       and then
         Free_Chain_Valid
           (Container,
            Memory_Index_Sets.Add (Active_Set (Container), New_Node))
       and then Free_Count_Correct (Container, Count + 1)
       and then Covered (Container, New_Node))
   with Ghost => Static;
   --  The "limbo" state of node New_Node: off both the active and free lists
   --  (element set, links possibly stale) but with the active list still valid
   --  and holding Count nodes. Both Allocate/Insert_Internal (Count = Length,
   --  active untouched) and Unlink_*_Node/Free (Count = Length - 1, active
   --  minus the unlinked node) use it; the field Container.Length is
   --  independent of Count while a node is in limbo. New_Node is the Covered
   --  Extra node, so its stale Prev does not misclassify it as active.

   -----------------------
   -- Local Subprograms --
   -----------------------

   procedure Allocate
     (Container : in out List;
      New_Item  : Element_Type;
      New_Node  : out Count_Type)
   with
     Pre  =>
       (Static =>
          Structural_Invariant (Container)
          and then Container.Length < Container.Capacity),
     Post =>
       (Static =>
          (Limbo_State (Container, New_Node, Container.Length)
           and then Container.Length = Container.Length'Old
           and then Container.First = Container.First'Old
           and then Container.Last = Container.Last'Old
           and then
             Memory_Index_Sets."="
               (Active_Set (Container), Active_Set (Container'Old))));
   --  New_Node has been taken off the free list (its element set, still
   --  deallocated and off the active list) but not yet linked in. The active
   --  list is valid and the free list, now one node shorter and excluding
   --  New_Node, still forms a valid chain. Insert_Internal links New_Node in,
   --  restoring Structural_Invariant with Length + 1.

   procedure Free (Container : in out List; X : Count_Type)
   with
     Pre  =>
       (Static =>
          Valid_Memory (Memory (Container))
          and then Container.First in Memory (Container)'Range | 0
          and then X in Memory (Container)'Range
          and then Container.Length < Container.Capacity
          and then not Memory_Index_Sets.Contains (Active_Set (Container), X)
          and then Active_List_Valid (Container, Container.Length)
          and then
            Free_Chain_Valid
              (Container, Memory_Index_Sets.Add (Active_Set (Container), X))
          and then Free_Count_Correct (Container, Container.Length + 1)
          and then Covered (Container, X)),
     Post =>
       (Static =>
          Structural_Invariant (Container)
          and then Container.Length = Container.Length'Old
          and then Container.First = Container.First'Old
          and then Container.Last = Container.Last'Old
          and then
            Memory_Index_Sets."="
              (Active_Set (Container), Active_Set (Container'Old)));
   --  X is a dangling node: touched, off the active list, and off the free
   --  chain (the limbo state Allocate produces, symmetric to its Post). Free
   --  returns it to the free store, restoring Structural_Invariant with the
   --  same Length/First/Last.

   procedure Insert_First_Node
     (Container : in out List; New_Node : Count_Type; Count : Count_Type)
   with
     Inline,
     Pre  =>
       (Static =>
          Limbo_State (Container, New_Node, Count)
          and then Count >= 1
          and then Count < Count_Type'Last),
     Post =>
       (Static =>
          Structural_Invariant (Container, Count + 1)
          and then Container.Length = Container.Length'Old
          and then Container.Last = Container.Last'Old
          and then Container.First = New_Node
          and then
            Is_Add
              (Active_Set (Container'Old), Active_Set (Container), New_Node));
   --  Prepend the dangling New_Node as the new head (before the old First),
   --  Length-neutral: the active list gains exactly New_Node (Count -> Count +
   --  1) while Container.Length is unchanged. Count >= 1 so the list is
   --  non-empty. The caller does the single Length := Length + 1. Shared by
   --  Insert_Internal (Before = First) and Splice (variant 3).

   procedure Insert_Interior_Node
     (Container : in out List;
      Before    : Count_Type;
      New_Node  : Count_Type;
      Count     : Count_Type)
   with
     Inline,
     Pre  =>
       (Static =>
          Limbo_State (Container, New_Node, Count)
          and then Before in Memory (Container)'Range
          and then Memory_Index_Sets.Contains (Active_Set (Container), Before)
          and then Before /= Container.First
          and then Count < Count_Type'Last),
     Post =>
       (Static =>
          Structural_Invariant (Container, Count + 1)
          and then Container.Length = Container.Length'Old
          and then Container.First = Container.First'Old
          and then Container.Last = Container.Last'Old
          and then
            Is_Add
              (Active_Set (Container'Old), Active_Set (Container), New_Node));
   --  Insert the dangling New_Node immediately before the active node Before
   --  (not First, so it has an active predecessor P = Prev (Before)), Length-
   --  neutral: the active list gains exactly New_Node (Count -> Count + 1),
   --  First/Last unchanged. The caller does the single Length := Length + 1.
   --  Shared by Insert_Internal (interior Before) and Splice (variant 3).

   procedure Insert_Internal
     (Container : in out List; Before : Count_Type; New_Node : Count_Type)
   with
     Pre  =>
       (Static =>
          Limbo_State (Container, New_Node, Container.Length)
          and then
            (Before = 0
             or else
               Memory_Index_Sets.Contains (Active_Set (Container), Before))),
     Post =>
       (Static =>
          Structural_Invariant (Container)
          and then Container.Length = Container.Length'Old + 1

          --  Linking New_Node in adds exactly New_Node to the active list, so
          --  every node already active stays active (keeps a caller's cursor,
          --  e.g. Insert's Before, valid across the call).

          and then
            Is_Add
              (Active_Set (Container'Old), Active_Set (Container), New_Node));
   --  New_Node is a dangling node (the limbo state Allocate produces): taken
   --  off the free list, element set, not yet linked. Insert_Internal links it
   --  into the active list before Before (or at the end when Before = 0),
   --  restoring Structural_Invariant with Length + 1.

   procedure Insert_Last_Node
     (Container : in out List; New_Node : Count_Type; Count : Count_Type)
   with
     Inline,
     Pre  =>
       (Static =>
          Limbo_State (Container, New_Node, Count)
          and then Count >= 1
          and then Count < Count_Type'Last),
     Post =>
       (Static =>
          Structural_Invariant (Container, Count + 1)
          and then Container.Length = Container.Length'Old
          and then Container.First = Container.First'Old
          and then Container.Last = New_Node
          and then
            Is_Add
              (Active_Set (Container'Old), Active_Set (Container), New_Node));
   --  Append the dangling New_Node as the new tail (after the old Last),
   --  Length-neutral: the active list gains exactly New_Node (Count -> Count +
   --  1). Count >= 1 so the list is non-empty, First unchanged. The caller
   --  does the single Length := Length + 1. Shared by Insert_Internal
   --  (Before = 0) and Splice (variant 3).

   procedure Lemma_Add_Length
     (S1, S2 : Memory_Index_Set; E : Positive_Count_Type)
   with
     Ghost => Static,
     Pre   => Is_Add (S1, S2, E),
     Post  =>
       Memory_Index_Sets.Length (S2) = Memory_Index_Sets.Length (S1) + 1;
   --  Two functional sets related by "S2 is S1 with the single new element E
   --  added" -- stated extensionally: E is in S2 but not in S1, S1 is included
   --  in S2, and every element of S2 is in S1 or is E -- have lengths
   --  differing by one. This bridges the Reachability _Set lemmas, which
   --  relate two reachable sets only by membership (not cardinality), to the
   --  node-count conjunct of Active_List_Valid after an interior/tail unlink.

   procedure Lemma_Free_List_Preserved
     (X : Count_Type'Base; M1, M2 : Nodes_Type_Base)
   with
     Ghost => Static,
     Pre   =>
       X < 0
       or else
         (X in M1'Range | 0
          and then Valid_Memory (M1)
          and then Valid_Memory (M2)
          and then Is_Acyclic (X, M1)
          and then
            (for all I of Reachable_Set (X, M1) =>
               I <= M2'Last and then M1 (I).Next = M2 (I).Next)),
     Post  =>
       X < 0
       or else
         (Is_Acyclic (X, M2)
          and then
            Memory_Index_Sets."="
              (Reachable_Set (X, M1), Reachable_Set (X, M2))
          and then
            Memory_Index_Sets.Length (Reachable_Set (X, M1))
            = Memory_Index_Sets.Length (Reachable_Set (X, M2)));
   --  If X is non-negative, call preservation lemmas from the reachability
   --  library to prove that the list starting at X is preserved. This is used
   --  for the free list, which might be negative.

   procedure Unlink_First_Node (Container : in out List)
   with
     Inline,
     Pre  =>
       (Static =>
          Structural_Invariant (Container) and then Container.Length >= 2),
     Post =>
       (Static =>
          Limbo_State (Container, Container.First'Old, Container.Length - 1)
          and then Container.Length = Container.Length'Old
          and then Container.Last = Container.Last'Old
          and then Container.First'Old in Memory (Container)'Range
          and then
            Is_Add
              (Active_Set (Container),
               Active_Set (Container'Old),
               Container.First'Old));
   --  Unlink the active head (old First) from the active list, leaving it off
   --  both lists in the limbo state with Length unchanged. Length >= 2 so a
   --  non-empty list remains. Does not touch the free store or Length: the
   --  caller returns the old head to the free store (Clear/Delete_First/Move)
   --  and does the single Length write. Shared by those and Splice.

   procedure Unlink_Interior_Node (Container : in out List; X : Count_Type)
   with
     Inline,
     Pre  =>
       (Static =>
          Structural_Invariant (Container)
          and then X in 1 .. Container.Capacity
          and then Memory_Index_Sets.Contains (Active_Set (Container), X)
          and then X /= Container.First
          and then X /= Container.Last),
     Post =>
       (Static =>
          Limbo_State (Container, X, Container.Length - 1)
          and then Container.Length = Container.Length'Old
          and then Container.First = Container.First'Old
          and then Container.Last = Container.Last'Old
          and then X in Memory (Container)'Range
          and then
            Is_Add (Active_Set (Container), Active_Set (Container'Old), X));
   --  Unlink the interior node X (neither First nor Last) from the active
   --  list, leaving it off both lists in the limbo state (element still set,
   --  links possibly stale) with Length unchanged. Does not touch the free
   --  store or Length: the caller returns X to the free store (Delete, via
   --  Free) or relinks it elsewhere (Splice, via Insert_*_Node), and does the
   --  single Length write. Shared by Delete and Splice.

   procedure Unlink_Last_Node (Container : in out List)
   with
     Inline,
     Pre  =>
       (Static =>
          Structural_Invariant (Container) and then Container.Length >= 2),
     Post =>
       (Static =>
          Limbo_State (Container, Container.Last'Old, Container.Length - 1)
          and then Container.Length = Container.Length'Old
          and then Container.First = Container.First'Old
          and then Container.Last'Old in Memory (Container)'Range
          and then
            Is_Add
              (Active_Set (Container),
               Active_Set (Container'Old),
               Container.Last'Old));
   --  Unlink the active tail (old Last) from the active list, leaving it off
   --  both lists in the limbo state with Length unchanged. Length >= 2 so a
   --  non-empty list remains. Does not touch the free store or Length: the
   --  caller returns the old tail to the free store (Delete/Delete_Last) and
   --  does the single Length write. Shared by those and Splice.

   procedure Unlink_Sole_Node (Container : in out List)
   with
     Inline,
     Pre  =>
       (Static =>
          Structural_Invariant (Container) and then Container.Length = 1),
     Post =>
       (Static =>
          Limbo_State (Container, Container.First'Old, 0)
          and then Container.Length = Container.Length'Old
          and then Container.First = 0
          and then Container.Last = 0
          and then Container.First'Old in Memory (Container)'Range);
   --  Unlink the sole active node (Length = 1), leaving it off both lists in
   --  the limbo state (Count = 0, active list empty) with Length unchanged.
   --  Does not touch the free store or Length: the caller returns the node to
   --  the free store and does the single Length write. Shared by Clear, Move,
   --  and the whole-list Splice (variant 1); the intra-list Splice never
   --  unlinks a sole node (that move is a no-op).

   ---------
   -- "=" --
   ---------

   function "=" (Left : List; Right : List) return Boolean is
      Same : constant Boolean := Same_Object (Left, Right);
      --  Volatile read in a non-interfering context (object initialization)

      LI : Count_Type;
      RI : Count_Type;

   begin
      if Same then
         return True;
      end if;

      if Left.Length /= Right.Length then
         return False;
      end if;

      LI := Left.First;
      RI := Right.First;

      while LI /= 0 loop
         pragma
           Assert
             (Static =>
                (if LI /= 0
                 then
                   not Memory_Index_Sets.Is_Empty
                         (Reachable_Set (RI, Memory (Right)))));

         --  LI and RI walk the two active lists in lockstep. Their remaining
         --  reachable sets have equal length (the lists have equal Length and
         --  each step drops one node), so LI and RI reach 0 together and RI is
         --  a valid index whenever LI is.

         pragma Warnings (Off, "condition is always True");
         pragma Loop_Invariant (Static => LI /= 0 and RI /= 0);
         pragma
           Loop_Invariant
             (Static => Reachable (Left.First, Memory (Left), LI));
         pragma
           Loop_Invariant
             (Static => Reachable (Right.First, Memory (Right), RI));
         pragma
           Loop_Invariant
             (Static =>
                Memory_Index_Sets.Length (Reachable_Set (LI, Memory (Left)))
                = Memory_Index_Sets.Length
                    (Reachable_Set (RI, Memory (Right))));
         pragma
           Loop_Variant
             (Static =>
                (Decreases =>
                   Memory_Index_Sets.Length
                     (Reachable_Set (LI, Memory (Left)))));
         pragma Warnings (On, "condition is always True");

         --  Both heads are reachable from an acyclic list head, so they head
         --  acyclic lists; unfolding Reachable_Set at each gives the length
         --  drop that advances the variant and preserves the equal-length
         --  invariant.

         Lemma_Reachable_Is_Acyclic (Left.First, LI, Memory (Left));
         Lemma_Reachable_Is_Acyclic (Right.First, RI, Memory (Right));
         Lemma_Reachable_Included (Left.First, LI, Memory (Left));
         Lemma_Reachable_Included (Right.First, RI, Memory (Right));
         Lemma_Reachable_Def (LI, Memory (Left));
         Lemma_Reachable_Def (RI, Memory (Right));

         if Left.Nodes (LI).Element /= Right.Nodes (RI).Element then
            return False;
         end if;

         LI := Left.Nodes (LI).Next;
         RI := Right.Nodes (RI).Next;
      end loop;

      return True;
   end "=";

   --------------
   -- Allocate --
   --------------

   procedure Allocate
     (Container : in out List;
      New_Item  : Element_Type;
      New_Node  : out Count_Type)
   is
      N     : Node_Array renames Container.Nodes;
      M_Old : constant Nodes_Type_Base := Memory (Container)
      with Ghost => Static;

   begin
      --  Automatic instantiation of the recursive definitions of
      --  Reachable_Set and Is_Acyclic is disabled on the Reachability
      --  instance; disclose them for the scope of Allocate so the prover can
      --  unfold the free chain from its head (New_Node) to its successor (the
      --  new Free).

      Disclose_Reachable;
      Disclose_Is_Acyclic;

      if Container.Free >= 0 then
         New_Node := Container.Free;

         --  New_Node is the head of the free chain, hence a free node: it is
         --  deallocated (Prev = -1) and disjoint from the active list.

         N (New_Node).Element := New_Item;
         Container.Free := N (New_Node).Next;

      else
         New_Node := abs Container.Free;
         N (New_Node).Element := New_Item;

         --  Initialize the bookkeeping links of the freshly exposed node
         --  before it becomes "touched" (which only happens once Free is
         --  decremented below). The structural predicate requires every
         --  touched node to have its Prev/Next initialized; Insert_Internal
         --  overwrites both immediately after, so these values are transient.

         N (New_Node).Prev := -1;
         N (New_Node).Next := 0;
         Container.Free := Container.Free - 1;
      end if;

      --  Allocate leaves every Next link unchanged, so all reachable sets and
      --  acyclicity are preserved between M_Old and the new memory.

      Lemma_Reachable_Preserved (Container.First, M_Old, Memory (Container));
      Lemma_Is_Acyclic_Preserved (Container.First, M_Old, Memory (Container));

      --  Container.Free is now the tail of the (shrunk) free chain in the
      --  positive branch and negative in the negative branch, so branching on
      --  it recovers the new free chain's head without a ghost condition.

      Lemma_Free_List_Preserved (Container.Free, M_Old, Memory (Container));

      pragma
        Assert (Static => Active_List_Valid (Container, Container.Length));
   end Allocate;

   ------------
   -- Append --
   ------------

   procedure Append (Container : in out List; New_Item : Element_Type) is
   begin
      Insert (Container, No_Element, New_Item, 1);
   end Append;

   procedure Append
     (Container : in out List; New_Item : Element_Type; Count : Count_Type) is
   begin
      Insert (Container, No_Element, New_Item, Count);
   end Append;

   ------------
   -- Assign --
   ------------

   procedure Assign (Target : in out List; Source : List) is
      Same : constant Boolean := Same_Object (Target, Source);

      N : Node_Array renames Source.Nodes;
      J : Count_Type;

   begin
      if Same then
         return;
      end if;

      if Target.Capacity < Source.Length then
         raise Capacity_Error with "Source length exceeds Target capacity";
      end if;

      Clear (Target);

      J := Source.First;
      while J /= 0 loop
         pragma Loop_Invariant (Static => Structural_Invariant (Target));
         pragma
           Loop_Invariant
             (Static => Memory_Index_Sets.Contains (Active_Set (Source), J));
         pragma
           Loop_Invariant
             (Static =>
                Big_Conversions.To_Big (Target.Length)
                + Memory_Index_Sets.Length (Reachable_Set (J, Memory (Source)))
                = Big_Conversions.To_Big (Source.Length));
         pragma
           Loop_Variant
             (Static =>
                (Decreases =>
                   Memory_Index_Sets.Length
                     (Reachable_Set (J, Memory (Source)))));

         Lemma_Reachable_Is_Acyclic (Source.First, J, Memory (Source));
         Lemma_Reachable_Included (Source.First, J, Memory (Source));

         --  Advancing J to its successor drops it from the reachable set, so
         --  the count decreases by one (matching the node Append adds).

         Lemma_Reachable_Def (J, Memory (Source));
         Lemma_Is_Acyclic_Def (J, Memory (Source));

         Append (Target, N (J).Element, 1);
         J := N (J).Next;
      end loop;
   end Assign;

   -----------
   -- Clear --
   -----------

   procedure Clear (Container : in out List) is
      X : Count_Type;

   begin
      if Container.Length = 0 then
         return;
      end if;

      while Container.Length > 1 loop
         pragma Loop_Invariant (Static => Structural_Invariant (Container));
         pragma Loop_Variant (Static => (Decreases => Container.Length));

         X := Container.First;
         Unlink_First_Node (Container);
         Container.Length := Container.Length - 1;
         Free (Container, X);
      end loop;

      --  Exactly one active node is left; drop it

      X := Container.First;
      Unlink_Sole_Node (Container);
      Container.Length := 0;
      Free (Container, X);
   end Clear;

   ------------------------
   -- Constant_Reference --
   ------------------------

   function Constant_Reference
     (Container : aliased List; Position : Cursor)
      return not null access constant Element_Type is
   begin
      if Position = No_Element then
         raise Constraint_Error with "Position cursor is No_Element";
      elsif not Has_Element (Container, Position) then
         raise Program_Error with "Position cursor has no element";
      end if;

      return Container.Nodes (Position.Node).Element'Access;
   end Constant_Reference;

   --------------
   -- Contains --
   --------------

   function Contains (Container : List; Item : Element_Type) return Boolean is
      Position : Cursor;
   begin
      Position := Find (Container, Item);
      return Position /= No_Element;
   end Contains;

   ----------
   -- Copy --
   ----------

   function Copy (Source : List; Capacity : Count_Type := 0) return List is

      procedure Rebuild_Free_List (L : List; Base, Cont : Count_Type)
      with
        Ghost => Static,
        Pre   =>
          Valid_Memory (Memory (L))
          and then L.Free = Base
          and then Base in 1 .. L.Capacity
          and then Cont in 0 .. Base - 1
          and then Is_Acyclic (Cont, Memory (L))
          and then
            (for all J in Base .. L.Capacity - 1 => L.Nodes (J).Next = J + 1)
          and then L.Nodes (L.Capacity).Next = Cont
          and then (for all J in Base .. L.Capacity => L.Nodes (J).Prev = -1)
          and then
            (for all I of Reachable_Set (Cont, Memory (L)) => I <= Base - 1)
          and then
            (for all I of Reachable_Set (Cont, Memory (L)) =>
               L.Nodes (I).Prev = -1),
        Post  =>
          Is_Acyclic (Base, Memory (L))
          and then
            (for all I of Reachable_Set (Base, Memory (L)) =>
               I in Base .. L.Capacity
               or else
                 Memory_Index_Sets.Contains
                   (Reachable_Set (Cont, Memory (L)), I))
          and then
            (for all I of Reachable_Set (Base, Memory (L)) =>
               L.Nodes (I).Prev = -1)
          and then
            (for all I in Base .. L.Capacity =>
               Memory_Index_Sets.Contains
                 (Reachable_Set (Base, Memory (L)), I))
          and then
            (for all I of Reachable_Set (Cont, Memory (L)) =>
               Memory_Index_Sets.Contains
                 (Reachable_Set (Base, Memory (L)), I))
          and then
            Memory_Index_Sets.Length (Reachable_Set (Base, Memory (L)))
            = Big_Conversions.To_Big (L.Capacity - Base + 1)
              + Memory_Index_Sets.Length (Reachable_Set (Cont, Memory (L)));
      --  The tail Base -> Base + 1 -> ... -> Capacity chains into Source's
      --  free head Cont (< Base). The merged free list from Base is then
      --  acyclic, its reachable set is Base .. Capacity plus Cont's chain,
      --  every node deallocated, with (Capacity - Base + 1) + |Cont chain|
      --  nodes. Walk the tail from Capacity down to establish these by
      --  induction. Carried as a local lemma so the induction's loop
      --  invariants do not enlarge Copy's own postcondition checks.

      -----------------------
      -- Rebuild_Free_List --
      -----------------------

      procedure Rebuild_Free_List (L : List; Base, Cont : Count_Type) is
         M : constant Nodes_Type_Base := Memory (L)
         with Ghost => Static;
      begin
         for J in reverse Base .. L.Capacity loop
            Lemma_Is_Acyclic_Def (J, M);
            Lemma_Reachable_Def (J, M);

            pragma Loop_Invariant (Static => Is_Acyclic (J, M));
            pragma
              Loop_Invariant
                (Static =>
                   (for all I of Reachable_Set (J, M) =>
                      I in J .. L.Capacity
                      or else
                        Memory_Index_Sets.Contains
                          (Reachable_Set (Cont, M), I)));
            pragma
              Loop_Invariant
                (Static =>
                   (for all I of Reachable_Set (J, M) =>
                      L.Nodes (I).Prev = -1));
            pragma
              Loop_Invariant
                (Static =>
                   (for all I in J .. L.Capacity =>
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
                   = Big_Conversions.To_Big (L.Capacity - J + 1)
                     + Memory_Index_Sets.Length (Reachable_Set (Cont, M)));
         end loop;
      end Rebuild_Free_List;

      C : constant Count_Type := Count_Type'Max (Source.Capacity, Capacity);
      P : List (C);

   begin
      if Capacity < Source.Length and then Capacity /= 0 then
         raise Capacity_Error
           with "Requested capacity is less than Source length";
      end if;

      --  Copy the touched region as a single slice assignment (not field by
      --  field): it copies the whole node records, so Source's untouched tail
      --  with its uninitialized fields is carried over without a read of an
      --  uninitialized scalar.

      P.Nodes (1 .. Source.Capacity) := Source.Nodes (1 .. Source.Capacity);

      P.Length := Source.Length;
      P.First := Source.First;
      P.Last := Source.Last;

      if Source.Free < 0 or else C = Source.Capacity then

         --  No extra capacity is touched, so P mirrors Source's free
         --  encoding directly.

         P.Free := Source.Free;

         --  Source's free chain (when explicit) is copied verbatim -- same
         --  links on its reachable nodes, all within Source.Capacity <= C --
         --  so it is preserved from Source into P.

         Lemma_Free_List_Preserved (Source.Free, Memory (Source), Memory (P));

      else

         --  Source.Free >= 0 and C > Source.Capacity: the extra cells
         --  Source.Capacity + 1 .. C must join the free list. Thread them into
         --  a chain ending at Source's free head, mark them deallocated
         --  (Prev = -1), and publish P.Free (= the tail head) only once every
         --  exposed cell is initialized.

         for N in Source.Capacity + 1 .. C loop
            P.Nodes (N).Prev := -1;
            P.Nodes (N).Next := (if N = C then Source.Free else N + 1);

            pragma Loop_Invariant (Static => P.Free = P.Free'Loop_Entry);
            pragma
              Loop_Invariant
                (Static =>
                   (for all K in Source.Capacity + 1 .. N =>
                      P.Nodes (K).Prev'Initialized
                      and then P.Nodes (K).Next'Initialized
                      and then P.Nodes (K).Prev = -1
                      and then
                        P.Nodes (K).Next
                        = (if K = C then Source.Free else K + 1)));
         end loop;

         P.Free := Source.Capacity + 1;

         --  The extra cells Source.Capacity + 1 .. C were threaded into a
         --  chain ending at Source's free head; rebuild the merged free list
         --  from its head P.Free (= Source.Capacity + 1) via the local lemma.
         --  Source's free nodes lie in 1 .. Source.Capacity (copied verbatim,
         --  so their links and Prev = -1 carry over), which is what the lemma
         --  needs of the continuation chain. This is proof-only code, kept
         --  inside this (already-taken) branch -- whose guard is exactly the
         --  merge condition -- so no separate run-time test is evaluated.

         Lemma_Free_List_Preserved (Source.Free, Memory (Source), Memory (P));
         Rebuild_Free_List (P, Source.Capacity + 1, Source.Free);
      end if;

      --  The active list is copied verbatim -- same links on its reachable
      --  nodes, all within Source.Capacity <= C -- so it is preserved from
      --  Source into the larger P.

      Lemma_Is_Acyclic_Preserved (Source.First, Memory (Source), Memory (P));
      Lemma_Reachable_Preserved (Source.First, Memory (Source), Memory (P));

      pragma Assert (Static => Active_List_Valid (P, P.Length));

      return P;
   end Copy;

   ------------
   -- Delete --
   ------------

   procedure Delete (Container : in out List; Position : in out Cursor) is
      X : constant Count_Type := Position.Node;

      Old_Active : constant Memory_Index_Set := Active_Set (Container)
      with Ghost => Static;
      --  The active list on entry, so that the per-branch reasoning below can
      --  be stated without 'Old (not available in the body).

   begin
      if not Has_Element (Container => Container, Position => Position) then
         raise Constraint_Error with "Position cursor has no element";
      end if;

      Position := No_Element;

      --  Unlink X from the active list and return it to the free store. The
      --  Unlink_* primitives export the active-set change (Is_Add), which is
      --  what the Post passes on to the callers.

      if Container.Length = 1 then

         --  The sole node is the whole active list, so disclosing
         --  Reachable_Set (First) = {First} gives the active-set change.

         Lemma_Reachable_Def (Container.First, Memory (Container));
         Unlink_Sole_Node (Container);

         pragma
           Assert (Static => Is_Add (Active_Set (Container), Old_Active, X));

      elsif X = Container.First then
         Unlink_First_Node (Container);

      elsif X = Container.Last then
         Unlink_Last_Node (Container);

      else
         Unlink_Interior_Node (Container, X);
      end if;

      Container.Length := Container.Length - 1;
      Free (Container, X);
   end Delete;

   procedure Delete
     (Container : in out List; Position : in out Cursor; Count : Count_Type)
   is
      N : Node_Array renames Container.Nodes;
      X : Count_Type;

   begin
      if not Has_Element (Container => Container, Position => Position) then
         raise Constraint_Error with "Position cursor has no element";
      end if;

      if Position.Node = Container.First then
         Delete_First (Container, Count);
         Position := No_Element;
         return;
      end if;

      if Count = 0 then
         Position := No_Element;
         return;
      end if;

      for Index in 1 .. Count loop
         pragma Loop_Invariant (Static => Structural_Invariant (Container));
         pragma Loop_Invariant (Static => Has_Element (Container, Position));
         pragma Loop_Invariant (Static => Position.Node /= Container.First);

         X := Position.Node;

         if X = Container.Last then
            Position := No_Element;

            --  First /= Last (Position is Last but not First), so at least two
            --  nodes remain and Unlink_Last_Node's Length >= 2 precondition
            --  holds.

            Lemma_Reachable_Def (Container.First, Memory (Container));

            Unlink_Last_Node (Container);
            Container.Length := Container.Length - 1;
            Free (Container, X);
            return;
         end if;

         --  Advance past the interior node X: Q = Next (X) is active (X is
         --  interior, so Next (X) /= 0) and, by acyclicity, distinct from X
         --  and First. Read Q before unlinking X; Unlink_Interior_Node and
         --  Free both keep the active set (minus X) and First, so Q stays a
         --  valid, non-First cursor across the two calls.

         Lemma_Reachable_Closed_By_Next (Container.First, Memory (Container));
         Position.Node := N (X).Next;

         Lemma_Reachable_Is_Acyclic (Container.First, X, Memory (Container));
         Lemma_Reachable_Included (Container.First, X, Memory (Container));
         Lemma_Reachable_Def (X, Memory (Container));

         pragma
           Assert
             (Static =>
                Memory_Index_Sets.Contains
                  (Active_Set (Container), Position.Node));
         pragma Assert (Static => Position.Node /= X);

         Unlink_Interior_Node (Container, X);
         Container.Length := Container.Length - 1;
         Free (Container, X);
      end loop;

      Position := No_Element;
   end Delete;

   ------------------
   -- Delete_First --
   ------------------

   procedure Delete_First (Container : in out List) is
   begin
      Delete_First (Container => Container, Count => 1);
   end Delete_First;

   procedure Delete_First (Container : in out List; Count : Count_Type) is
      X : Count_Type;

   begin
      if Count >= Container.Length then
         Clear (Container);
         return;
      end if;

      if Count = 0 then
         return;
      end if;

      --  Here 0 < Count < Length, so at least one node survives every
      --  iteration (Length stays >= 2 at each head removal).

      for J in 1 .. Count loop
         pragma Loop_Invariant (Static => Structural_Invariant (Container));
         pragma Loop_Invariant (Static => Container.Length >= Count - J + 2);

         X := Container.First;
         Unlink_First_Node (Container);
         Container.Length := Container.Length - 1;
         Free (Container, X);
      end loop;
   end Delete_First;

   -----------------
   -- Delete_Last --
   -----------------

   procedure Delete_Last (Container : in out List) is
   begin
      Delete_Last (Container => Container, Count => 1);
   end Delete_Last;

   procedure Delete_Last (Container : in out List; Count : Count_Type) is
      X : Count_Type;
   begin
      if Count >= Container.Length then
         Clear (Container);
         return;
      end if;

      if Count = 0 then
         return;
      end if;

      --  Here 0 < Count < Length, so at least one node survives every
      --  iteration (Length stays >= 2 at each tail removal).

      for J in 1 .. Count loop
         pragma Loop_Invariant (Static => Structural_Invariant (Container));
         pragma Loop_Invariant (Static => Container.Length >= Count - J + 2);

         X := Container.Last;
         Unlink_Last_Node (Container);
         Container.Length := Container.Length - 1;
         Free (Container, X);
      end loop;
   end Delete_Last;

   -------------
   -- Element --
   -------------

   function Element (Container : List; Position : Cursor) return Element_Type
   is
   begin
      if not Has_Element (Container => Container, Position => Position) then
         raise Constraint_Error with "Position cursor has no element";
      end if;

      return Container.Nodes (Position.Node).Element;
   end Element;

   ----------------
   -- Empty_List --
   ----------------

   function Empty_List (Capacity : Count_Type := 10) return List
   is (Capacity => Capacity,
       Free     => -1,
       Length   => 0,
       First    => 0,
       Last     => 0,
       Nodes    => (1 .. Capacity => <>));

   ----------
   -- Find --
   ----------

   function Find
     (Container : List; Item : Element_Type; Position : Cursor := No_Element)
      return Cursor
   is
      From : Count_Type := Position.Node;

   begin
      if From = 0 then
         From := Container.First;
      elsif not Has_Element (Container, Position) then
         raise Program_Error with "bad cursor in Find";
      end if;

      --  The active list is closed under Next, so once From is reachable from
      --  First its successor is reachable (or 0).

      Lemma_Reachable_Closed_By_Next (Container.First, Memory (Container));

      while From /= 0 loop
         pragma
           Loop_Invariant
             (Static => Reachable (Container.First, Memory (Container), From));
         pragma
           Loop_Variant
             (Static =>
                (Decreases =>
                   Memory_Index_Sets.Length
                     (Reachable_Set (From, Memory (Container)))));

         Lemma_Reachable_Is_Acyclic
           (Container.First, From, Memory (Container));
         Lemma_Reachable_Def (From, Memory (Container));

         if Container.Nodes (From).Element = Item then
            return (Node => From);
         end if;

         From := Container.Nodes (From).Next;
      end loop;

      return No_Element;
   end Find;

   -----------
   -- First --
   -----------

   function First (Container : List) return Cursor
   is (if Container.First = 0 then No_Element else (Node => Container.First));

   -------------------
   -- First_Element --
   -------------------

   function First_Element (Container : List) return Element_Type is
      F : constant Count_Type := Container.First;

   begin
      if F = 0 then
         raise Constraint_Error with "list is empty";
      else
         return Container.Nodes (F).Element;
      end if;
   end First_Element;

   ----------
   -- Free --
   ----------

   procedure Free (Container : in out List; X : Count_Type) is

      procedure Rebuild_Free_List (C : List; Head, Base : Count_Type)
      with
        Ghost => Static,
        Pre   =>
          C.Free >= 0
          and then Valid_Memory (Memory (C))
          and then Head in 1 .. C.Capacity
          and then Base in 1 .. C.Capacity
          and then Head < Base
          and then C.Nodes (Head).Next = Base
          and then C.Nodes (Head).Prev = -1
          and then
            (for all J in Base .. C.Capacity - 1 => C.Nodes (J).Next = J + 1)
          and then C.Nodes (C.Capacity).Next = 0
          and then (for all J in Base .. C.Capacity => C.Nodes (J).Prev = -1),
        Post  =>
          Is_Acyclic (Head, Memory (C))
          and then
            Memory_Index_Sets.Contains (Reachable_Set (Head, Memory (C)), Head)
          and then
            (for all I of Reachable_Set (Head, Memory (C)) =>
               I = Head or else I in Base .. C.Capacity)
          and then
            (for all I of Reachable_Set (Head, Memory (C)) =>
               C.Nodes (I).Prev = -1)
          and then
            (for all I in Base .. C.Capacity =>
               Memory_Index_Sets.Contains
                 (Reachable_Set (Head, Memory (C)), I))
          and then
            Memory_Index_Sets.Length (Reachable_Set (Head, Memory (C)))
            = Big_Conversions.To_Big (C.Capacity - Base + 2);
      --  The rebuilt free list runs Head -> Base -> Base + 1 -> ... ->
      --  Capacity -> 0, every node pointing to a strictly larger index. Walk
      --  it from the tail (Capacity) down to establish acyclicity, the
      --  reachable set {Head} + Base .. Capacity, and its cardinality, by
      --  induction.

      -----------------------
      -- Rebuild_Free_List --
      -----------------------

      procedure Rebuild_Free_List (C : List; Head, Base : Count_Type) is
         M : constant Nodes_Type_Base := Memory (C)
         with Ghost => Static;
      begin
         for J in reverse Base .. C.Capacity loop
            Lemma_Is_Acyclic_Def (J, M);
            Lemma_Reachable_Def (J, M);

            pragma Loop_Invariant (Static => Is_Acyclic (J, M));
            pragma
              Loop_Invariant
                (Static =>
                   (for all I of Reachable_Set (J, M) =>
                      I in J .. C.Capacity));
            pragma
              Loop_Invariant
                (Static =>
                   (for all I in J .. C.Capacity =>
                      Memory_Index_Sets.Contains (Reachable_Set (J, M), I)));
            pragma
              Loop_Invariant
                (Static =>
                   Memory_Index_Sets.Length (Reachable_Set (J, M))
                   = Big_Conversions.To_Big (C.Capacity - J + 1));
         end loop;

         --  Head < Base, so Head is not already on the tail chain; prepending
         --  it keeps the chain acyclic and adds exactly one node.

         Lemma_Is_Acyclic_Def (Head, M);
         Lemma_Reachable_Def (Head, M);
      end Rebuild_Free_List;

      N     : Node_Array renames Container.Nodes;
      M_Old : constant Nodes_Type_Base := Memory (Container)
      with Ghost => Static;

   begin
      N (X).Prev := -1;  -- Node is deallocated (not on active list)

      if Container.Free >= 0 then
         N (X).Next := Container.Free;

         Lemma_Reachable_Preserved
           (Container.First, M_Old, Memory (Container));
         Lemma_Is_Acyclic_Preserved
           (Container.First, M_Old, Memory (Container));
         pragma
           Assert (Static => Active_List_Valid (Container, Container.Length));

         --  Writing N (X) leaves the old free chain untouched, so it is
         --  preserved; push X onto its head to obtain the new free chain.

         Lemma_Reachable_Preserved (Container.Free, M_Old, Memory (Container));
         Lemma_Is_Acyclic_Preserved
           (Container.Free, M_Old, Memory (Container));
         Lemma_Is_Acyclic_Def (X, Memory (Container));
         Lemma_Reachable_Def (X, Memory (Container));

         Container.Free := X;

         pragma
           Assert
             (Static => Structural_Invariant (Container, Container.Length));

      elsif Container.Free = -X - 1 then
         Lemma_Reachable_Closed_By_Next (Container.First, M_Old);

         N (X).Next := 0;

         Container.Free := Container.Free + 1;

         Lemma_Reachable_Preserved
           (Container.First, M_Old, Memory (Container));
         Lemma_Is_Acyclic_Preserved
           (Container.First, M_Old, Memory (Container));
         pragma
           Assert (Static => Active_List_Valid (Container, Container.Length));

         --  Free stays negative, so the free chain is still the implicit tail
         --  and Free_Chain_Valid holds trivially.

         pragma
           Assert
             (Static => Structural_Invariant (Container, Container.Length));

      elsif Container.Free = -Container.Capacity - 1 then

         --  The never-used region is empty (every cell has been handed out via
         --  the negative-Free encoding), so the rebuilt free list is just X.

         N (X).Next := 0;
         Container.Free := X;

         Lemma_Reachable_Preserved
           (Container.First, M_Old, Memory (Container));
         Lemma_Is_Acyclic_Preserved
           (Container.First, M_Old, Memory (Container));
         pragma
           Assert (Static => Active_List_Valid (Container, Container.Length));

         Lemma_Is_Acyclic_Def (X, Memory (Container));
         Lemma_Reachable_Def (X, Memory (Container));
         pragma
           Assert
             (Static => Structural_Invariant (Container, Container.Length));

      else
         declare
            Base : constant Count_Type := -Container.Free;
         begin
            for J in Base .. Container.Capacity - 1 loop
               N (J).Next := J + 1;
               N (J).Prev := -1;

               pragma
                 Loop_Invariant
                   (Static => Container.Free = Container.Free'Loop_Entry);
               pragma
                 Loop_Invariant
                   (Static =>
                      (for all K in Base .. J =>
                         N (K).Prev'Initialized
                         and then N (K).Next'Initialized
                         and then N (K).Prev = -1
                         and then N (K).Next = K + 1));
            end loop;

            N (Container.Capacity).Next := 0;
            N (Container.Capacity).Prev := -1;

            Container.Free := X;
            N (X).Next := Base;

            pragma
              Assert
                (Static =>
                   (for all I of Reachable_Set (Container.First, M_Old) =>
                      I <= Memory (Container)'Last
                      and then
                        Next_Link (M_Old (I))
                        = Next_Link (Memory (Container) (I))));

            Lemma_Reachable_Preserved
              (Container.First, M_Old, Memory (Container));
            Lemma_Is_Acyclic_Preserved
              (Container.First, M_Old, Memory (Container));
            pragma
              Assert
                (Static => Active_List_Valid (Container, Container.Length));

            --  Reconstruct the rebuilt free list, now headed at X (X -> Base
            --  -> ... -> Capacity -> 0), via the local lemma.

            Rebuild_Free_List (Container, X, Base);
            pragma
              Assert
                (Static => Structural_Invariant (Container, Container.Length));
         end;
      end if;
   end Free;

   ---------------------
   -- Generic_Sorting --
   ---------------------

   package body Generic_Sorting is

      ---------------
      -- Is_Sorted --
      ---------------

      function Is_Sorted (Container : List) return Boolean is
         Nodes : Node_Array renames Container.Nodes;
         Node  : Count_Type := Container.First;

      begin
         --  The active list is closed under Next, so once Node is reachable
         --  from First its successor is reachable (or 0).

         Lemma_Reachable_Closed_By_Next (Container.First, Memory (Container));

         for J in 2 .. Container.Length loop

            --  Node is the (J - 1)th node of the active list, so the list it
            --  heads still holds Length - J + 2 nodes. Two or more of them
            --  means Node has a successor, which is what makes the reads
            --  below in range.

            pragma
              Loop_Invariant
                (Static =>
                   Reachable (Container.First, Memory (Container), Node));
            pragma
              Loop_Invariant
                (Static =>
                   Memory_Index_Sets.Length
                     (Reachable_Set (Node, Memory (Container)))
                   = Big_Conversions.To_Big (Container.Length - J + 2));

            Lemma_Reachable_Is_Acyclic
              (Container.First, Node, Memory (Container));
            Lemma_Reachable_Def (Node, Memory (Container));

            if Nodes (Nodes (Node).Next).Element < Nodes (Node).Element then
               return False;
            else
               Node := Nodes (Node).Next;
            end if;
         end loop;

         return True;
      end Is_Sorted;

      -----------
      -- Merge --
      -----------

      procedure Merge (Target : in out List; Source : in out List) is
         Same : constant Boolean := Same_Object (Target, Source);

         LN : Node_Array renames Target.Nodes;
         RN : Node_Array renames Source.Nodes;
         LI : Cursor;
         RI : Cursor;

         Orig_Sum : Count_Type
         with Ghost => Static;
         --  The invariant sum Target.Length + Source.Length (captured once the
         --  guards rule out its overflow), which bounds Target below capacity.

      begin
         pragma Assume (Static => Same = Same_Object_Ghost);

         if Is_Empty (Source) then
            return;
         end if;

         if Same then
            raise Program_Error
              with "Target and Source denote same non-empty container";
            pragma
              Annotate
                (GNATprove,
                 Intentional,
                 "unexpected exception might be raised",
                 "unreachable in SPARK: two in out parameters cannot alias, "
                 & "so Same_Object never holds here");
         end if;

         if Target.Length > Count_Type'Last - Source.Length then
            raise Constraint_Error with "new length exceeds maximum";
         end if;

         if Target.Length + Source.Length > Target.Capacity then
            raise Capacity_Error with "new length exceeds target capacity";
         end if;

         Orig_Sum := Target.Length + Source.Length;

         LI := First (Target);
         RI := First (Source);

         --  Walk both lists in lockstep, moving Source's head into Target
         --  whenever it is the smaller of the two heads and advancing LI
         --  otherwise. The running sum Target.Length + Source.Length stays
         --  equal to Orig_Sum, so Target never overflows and each move keeps
         --  LI a valid cursor. Termination is lexicographic: a move shortens
         --  Source, and otherwise LI advances along an unchanged Target.

         while RI.Node /= 0 loop
            pragma Loop_Invariant (Static => Structural_Invariant (Target));
            pragma Loop_Invariant (Static => Structural_Invariant (Source));
            pragma Loop_Invariant (Static => Has_Element (Source, RI));
            pragma Loop_Invariant (Static => Is_Relevant (Target, LI));
            pragma
              Loop_Invariant
                (Static => Target.Length + Source.Length = Orig_Sum);
            pragma Loop_Invariant (Static => Orig_Sum <= Target.Capacity);
            pragma
              Loop_Variant
                (Static =>
                   (Decreases => Source.Length,
                    Decreases =>
                      Memory_Index_Sets.Length
                        (Reachable_Set (LI.Node, Memory (Target)))));

            if LI.Node = 0 then
               Splice (Target, No_Element, Source);
               return;
            end if;

            if RN (RI.Node).Element < LN (LI.Node).Element then
               declare
                  RJ : Cursor := RI;

               begin
                  --  RI moves to the successor of the node being moved, which
                  --  is active (the active list is closed under Next) and
                  --  distinct from it (acyclicity), so it survives the move:
                  --  Splice takes exactly RJ's node off Source. Splice resets
                  --  RJ, which is discarded: RI is the cursor Merge follows.

                  Lemma_Reachable_Closed_By_Next
                    (Source.First, Memory (Source));
                  Lemma_Reachable_Is_Acyclic
                    (Source.First, RI.Node, Memory (Source));
                  Lemma_Reachable_Def (RI.Node, Memory (Source));

                  RI.Node := RN (RJ.Node).Next;
                  Splice (Target, LI, Source, RJ);
               end;

            else
               --  LI moves to its successor, which is active or 0, and heads
               --  a shorter part of the unchanged Target.

               Lemma_Reachable_Closed_By_Next (Target.First, Memory (Target));
               Lemma_Reachable_Is_Acyclic
                 (Target.First, LI.Node, Memory (Target));
               Lemma_Reachable_Def (LI.Node, Memory (Target));

               LI.Node := LN (LI.Node).Next;
            end if;
         end loop;
      end Merge;

      ----------
      -- Sort --
      ----------

      procedure Sort (Container : in out List) is

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

         Old_Free : constant Count_Type'Base := Container.Free
         with Ghost => Static;
         --  The free-list head on entry. The sort never touches it, and that
         --  is threaded through the preconditions of the helpers as well as
         --  their postconditions: it is what keeps the bounds of the memory
         --  the model sees fixed for the whole sort, and 'Old only relates a
         --  call's own entry and exit, not the sort's entry.

         function Segment_Valid
           (M : Nodes_Type_Base; D : List_Descriptor) return Boolean
         is (Valid_Memory (M)
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
                  and then M (I).Element'Initialized
                  and then (if M (I).Next = 0 then I = D.Last)
                  and then
                    (if M (I).Prev = 0
                     then I = D.First
                     else
                       Reachable (D.First, M, M (I).Prev)
                       and then M (M (I).Prev).Next = I)))
         with Ghost => Static;
         --  D is a well-formed doubly linked segment of the memory M: an
         --  acyclic chain of D.Length allocated nodes running from D.First to
         --  D.Last, with the Prev links mirroring the Next links inside the
         --  segment.

         function Untouched_Outside
           (M1, M2 : Nodes_Type_Base; S : Memory_Index_Set) return Boolean
         is (M1'First = M2'First
             and then M1'Last = M2'Last
             and then (for all N of M1 => N.Prev'Initialized)
             and then (for all N of M2 => N.Prev'Initialized)
             and then
               (for all I in M1'Range =>
                  M1 (I).Element'Initialized = M2 (I).Element'Initialized)
             and then
               (for all I in M1'Range =>
                  (if not Memory_Index_Sets.Contains (S, I)
                   then
                     M1 (I).Prev = M2 (I).Prev
                     and then M1 (I).Next = M2 (I).Next)))
         with Ghost => Static;
         --  The frame of the sort helpers: they only ever relink the nodes of
         --  the segments they are given, and never touch an element

         Whole : List_Descriptor :=
           (First  => Container.First,
            Last   => Container.Last,
            Length => Container.Length);
         --  The whole list, as the segment handed to the sort

         M_Old : constant Nodes_Type_Base := Memory (Container)
         with Ghost => Static;

         ------------------------
         -- Local subprograms  --
         ------------------------

         procedure Detach_First
           (Source : in out List_Descriptor; Detached : out Count_Type)
         with
           Modifies => (Container.Nodes, Source, Detached),
           Pre      =>
             (Static =>
                Container.Free = Old_Free
                and then Segment_Valid (Memory (Container), Source)
                and then Source.Length >= 1),
           Post     =>
             (Static =>
                Segment_Valid (Memory (Container), Source)
                and then Detached = Source'Old.First
                and then Detached in Memory (Container)'Range
                and then Source.Length = Source'Old.Length - 1
                and then Memory (Container) (Detached).Prev = 0
                and then Memory (Container) (Detached).Next = 0
                and then Memory (Container) (Detached).Element'Initialized
                and then
                  Is_Add
                    (Reachable_Set (Source.First, Memory (Container)),
                     Reachable_Set (Source'Old.First, Memory (Container'Old)),
                     Detached)
                and then
                  Untouched_Outside
                    (Memory (Container'Old),
                     Memory (Container),
                     Reachable_Set
                       (Source'Old.First, Memory (Container'Old))));
         --  Take the first node off a non-empty segment. The detached node is
         --  left as an isolated singleton (both its links null), as the merge
         --  loop expects.

         procedure Append_Node
           (Target : in out List_Descriptor; New_Node : Count_Type)
         with
           Modifies => (Container.Nodes, Target),
           Pre      =>
             (Static =>
                Container.Free = Old_Free
                and then Segment_Valid (Memory (Container), Target)
                and then New_Node in Memory (Container)'Range
                and then Memory (Container) (New_Node).Prev = 0
                and then Memory (Container) (New_Node).Next = 0
                and then Memory (Container) (New_Node).Element'Initialized
                and then
                  not Reachable (Target.First, Memory (Container), New_Node)),
           Post     =>
             (Static =>
                Segment_Valid (Memory (Container), Target)
                and then Target.Length = Target'Old.Length + 1
                and then
                  Is_Add
                    (Reachable_Set (Target'Old.First, Memory (Container'Old)),
                     Reachable_Set (Target.First, Memory (Container)),
                     New_Node)
                and then
                  Untouched_Outside
                    (Memory (Container'Old),
                     Memory (Container),
                     Reachable_Set (Target.First, Memory (Container))));
         --  Append a detached node to a list segment

         procedure Merge_Parts
           (Part1, Part2 : List_Descriptor; Merged : out List_Descriptor)
         with
           Pre  =>
             (Static =>
                Container.Free = Old_Free
                and then Segment_Valid (Memory (Container), Part1)
                and then Segment_Valid (Memory (Container), Part2)
                and then
                  Memory_Index_Sets.No_Overlap
                    (Reachable_Set (Part1.First, Memory (Container)),
                     Reachable_Set (Part2.First, Memory (Container)))
                and then Part1.Length <= Count_Type'Last - Part2.Length),
           Post =>
             (Static =>
                Container.Free = Old_Free
                and then Segment_Valid (Memory (Container), Merged)
                and then Container.First = Container.First'Old
                and then Container.Last = Container.Last'Old
                and then Container.Length = Container.Length'Old
                and then Merged.Length = Part1.Length + Part2.Length
                and then
                  Memory_Index_Sets."="
                    (Reachable_Set (Merged.First, Memory (Container)),
                     Memory_Index_Sets.Union
                       (Reachable_Set (Part1.First, Memory (Container'Old)),
                        Reachable_Set (Part2.First, Memory (Container'Old))))
                and then
                  Untouched_Outside
                    (Memory (Container'Old),
                     Memory (Container),
                     Memory_Index_Sets.Union
                       (Reachable_Set (Part1.First, Memory (Container'Old)),
                        Reachable_Set (Part2.First, Memory (Container'Old)))));
         --  Merge two disjoint segments, preserving the sorted property. If
         --  the compared elements are equal the node of Part1 comes first, as
         --  stability requires.

         procedure Merge_Sort (Arg : in out List_Descriptor)
         with
           Subprogram_Variant => (Decreases => Arg.Length),
           Pre                =>
             (Static =>
                Container.Free = Old_Free
                and then Segment_Valid (Memory (Container), Arg)),
           Post               =>
             (Static =>
                Container.Free = Old_Free
                and then Segment_Valid (Memory (Container), Arg)
                and then Container.First = Container.First'Old
                and then Container.Last = Container.Last'Old
                and then Container.Length = Container.Length'Old
                and then Arg.Length = Arg'Old.Length
                and then
                  Memory_Index_Sets."="
                    (Reachable_Set (Arg.First, Memory (Container)),
                     Reachable_Set (Arg'Old.First, Memory (Container'Old)))
                and then
                  Untouched_Outside
                    (Memory (Container'Old),
                     Memory (Container),
                     Reachable_Set (Arg'Old.First, Memory (Container'Old))));
         --  Sort a segment in place using MergeSort. As required by the RM,
         --  the sort is stable.

         procedure Split_List
           (Unsplit : List_Descriptor; Part1, Part2 : out List_Descriptor)
         with
           Pre  =>
             (Static =>
                Container.Free = Old_Free
                and then Segment_Valid (Memory (Container), Unsplit)
                and then Unsplit.Length >= 2),
           Post =>
             (Static =>
                Container.Free = Old_Free
                and then Segment_Valid (Memory (Container), Part1)
                and then Segment_Valid (Memory (Container), Part2)
                and then Container.First = Container.First'Old
                and then Container.Last = Container.Last'Old
                and then Container.Length = Container.Length'Old
                and then Part1.Length >= 1
                and then Part2.Length >= 1
                and then Part1.Length + Part2.Length = Unsplit.Length
                and then
                  Memory_Index_Sets.No_Overlap
                    (Reachable_Set (Part1.First, Memory (Container)),
                     Reachable_Set (Part2.First, Memory (Container)))
                and then
                  Memory_Index_Sets."="
                    (Memory_Index_Sets.Union
                       (Reachable_Set (Part1.First, Memory (Container)),
                        Reachable_Set (Part2.First, Memory (Container))),
                     Reachable_Set (Unsplit.First, Memory (Container'Old)))
                and then
                  Untouched_Outside
                    (Memory (Container'Old),
                     Memory (Container),
                     Reachable_Set (Unsplit.First, Memory (Container'Old))));
         --  Split a segment of two nodes or more into two non-empty parts for
         --  divide-and-conquer

         -----------------
         -- Append_Node --
         -----------------

         procedure Append_Node
           (Target : in out List_Descriptor; New_Node : Count_Type)
         is
            M_Old : constant Nodes_Type_Base := Memory (Container)
            with Ghost => Static;
         begin
            --  The new node is an isolated singleton

            Lemma_Is_Acyclic_Def (New_Node, Memory (Container));
            Lemma_Reachable_Def (New_Node, Memory (Container));

            if Target.Length = 0 then
               Target := (First | Last => New_Node, Length => 1);

            else
               --  The tail of the merged list is its own last node, so
               --  appending the singleton headed by New_Node adds exactly one
               --  node.

               Lemma_Reachable_Is_Acyclic
                 (Target.First, Target.Last, Memory (Container));
               Lemma_Reachable_Def (Target.Last, Memory (Container));

               Container.Nodes (New_Node).Prev := Target.Last;
               Container.Nodes (Target.Last).Next := New_Node;

               --  Only the Next link of the old tail changed, so the three
               --  lists are reconstructed on the final memory in one step
               --  each: neither part goes through that node.

               Lemma_Reachable_After_Set
                 (Target.First,
                  Target.Last,
                  New_Node,
                  M_Old,
                  Memory (Container));
               Lemma_Is_Acyclic_After_Set
                 (Target.First,
                  Target.Last,
                  New_Node,
                  M_Old,
                  Memory (Container));

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
            M_Old : constant Nodes_Type_Base := Memory (Container)
            with Ghost => Static;
            S_Old : constant List_Descriptor := Source
            with Ghost => Static;
         begin
            Detached := Source.First;

            if Source.Length = 1 then

               --  The sole node of the segment is both its head and its tail,
               --  so it is already isolated.

               Lemma_Reachable_Def (Detached, Memory (Container));
               Source := No_Segment;

            else
               Source :=
                 (First  => Container.Nodes (Detached).Next,
                  Last   => Source.Last,
                  Length => Source.Length - 1);

               Lemma_Reachable_Def (Detached, Memory (Container));
               Lemma_Is_Acyclic_Def (Detached, Memory (Container));

               Container.Nodes (Source.First).Prev := 0;

               Lemma_Reachable_Preserved
                 (Source.First, M_Old, Memory (Container));
               Lemma_Is_Acyclic_Preserved
                 (Source.First, M_Old, Memory (Container));

               declare
                  M_Interm : constant Nodes_Type_Base := Memory (Container)
                  with Ghost => Static;
               begin
                  Container.Nodes (Detached).Next := 0;

                  Lemma_Reachable_Preserved
                    (Source.First, M_Interm, Memory (Container));
                  Lemma_Is_Acyclic_Preserved
                    (Source.First, M_Interm, Memory (Container));
               end;
            end if;

            pragma
              Assert
                (Static =>
                   Is_Add
                     (Reachable_Set (Source.First, Memory (Container)),
                      Reachable_Set (S_Old.First, M_Old),
                      Detached));
         end Detach_First;

         -----------------
         -- Merge_Parts --
         -----------------

         procedure Merge_Parts
           (Part1, Part2 : List_Descriptor; Merged : out List_Descriptor)
         is
            M_Old : constant Nodes_Type_Base := Memory (Container)
            with Ghost => Static;

            All_Cells : constant Memory_Index_Set :=
              Memory_Index_Sets.Union
                (Reachable_Set (Part1.First, Memory (Container)),
                 Reachable_Set (Part2.First, Memory (Container)))
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
               pragma
                 Loop_Invariant
                   (Static =>
                      Container.Free = Old_Free
                      and then Container.First = Container.First'Loop_Entry
                      and then Container.Last = Container.Last'Loop_Entry
                      and then Container.Length = Container.Length'Loop_Entry);
               pragma
                 Loop_Invariant
                   (Static => Segment_Valid (Memory (Container), P1));
               pragma
                 Loop_Invariant
                   (Static => Segment_Valid (Memory (Container), P2));
               pragma
                 Loop_Invariant
                   (Static => Segment_Valid (Memory (Container), Merged));
               pragma
                 Loop_Invariant
                   (Static =>
                      Memory_Index_Sets.No_Overlap
                        (Reachable_Set (P1.First, Memory (Container)),
                         Reachable_Set (P2.First, Memory (Container))));
               pragma
                 Loop_Invariant
                   (Static =>
                      Memory_Index_Sets.No_Overlap
                        (Reachable_Set (Merged.First, Memory (Container)),
                         Reachable_Set (P1.First, Memory (Container))));
               pragma
                 Loop_Invariant
                   (Static =>
                      Memory_Index_Sets.No_Overlap
                        (Reachable_Set (Merged.First, Memory (Container)),
                         Reachable_Set (P2.First, Memory (Container))));
               pragma
                 Loop_Invariant
                   (Static =>
                      Memory_Index_Sets."<="
                        (Reachable_Set (Merged.First, Memory (Container)),
                         All_Cells));
               pragma
                 Loop_Invariant
                   (Static =>
                      Memory_Index_Sets."<="
                        (Reachable_Set (P1.First, Memory (Container)),
                         All_Cells));
               pragma
                 Loop_Invariant
                   (Static =>
                      Memory_Index_Sets."<="
                        (Reachable_Set (P2.First, Memory (Container)),
                         All_Cells));
               pragma
                 Loop_Invariant
                   (Static =>
                      (for all I of All_Cells =>
                         Memory_Index_Sets.Contains
                           (Reachable_Set (Merged.First, Memory (Container)),
                            I)
                         or else
                           Memory_Index_Sets.Contains
                             (Reachable_Set (P1.First, Memory (Container)), I)
                         or else
                           Memory_Index_Sets.Contains
                             (Reachable_Set (P2.First, Memory (Container)),
                              I)));
               pragma
                 Loop_Invariant
                   (Static => Merged.Length + P1.Length + P2.Length = Total);
               pragma
                 Loop_Invariant
                   (Static =>
                      Untouched_Outside
                        (M_Old, Memory (Container), All_Cells));
               pragma
                 Loop_Variant (Static => (Decreases => P1.Length + P2.Length));

               M_Entry := Memory (Container);
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
                    Container.Nodes (P2.First).Element
                    < Container.Nodes (P1.First).Element;
               end if;

               --  The other part and the merged list lie outside the part the
               --  node is taken from, so the detach leaves them alone.

               if Take_From_P2 then
                  Detach_First (P2, Detached);

                  Lemma_Reachable_Preserved
                    (P1.First, M_Entry, Memory (Container));
                  Lemma_Is_Acyclic_Preserved
                    (P1.First, M_Entry, Memory (Container));
               else
                  Detach_First (P1, Detached);

                  Lemma_Reachable_Preserved
                    (P2.First, M_Entry, Memory (Container));
                  Lemma_Is_Acyclic_Preserved
                    (P2.First, M_Entry, Memory (Container));
               end if;

               Lemma_Reachable_Preserved
                 (Merged.First, M_Entry, Memory (Container));
               Lemma_Is_Acyclic_Preserved
                 (Merged.First, M_Entry, Memory (Container));

               declare
                  M_Det : constant Nodes_Type_Base := Memory (Container)
                  with Ghost => Static;

               begin
                  Append_Node (Merged, Detached);

                  Lemma_Reachable_Preserved
                    (P1.First, M_Det, Memory (Container));
                  Lemma_Is_Acyclic_Preserved
                    (P1.First, M_Det, Memory (Container));
                  Lemma_Reachable_Preserved
                    (P2.First, M_Det, Memory (Container));
                  Lemma_Is_Acyclic_Preserved
                    (P2.First, M_Det, Memory (Container));
               end;

               --  Every node the three lists held on entry is still on one of
               --  them: the merged list only grew, and each part lost at most
               --  the detached node, which the merged list took.

               Lemma_Still_Covered
                 (Reachable_Set (Merged_Entry.First, M_Entry),
                  Reachable_Set (P1_Entry.First, M_Entry),
                  Reachable_Set (P2_Entry.First, M_Entry),
                  Reachable_Set (Merged.First, Memory (Container)),
                  Reachable_Set (P1.First, Memory (Container)),
                  Reachable_Set (P2.First, Memory (Container)),
                  Detached);

               pragma
                 Assert
                   (Static =>
                      Untouched_Outside
                        (M_Entry, Memory (Container), All_Cells));
            end loop;

            --  Both parts are exhausted, so the merged list holds every node

            pragma
              Assert
                (Static =>
                   Memory_Index_Sets.Is_Empty
                     (Reachable_Set (P1.First, Memory (Container))));
            pragma
              Assert
                (Static =>
                   Memory_Index_Sets.Is_Empty
                     (Reachable_Set (P2.First, Memory (Container))));
            pragma
              Assert
                (Static =>
                   Memory_Index_Sets."="
                     (Reachable_Set (Merged.First, Memory (Container)),
                      All_Cells));
         end Merge_Parts;

         ----------------
         -- Merge_Sort --
         ----------------

         procedure Merge_Sort (Arg : in out List_Descriptor) is
            Part1, Part2 : List_Descriptor;

            Cells : constant Memory_Index_Set :=
              Reachable_Set (Arg.First, Memory (Container))
            with Ghost => Static;
            --  The nodes of the segment on entry. Each step below states that
            --  the two parts still cover exactly them: the final equality is
            --  a chain of five set equalities composed through Union, and it
            --  times out unless each link is established on its own.

         begin
            if Arg.Length < 2 then

               --  Already sorted

               return;
            end if;

            Split_List (Arg, Part1, Part2);

            pragma
              Assert
                (Static =>
                   Memory_Index_Sets."="
                     (Memory_Index_Sets.Union
                        (Reachable_Set (Part1.First, Memory (Container)),
                         Reachable_Set (Part2.First, Memory (Container))),
                      Cells));

            declare
               M_Split : constant Nodes_Type_Base := Memory (Container)
               with Ghost => Static;
            begin
               Merge_Sort (Part1);

               --  Part2 lies outside Part1, so sorting Part1 left it alone.
               --  Part2 being closed under Next is what places the successor
               --  of each of its nodes outside Part1 too.

               Lemma_Reachable_Preserved
                 (Part2.First, M_Split, Memory (Container));
               Lemma_Is_Acyclic_Preserved
                 (Part2.First, M_Split, Memory (Container));
               Lemma_Reachable_Closed_By_Next (Part2.First, M_Split);

               pragma
                 Assert
                   (Static =>
                      Memory_Index_Sets."="
                        (Memory_Index_Sets.Union
                           (Reachable_Set (Part1.First, Memory (Container)),
                            Reachable_Set (Part2.First, Memory (Container))),
                         Cells));
            end;

            declare
               M_Sorted1 : constant Nodes_Type_Base := Memory (Container)
               with Ghost => Static;
            begin
               Merge_Sort (Part2);

               Lemma_Reachable_Preserved
                 (Part1.First, M_Sorted1, Memory (Container));
               Lemma_Is_Acyclic_Preserved
                 (Part1.First, M_Sorted1, Memory (Container));
               Lemma_Reachable_Closed_By_Next (Part1.First, M_Sorted1);

               pragma
                 Assert
                   (Static =>
                      Memory_Index_Sets."="
                        (Memory_Index_Sets.Union
                           (Reachable_Set (Part1.First, Memory (Container)),
                            Reachable_Set (Part2.First, Memory (Container))),
                         Cells));
            end;

            Merge_Parts (Part1, Part2, Arg);
         end Merge_Sort;

         ----------------
         -- Split_List --
         ----------------

         procedure Split_List
           (Unsplit : List_Descriptor; Part1, Part2 : out List_Descriptor)
         is
            M_Old : constant Nodes_Type_Base := Memory (Container)
            with Ghost => Static;

            Rover      : Count_Type := Unsplit.First;
            Bump_Count : constant Count_Type := (Unsplit.Length - 1) / 2;

         begin
            for Iter in 1 .. Bump_Count loop
               pragma
                 Loop_Invariant (Static => Rover in Memory (Container)'Range);
               pragma
                 Loop_Invariant
                   (Static =>
                      Reachable (Unsplit.First, Memory (Container), Rover));
               pragma
                 Loop_Invariant
                   (Static =>
                      Memory_Index_Sets.Length
                        (Reachable_Set (Rover, Memory (Container)))
                      = Big_Conversions.To_Big (Unsplit.Length - Iter + 1));

               Lemma_Reachable_Is_Acyclic
                 (Unsplit.First, Rover, Memory (Container));
               Lemma_Reachable_Def (Rover, Memory (Container));
               Lemma_Reachable_Closed_By_Next
                 (Unsplit.First, Memory (Container));

               Rover := Container.Nodes (Rover).Next;
            end loop;

            Lemma_Reachable_Is_Acyclic
              (Unsplit.First, Rover, Memory (Container));
            Lemma_Reachable_Def (Rover, Memory (Container));
            Lemma_Reachable_Closed_By_Next (Unsplit.First, Memory (Container));

            Part1 :=
              (First  => Unsplit.First,
               Last   => Rover,
               Length => Bump_Count + 1);

            Part2 :=
              (First  => Container.Nodes (Rover).Next,
               Last   => Unsplit.Last,
               Length => Unsplit.Length - Part1.Length);

            pragma Assert (Static => Part2.First in Memory (Container)'Range);
            pragma
              Assert
                (Static =>
                   Memory_Index_Sets.Length
                     (Reachable_Set (Part2.First, Memory (Container)))
                   = Big_Conversions.To_Big (Part2.Length));

            Lemma_Reachable_Is_Acyclic
              (Unsplit.First, Part2.First, Memory (Container));
            Lemma_Reachable_Included
              (Unsplit.First, Part2.First, Memory (Container));

            --  The tail of the segment belongs to the second part: Rover
            --  heads two nodes or more, so it is not the tail itself, and the
            --  two are ordered along the chain.

            Lemma_Reachable_Is_Acyclic
              (Unsplit.First, Unsplit.Last, Memory (Container));
            Lemma_Reachable_Def (Unsplit.Last, Memory (Container));
            Lemma_Reachable_Ordered
              (Unsplit.First, Rover, Unsplit.Last, Memory (Container));

            pragma
              Assert
                (Static =>
                   Reachable (Part2.First, Memory (Container), Unsplit.Last));

            --  Detach

            Container.Nodes (Part1.Last).Next := 0;
            Container.Nodes (Part2.First).Prev := 0;

            Lemma_Reachable_After_Set
              (Part1.First, Part1.Last, 0, M_Old, Memory (Container));
            Lemma_Is_Acyclic_After_Set
              (Part1.First, Part1.Last, 0, M_Old, Memory (Container));
            Lemma_Reachable_Preserved (Part2.First, M_Old, Memory (Container));
            Lemma_Is_Acyclic_Preserved
              (Part2.First, M_Old, Memory (Container));

            Lemma_Reachable_Closed_By_Next (Part1.First, Memory (Container));
            Lemma_Reachable_Closed_By_Next (Part2.First, Memory (Container));

            --  Establish the postcondition conjunct by conjunct: merged into
            --  a single verification condition they time out.

            pragma
              Assert
                (Static =>
                   Memory_Index_Sets.No_Overlap
                     (Reachable_Set (Part1.First, Memory (Container)),
                      Reachable_Set (Part2.First, Memory (Container))));
            pragma
              Assert (Static => Segment_Valid (Memory (Container), Part1));
            pragma
              Assert (Static => Segment_Valid (Memory (Container), Part2));
            pragma
              Assert
                (Static =>
                   Untouched_Outside
                     (M_Old,
                      Memory (Container),
                      Reachable_Set (Unsplit.First, M_Old)));
         end Split_List;

      begin
         if Container.Length <= 1 then
            return;
         end if;

         Merge_Sort (Whole);

         Container.First := Whole.First;
         Container.Last := Whole.Last;

         pragma
           Assert (Static => Active_List_Valid (Container, Container.Length));

         --  The sort permutes the links of the active nodes and leaves every
         --  other node alone, so the free store is untouched and the active
         --  set is the same as on entry.

         Lemma_Free_List_Preserved (Container.Free, M_Old, Memory (Container));

         pragma Assert (Static => Covered (Container, 0));
         pragma
           Assert
             (Static => Structural_Invariant (Container, Container.Length));
      end Sort;

   end Generic_Sorting;

   -----------------
   -- Has_Element --
   -----------------

   function Has_Element (Container : List; Position : Cursor) return Boolean is
   begin
      return
        Position.Node in 1 .. Container.Capacity
        and then
          (Container.Free >= 0 or else Position.Node <= -(1 + Container.Free))
        and then Container.Nodes (Position.Node).Prev /= -1;
   end Has_Element;

   ------------
   -- Insert --
   ------------

   procedure Insert
     (Container : in out List;
      Before    : Cursor;
      New_Item  : Element_Type;
      Position  : out Cursor;
      Count     : Count_Type)
   is
      J  : Count_Type;
      L0 : constant Count_Type := Container.Length
      with Ghost => Static;

   begin
      if Before.Node /= 0 and then not Has_Element (Container, Before) then
         raise Program_Error with "bad cursor in Insert";
      end if;

      if Count = 0 then
         Position := Before;
         return;
      end if;

      if Container.Length > Count_Type'Last - Count then
         raise Constraint_Error with "new length exceeds maximum";
      end if;

      if Container.Length + Count > Container.Capacity then
         raise Capacity_Error with "new length exceeds target capacity";
      end if;

      Allocate (Container, New_Item, New_Node => J);
      Insert_Internal (Container, Before.Node, New_Node => J);
      Position := (Node => J);

      for Index in 2 .. Count loop
         pragma Loop_Invariant (Static => Structural_Invariant (Container));
         pragma Loop_Invariant (Static => Container.Length = L0 + (Index - 1));
         pragma
           Loop_Invariant
             (Static =>
                Container.Length + (Count - Index + 1) <= Container.Capacity);
         pragma
           Loop_Invariant
             (Static =>
                Before.Node = 0
                or else
                  Memory_Index_Sets.Contains
                    (Active_Set (Container), Before.Node));

         Allocate (Container, New_Item, New_Node => J);
         Insert_Internal (Container, Before.Node, New_Node => J);
      end loop;
      pragma Assert (Static => Is_Relevant (Container, Before));
   end Insert;

   procedure Insert
     (Container : in out List;
      Before    : Cursor;
      New_Item  : Element_Type;
      Position  : out Cursor) is
   begin
      Insert
        (Container => Container,
         Before    => Before,
         New_Item  => New_Item,
         Position  => Position,
         Count     => 1);
   end Insert;

   procedure Insert
     (Container : in out List;
      Before    : Cursor;
      New_Item  : Element_Type;
      Count     : Count_Type)
   is
      Position : Cursor;

   begin
      Insert (Container, Before, New_Item, Position, Count);
   end Insert;

   procedure Insert
     (Container : in out List; Before : Cursor; New_Item : Element_Type)
   is
      Position : Cursor;

   begin
      Insert (Container, Before, New_Item, Position, 1);
   end Insert;

   -----------------------
   -- Insert_First_Node --
   -----------------------

   procedure Insert_First_Node
     (Container : in out List; New_Node : Count_Type; Count : Count_Type)
   is
      N     : Node_Array renames Container.Nodes;
      M_Old : constant Nodes_Type_Base := Memory (Container)
      with Ghost => Static;
      F_Old : constant Count_Type := Container.First
      with Ghost => Static;
   begin
      --  Point the dangling New_Node at the old head, make it the new First,
      --  and fix the Prev links. The only Next change is New_Node's; the Prev
      --  writes and the First-field change touch no Next link.

      N (New_Node).Next := Container.First;
      N (Container.First).Prev := New_Node;
      Container.First := New_Node;
      N (Container.First).Prev := 0;

      --  F_Old is not reachable from New_Node in the pre-state (New_Node was
      --  dangling), so the old active list and the free chain are preserved
      --  across New_Node's Next change, and New_Node now heads the acyclic
      --  list {New_Node} + old active.

      Lemma_Reachable_Preserved (F_Old, M_Old, Memory (Container));
      Lemma_Is_Acyclic_Preserved (F_Old, M_Old, Memory (Container));
      Lemma_Is_Acyclic_Def (New_Node, Memory (Container));
      Lemma_Reachable_Def (New_Node, Memory (Container));

      pragma Assert (Static => Active_List_Valid (Container, Count + 1));
      Lemma_Free_List_Preserved (Container.Free, M_Old, Memory (Container));
   end Insert_First_Node;

   --------------------------
   -- Insert_Interior_Node --
   --------------------------

   procedure Insert_Interior_Node
     (Container : in out List;
      Before    : Count_Type;
      New_Node  : Count_Type;
      Count     : Count_Type)
   is
      N     : Node_Array renames Container.Nodes;
      P     : constant Count_Type := N (Before).Prev;
      M_Old : constant Nodes_Type_Base := Memory (Container)
      with Ghost => Static;
   begin
      --  Step 1: point the dangling New_Node at Before. Only New_Node's Next
      --  changes, so the old active list and the free chain are preserved and
      --  New_Node heads the acyclic list {New_Node} + Reachable_Set (Before).

      N (New_Node).Next := Before;
      N (New_Node).Prev := P;

      declare
         M1 : constant Nodes_Type_Base := Memory (Container)
         with Ghost => Static;

      begin
         --  The old active list is preserved

         Lemma_Reachable_Preserved (Container.First, M_Old, M1);
         Lemma_Is_Acyclic_Preserved (Container.First, M_Old, M1);

         --  New_Node heads the acyclic list {New_Node} + Reachable_Set
         --  (Before).

         Lemma_Reachable_Is_Acyclic (Container.First, Before, M_Old);
         Lemma_Reachable_Included (Container.First, Before, M_Old);
         Lemma_Reachable_Preserved (Before, M_Old, M1);
         Lemma_Is_Acyclic_Preserved (Before, M_Old, M1);
         Lemma_Is_Acyclic_Def (New_Node, M1);
         Lemma_Reachable_Def (New_Node, M1);

         Lemma_Is_Acyclic_Def (P, M1);
         Lemma_Reachable_Def (P, M1);
         Lemma_Reachable_Antisymmetric (Container.First, Before, M1);

         --  Step 2: redirect P's Next from Before to New_Node. P precedes
         --  Before, so P is not reachable from New_Node's disjoint acyclic
         --  list; the _Set lemma then adds exactly New_Node to the active set.

         N (P).Next := New_Node;
         N (Before).Prev := New_Node;

         Lemma_Reachable_After_Set
           (Container.First, P, New_Node, M1, Memory (Container));
         Lemma_Is_Acyclic_After_Set
           (Container.First, P, New_Node, M1, Memory (Container));
         Lemma_Reachable_Preserved (New_Node, M1, Memory (Container));
         Lemma_Is_Acyclic_Preserved (New_Node, M1, Memory (Container));
      end;

      Lemma_Add_Length
        (S1 => Reachable_Set (Container.First, M_Old),
         S2 => Reachable_Set (Container.First, Memory (Container)),
         E  => New_Node);

      pragma Assert (Static => Active_List_Valid (Container, Count + 1));

      Lemma_Free_List_Preserved (Container.Free, M_Old, Memory (Container));
   end Insert_Interior_Node;

   ---------------------
   -- Insert_Internal --
   ---------------------

   procedure Insert_Internal
     (Container : in out List; Before : Count_Type; New_Node : Count_Type)
   is
      N     : Node_Array renames Container.Nodes;
      M_Old : constant Nodes_Type_Base := Memory (Container)
      with Ghost => Static;

   begin
      if Container.Length = 0 then
         pragma
           Assert
             (Static => Memory_Index_Sets.Is_Empty (Active_Set (Container)));

         Container.First := New_Node;
         Container.Last := New_Node;

         N (Container.First).Prev := 0;
         N (Container.Last).Next := 0;

         Lemma_Is_Acyclic_Def (New_Node, Memory (Container));
         Lemma_Reachable_Def (New_Node, Memory (Container));
         Lemma_Free_List_Preserved (Container.Free, M_Old, Memory (Container));

         pragma Assert (Static => Structural_Invariant (Container, 1));

      elsif Before = 0 then
         Insert_Last_Node (Container, New_Node, Count => Container.Length);

      elsif Before = Container.First then
         Insert_First_Node (Container, New_Node, Count => Container.Length);

      else
         Insert_Interior_Node
           (Container, Before, New_Node, Count => Container.Length);
      end if;

      Container.Length := Container.Length + 1;

      pragma
        Assert (Static => Structural_Invariant (Container, Container.Length));
   end Insert_Internal;

   ----------------------
   -- Insert_Last_Node --
   ----------------------

   procedure Insert_Last_Node
     (Container : in out List; New_Node : Count_Type; Count : Count_Type)
   is
      N     : Node_Array renames Container.Nodes;
      L_Old : constant Count_Type := Container.Last
      with Ghost => Static;
      M_Old : constant Nodes_Type_Base := Memory (Container)
      with Ghost => Static;

   begin
      --  Step 1: make the dangling New_Node a singleton tail (Next = 0). Only
      --  New_Node's Next changes, so the old active list and free chain are
      --  preserved and Reachable_Set (New_Node) = {New_Node}.

      N (New_Node).Next := 0;
      N (New_Node).Prev := Container.Last;

      declare
         M1 : constant Nodes_Type_Base := Memory (Container)
         with Ghost => Static;
      begin
         Lemma_Reachable_Preserved (Container.First, M_Old, M1);
         Lemma_Is_Acyclic_Preserved (Container.First, M_Old, M1);
         Lemma_Is_Acyclic_Def (New_Node, M1);
         Lemma_Reachable_Def (New_Node, M1);

         --  Step 2: redirect the old Last's Next from 0 to New_Node. The
         --  New_Node singleton list does not reach the old Last, so the _Set
         --  lemma adds exactly New_Node to the active set.

         N (Container.Last).Next := New_Node;
         Container.Last := New_Node;

         Lemma_Reachable_After_Set
           (Container.First, L_Old, New_Node, M1, Memory (Container));
         Lemma_Is_Acyclic_After_Set
           (Container.First, L_Old, New_Node, M1, Memory (Container));
      end;

      Lemma_Add_Length
        (S1 => Reachable_Set (Container.First, M_Old),
         S2 => Reachable_Set (Container.First, Memory (Container)),
         E  => New_Node);
      Lemma_Free_List_Preserved (Container.Free, M_Old, Memory (Container));

      pragma Assert (Static => Active_List_Valid (Container, Count + 1));
   end Insert_Last_Node;

   ----------
   -- Last --
   ----------

   function Last (Container : List) return Cursor
   is (if Container.Last = 0 then No_Element else (Node => Container.Last));

   ------------------
   -- Last_Element --
   ------------------

   function Last_Element (Container : List) return Element_Type is
      L : constant Count_Type := Container.Last;

   begin
      if L = 0 then
         raise Constraint_Error with "list is empty";
      else
         return Container.Nodes (L).Element;
      end if;
   end Last_Element;

   ----------------------
   -- Lemma_Add_Length --
   ----------------------

   procedure Lemma_Add_Length
     (S1, S2 : Memory_Index_Set; E : Positive_Count_Type)
   is
      S3 : constant Memory_Index_Set := Memory_Index_Sets.Add (S1, E)
      with Ghost => Static;
      --  S3 = S1 + E is extensionally equal to S2 and, by construction, has
      --  Length (S1) + 1 elements.
   begin
      pragma Assert (Memory_Index_Sets."<=" (S3, S2));
      pragma Assert (Memory_Index_Sets."<=" (S2, S3));

      --  Mutually-included sets share their Num_Overlaps, which equals the
      --  length of either side; hence Length (S2) = Length (S3).

      pragma
        Assert
          (Memory_Index_Sets.Num_Overlaps (S2, S3)
           = Memory_Index_Sets.Length (S2));
      pragma
        Assert
          (Memory_Index_Sets.Num_Overlaps (S2, S3)
           = Memory_Index_Sets.Length (S3));
   end Lemma_Add_Length;

   -------------------------------
   -- Lemma_Free_List_Preserved --
   -------------------------------

   procedure Lemma_Free_List_Preserved
     (X : Count_Type'Base; M1, M2 : Nodes_Type_Base) is
   begin
      if X >= 0 then
         Lemma_Reachable_Preserved (X, M1, M2);
         Lemma_Is_Acyclic_Preserved (X, M1, M2);
      end if;
   end Lemma_Free_List_Preserved;

   -----------
   -- Model --
   -----------

   function Model (Container : List) return M.Sequence is
      Position : Count_Type := Container.First;
      R        : M.Sequence;

   begin
      --  The active list is closed under Next, so once Position is reachable
      --  from First its successor is reachable (or 0).

      Lemma_Reachable_Closed_By_Next (Container.First, Memory (Container));

      while Position /= 0 loop
         pragma
           Loop_Variant
             (Static =>
                (Decreases =>
                   Memory_Index_Sets.Length
                     (Reachable_Set (Position, Memory (Container)))));
         pragma
           Loop_Invariant
             (Static =>
                Reachable (Container.First, Memory (Container), Position));
         pragma
           Loop_Invariant
             (Static =>
                M.Length (R)
                + Memory_Index_Sets.Length
                    (Reachable_Set (Position, Memory (Container)))
                = M.Big (Container.Length));

         Lemma_Reachable_Is_Acyclic
           (Container.First, Position, Memory (Container));
         Lemma_Reachable_Def (Position, Memory (Container));

         R := M.Add (R, Container.Nodes (Position).Element);
         Position := Container.Nodes (Position).Next;
      end loop;

      return R;
   end Model;

   ----------
   -- Move --
   ----------

   procedure Move (Target : in out List; Source : in out List) is
      Same : constant Boolean := Same_Object (Target, Source);

      N    : Node_Array renames Source.Nodes;
      X    : Count_Type;
      Orig : constant Count_Type := Source.Length
      with Ghost => Static;

   begin
      if Same then
         return;
      end if;

      if Target.Capacity < Source.Length then
         raise Capacity_Error with "Source length exceeds Target capacity";
      end if;

      Clear (Target);

      --  Move Source's elements one at a time: append the first to Target,
      --  then unlink and free it in Source (Unlink_First_Node + Free). The
      --  running count Target.Length + Source.Length stays equal to the
      --  original Source length, so Target never overflows.

      while Source.Length > 1 loop
         pragma Loop_Invariant (Static => Structural_Invariant (Target));
         pragma Loop_Invariant (Static => Structural_Invariant (Source));
         pragma
           Loop_Invariant (Static => Target.Length + Source.Length = Orig);
         pragma Loop_Variant (Static => (Decreases => Source.Length));

         X := Source.First;
         Append (Target, N (X).Element);
         Unlink_First_Node (Source);
         Source.Length := Source.Length - 1;
         Free (Source, X);
      end loop;

      if Source.Length = 1 then

         --  Copy the last element, then drop the sole node

         X := Source.First;
         Append (Target, N (X).Element);
         Unlink_Sole_Node (Source);
         Source.Length := Source.Length - 1;
         Free (Source, X);
      end if;
   end Move;

   ----------
   -- Next --
   ----------

   procedure Next (Container : List; Position : in out Cursor) is
   begin
      Position := Next (Container, Position);
   end Next;

   function Next (Container : List; Position : Cursor) return Cursor is
   begin
      if Position.Node = 0 then
         return No_Element;
      end if;

      if not Has_Element (Container, Position) then
         raise Program_Error with "Position cursor has no element";
      end if;

      return (Node => Container.Nodes (Position.Node).Next);
   end Next;

   ---------------
   -- Positions --
   ---------------

   function Positions (Container : List) return P.Map is
      I        : Count_Type := 0;
      Position : Count_Type := Container.First;
      R        : P.Map;

   begin
      --  The active list is closed under Next; establish that once so the loop
      --  needs no per-iteration closure lemma.

      Lemma_Reachable_Closed_By_Next (Container.First, Memory (Container));

      while Position /= 0 loop
         pragma
           Loop_Variant
             (Static =>
                (Decreases =>
                   Memory_Index_Sets.Length
                     (Reachable_Set (Position, Memory (Container)))));
         pragma
           Loop_Invariant
             (Static =>
                Reachable (Container.First, Memory (Container), Position));
         pragma Loop_Invariant (Static => M.Big (I) = P.Length (R));
         pragma
           Loop_Invariant
             (Static =>
                P.Length (R)
                + Memory_Index_Sets.Length
                    (Reachable_Set (Position, Memory (Container)))
                = M.Big (Container.Length));
         pragma
           Loop_Invariant
             (Static =>
                (for all C of R =>
                   C.Node /= 0
                   and then
                     not Memory_Index_Sets.Contains
                           (Reachable_Set (Position, Memory (Container)),
                            C.Node)));

         Lemma_Reachable_Is_Acyclic
           (Container.First, Position, Memory (Container));
         Lemma_Reachable_Def (Position, Memory (Container));

         I := I + 1;
         R := P.Add (R, (Node => Position), I);
         Position := Container.Nodes (Position).Next;
      end loop;

      return R;
   end Positions;

   -------------
   -- Prepend --
   -------------

   procedure Prepend (Container : in out List; New_Item : Element_Type) is
   begin
      --  First (Container) is No_Element or the active-list head, hence a
      --  relevant cursor, so Insert never takes its Program_Error branch.

      pragma Assert (Static => Is_Relevant (Container, First (Container)));
      Insert (Container, First (Container), New_Item, 1);
   end Prepend;

   procedure Prepend
     (Container : in out List; New_Item : Element_Type; Count : Count_Type) is
   begin
      pragma Assert (Static => Is_Relevant (Container, First (Container)));
      Insert (Container, First (Container), New_Item, Count);
   end Prepend;

   --------------
   -- Previous --
   --------------

   procedure Previous (Container : List; Position : in out Cursor) is
   begin
      Position := Previous (Container, Position);
   end Previous;

   function Previous (Container : List; Position : Cursor) return Cursor is
   begin
      if Position.Node = 0 then
         return No_Element;
      end if;

      if not Has_Element (Container, Position) then
         raise Program_Error with "Position cursor has no element";
      end if;

      return (Node => Container.Nodes (Position.Node).Prev);
   end Previous;

   ---------------
   -- Reference --
   ---------------

   function Reference
     (Container : aliased in out List; Position : Cursor)
      return not null access Element_Type
   is
      M_Old : constant Nodes_Type_Base := Memory (Container)
      with Ghost => Static;

   begin
      if Position = No_Element then
         raise Constraint_Error with "Position cursor is No_Element";
      elsif not Has_Element (Container, Position) then
         raise Program_Error with "Position cursor has no element";
      end if;

      --  Use an extended return so the borrow is live in the do-block, where
      --  At_End (Container) is meaningful. The borrow can only change the
      --  designated element, never a link, so the active list (from First) and
      --  the free chain (from Free) are unchanged when the borrow ends and the
      --  structural invariant is restored.

      return
         R : constant not null access Element_Type :=
           Container.Nodes (Position.Node).Element'Access
      do
         Lemma_Reachable_Preserved
           (Container.First, M_Old, Memory (At_End (Container)));
         Lemma_Is_Acyclic_Preserved
           (Container.First, M_Old, Memory (At_End (Container)));

         Lemma_Free_List_Preserved
           (Container.Free, M_Old, Memory (At_End (Container)));
      end return;
   end Reference;

   ---------------------
   -- Replace_Element --
   ---------------------

   procedure Replace_Element
     (Container : in out List; Position : Cursor; New_Item : Element_Type)
   is
      M_Old : constant Nodes_Type_Base := Memory (Container)
      with Ghost => Static;

   begin
      if Position = No_Element then
         raise Constraint_Error with "Position cursor is No_Element";
      elsif not Has_Element (Container, Position) then
         raise Program_Error with "Position cursor has no element";
      end if;

      Container.Nodes (Position.Node).Element := New_Item;

      --  Only the element changed; every Next link is intact, so both the
      --  active list (from First) and the free chain (from Free, when
      --  explicit) are preserved unchanged.

      Lemma_Reachable_Preserved (Container.First, M_Old, Memory (Container));
      Lemma_Is_Acyclic_Preserved (Container.First, M_Old, Memory (Container));

      Lemma_Free_List_Preserved (Container.Free, M_Old, Memory (Container));
   end Replace_Element;

   ----------------------
   -- Reverse_Elements --
   ----------------------

   procedure Reverse_Elements (Container : in out List) is
      N : Node_Array renames Container.Nodes;

      Done : Count_Type := 0;
      Rest : Count_Type := Container.First;
      Nxt  : Count_Type;

      M_Old : constant Nodes_Type_Base := Memory (Container)
      with Ghost => Static;
      F_Old : constant Count_Type := Container.First
      with Ghost => Static;
      L_Old : constant Count_Type := Container.Last
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
      if Container.Length <= 1 then
         return;
      end if;

      --  Single-pass link reversal: walk front to back, moving each node from
      --  the head of the untouched suffix (Rest) to the head of the reversed
      --  prefix (Done), flipping its links. Done and Rest head two disjoint
      --  acyclic lists whose union is the active set; when Rest reaches 0 the
      --  list is reversed. Same final memory as an outside-in node swap, in
      --  O (Length).

      while Rest /= 0 loop
         pragma
           Loop_Variant
             (Static =>
                (Decreases =>
                   Memory_Index_Sets.Length
                     (Reachable_Set (Rest, Memory (Container)))));

         pragma Loop_Invariant (Static => Valid_Memory (Memory (Container)));
         pragma
           Loop_Invariant
             (Static =>
                Done in Memory (Container)'Range | 0
                and then Rest in Memory (Container)'Range | 0);
         pragma
           Loop_Invariant
             (Static =>
                Cells_Partitioned
                  (Memory (Container),
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
                   Memory (Container) (Done).Prev = Rest
                   and Valid_Segment (Memory (Container), Done, F_Old)));
         pragma
           Loop_Invariant
             (Static =>
                (for all I of Reachable_Set (Rest, Memory (Container)) =>
                   Memory (Container) (I).Next = M_Old (I).Next
                   and then Memory (Container) (I).Prev = M_Old (I).Prev));
         pragma
           Loop_Invariant
             (Static =>
                (for all I in Memory (Container)'Range =>
                   (if not Reachable (F_Old, M_Old, I)
                    then
                      Memory (Container) (I).Next = M_Old (I).Next
                      and then Memory (Container) (I).Prev = M_Old (I).Prev)));

         declare
            M1 : constant Nodes_Type_Base := Memory (Container)
            with Ghost => Static;
         begin
            --  Move Rest (head of the untouched suffix) to the head of the
            --  reversed list by pointing its Next at Done; the step lemma
            --  carries the whole invariant across the single link change.

            Nxt := N (Rest).Next;

            N (Rest).Next := Done;
            N (Rest).Prev := Nxt;

            Lemma_Reverse_Step (M1, Memory (Container), Done, Rest, Nxt);
         end;

         Done := Rest;
         Rest := Nxt;
      end loop;

      --  Rest = 0: the suffix is empty and every active node is on the
      --  reversed list, now headed by Done = L_Old.

      pragma Assert (Static => Done = L_Old);

      Container.Last := Container.First;
      Container.First := Done;

      --  The whole (reversed) active set is now RS (Done); its self-contained
      --  consistency gives Active_List_Valid directly.

      pragma
        Assert
          (Static =>
             Memory_Index_Sets."="
               (Reachable_Set (Container.First, Memory (Container)),
                Reachable_Set (F_Old, M_Old)));
      pragma
        Assert (Static => Active_List_Valid (Container, Container.Length));

      --  The free store was never touched (only active nodes were relinked),
      --  so its chain (Next links) is preserved from M_Old.

      Lemma_Free_List_Preserved (Container.Free, M_Old, Memory (Container));

      pragma
        Assert (Static => Structural_Invariant (Container, Container.Length));
   end Reverse_Elements;

   ------------------
   -- Reverse_Find --
   ------------------

   function Reverse_Find
     (Container : List; Item : Element_Type; Position : Cursor := No_Element)
      return Cursor
   is
      CFirst : Count_Type := Position.Node;

   begin
      if CFirst = 0 then
         CFirst := Container.Last;

      elsif not Has_Element (Container, Position) then
         raise Program_Error with "bad cursor in Reverse_Find";
      end if;

      if Container.Length = 0 then
         return No_Element;

      else
         while CFirst /= 0 loop
            Lemma_Reachable_Is_Acyclic
              (Container.First, CFirst, Memory (Container));
            Lemma_Reachable_Def (CFirst, Memory (Container));
            Lemma_Reachable_Included
              (Container.First, CFirst, Memory (Container));
            pragma
              Assert
                (Static =>
                   Memory_Index_Sets.Num_Overlaps
                     (Reachable_Set (CFirst, Memory (Container)),
                      Reachable_Set (Container.First, Memory (Container)))
                   = Memory_Index_Sets.Length
                       (Reachable_Set (CFirst, Memory (Container))));

            pragma Warnings (Off, "condition is always True");
            pragma Loop_Invariant (Static => CFirst /= 0);
            pragma
              Loop_Invariant
                (Static =>
                   Reachable (Container.First, Memory (Container), CFirst));
            pragma
              Loop_Variant
                (Static =>
                   (Decreases =>
                      Memory_Index_Sets.Length
                        (Reachable_Set (Container.First, Memory (Container)))
                      - Memory_Index_Sets.Length
                          (Reachable_Set (CFirst, Memory (Container)))));
            pragma Warnings (On, "condition is always True");

            if Container.Nodes (CFirst).Element = Item then
               return (Node => CFirst);
            else
               CFirst := Container.Nodes (CFirst).Prev;
            end if;
         end loop;

         return No_Element;
      end if;
   end Reverse_Find;

   ------------
   -- Splice --
   ------------

   procedure Splice
     (Target : in out List; Before : Cursor; Source : in out List)
   is
      Same : constant Boolean := Same_Object (Target, Source);

      SN : Node_Array renames Source.Nodes;

      Orig_Sum : Count_Type
      with Ghost => Static;
      --  The invariant sum Target.Length + Source.Length (captured once the
      --  guards rule out its overflow), which bounds Target below capacity.

   begin
      --  Name the volatile aliasing outcome as a pre-state ghost fact so the
      --  Exit_Cases can refer to it (Same_Object cannot appear in a contract).

      pragma Assume (Static => Same = Same_Object_Ghost);

      if Before.Node /= 0 and then not Has_Element (Target, Before) then
         raise Program_Error with "bad cursor in Splice";
      end if;

      if Same or else Source.Length = 0 then
         return;
      end if;

      if Target.Length > Count_Type'Last - Source.Length then
         raise Constraint_Error with "new length exceeds maximum";
      end if;

      if Target.Length + Source.Length > Target.Capacity then
         raise Capacity_Error with "new length exceeds target capacity";
      end if;

      Orig_Sum := Target.Length + Source.Length;

      --  Move Source's elements into Target one at a time: insert the first
      --  before Before, then unlink and free it in Source. The running sum
      --  Target.Length + Source.Length stays equal to Orig_Sum, so Target
      --  never overflows and each Insert keeps Before a valid cursor.

      while Source.Length > 1 loop
         pragma Loop_Invariant (Static => Structural_Invariant (Target));
         pragma Loop_Invariant (Static => Structural_Invariant (Source));
         pragma Loop_Invariant (Static => Is_Relevant (Target, Before));
         pragma
           Loop_Invariant (Static => Target.Length + Source.Length = Orig_Sum);
         pragma Loop_Invariant (Static => Orig_Sum <= Target.Capacity);
         pragma Loop_Variant (Static => (Decreases => Source.Length));

         Insert (Target, Before, SN (Source.First).Element);
         declare
            X : constant Count_Type := Source.First;
         begin
            Unlink_First_Node (Source);
            Source.Length := Source.Length - 1;
            Free (Source, X);
         end;
      end loop;

      if Source.Length = 1 then

         --  Insert the last element, then drop the sole node in Source

         Insert (Target, Before, SN (Source.First).Element);
         declare
            X : constant Count_Type := Source.First;
         begin
            Unlink_Sole_Node (Source);
            Source.Length := Source.Length - 1;
            Free (Source, X);
         end;
      end if;
   end Splice;

   procedure Splice
     (Target   : in out List;
      Before   : Cursor;
      Source   : in out List;
      Position : in out Cursor)
   is
      Same : constant Boolean := Same_Object (Target, Source);

      Target_Position : Cursor;

   begin
      --  Name the volatile aliasing outcome as a pre-state ghost fact so the
      --  Exit_Cases can refer to it (Same_Object cannot appear in a contract).

      pragma Assume (Static => Same = Same_Object_Ghost);

      if Same then
         Splice (Target, Before, Position);
         return;
      end if;

      if Before.Node /= 0 and then not Has_Element (Target, Before) then
         raise Program_Error with "bad Before cursor in Splice";
      end if;

      if Position.Node = 0 then
         raise Constraint_Error with "Position cursor has no element";
      elsif not Has_Element (Source, Position) then
         raise Program_Error with "bad Position cursor in Splice";
      end if;

      if Target.Length = Count_Type'Last then
         raise Constraint_Error with "Target exceeds maximum";
      elsif Target.Length >= Target.Capacity then
         raise Capacity_Error with "Target is full";
      end if;

      Insert
        (Container => Target,
         Before    => Before,
         New_Item  => Source.Nodes (Position.Node).Element,
         Position  => Target_Position);

      --  Take Position's node off Source. Delete exports the active-set
      --  change (Is_Add), which is what keeps the other Source cursors of a
      --  caller valid across the move. It also resets the cursor it is given,
      --  which is discarded here: Position is set to the node's new location
      --  in Target.

      Delete (Source, Position);

      Position := Target_Position;
   end Splice;

   procedure Splice
     (Container : in out List; Before : Cursor; Position : Cursor)
   is
      X : constant Count_Type := Position.Node;

      procedure Lemma_Length_Ge_2
        (Container : List; Before : Cursor; Position : Cursor)
      with
        Ghost => Static,
        Pre   =>
          Structural_Invariant (Container)
          and then Has_Element (Container, Position)
          and then (Before = No_Element or Has_Element (Container, Before))
          and then Position /= Before
          and then Container.Nodes (Position.Node).Next /= Before.Node,
        Post  => Container.Length >= 2;
      --  Past the early returns Length >= 2 (a one-node list forces Before to
      --  be Position or 0 = Next (Position), both no-ops). Establish it -- the
      --  unlink helpers require it -- by exhibiting two distinct active nodes:
      --  X and either Before, or (when Before = 0) the successor Next (X),
      --  which is active and /= X here.

      -----------------------
      -- Lemma_Length_Ge_2 --
      -----------------------

      procedure Lemma_Length_Ge_2
        (Container : List; Before : Cursor; Position : Cursor)
      is
         use Memory_Index_Sets;
         X : constant Positive_Count_Type := Position.Node;
         Y : constant Positive_Count_Type :=
           (if Before.Node = 0 then Container.Nodes (X).Next else Before.Node);

      begin
         if Before.Node = 0 then
            Lemma_Reachable_Is_Acyclic
              (Container.First, X, Memory (Container));
            Lemma_Reachable_Included (Container.First, X, Memory (Container));
            Lemma_Reachable_Def (X, Memory (Container));
         end if;
         pragma
           Assert
             (Num_Overlaps
                (Add (Add (Empty_Set, X), Y), Active_Set (Container))
              = 2);
      end Lemma_Length_Ge_2;

   begin
      if Before.Node /= 0 and then not Has_Element (Container, Before) then
         raise Program_Error with "bad Before cursor in Splice";
      end if;

      if Position.Node = 0 then
         raise Constraint_Error with "Position cursor has no element";
      elsif not Has_Element (Container, Position) then
         raise Program_Error with "bad Position cursor in Splice";
      end if;

      if Position.Node = Before.Node
        or else Container.Nodes (X).Next = Before.Node
      then
         return;
      end if;

      --  Past the early returns Length >= 2 (a one-node list forces Before to
      --  be Position or 0 = Next (Position), both no-ops). Establish it -- the
      --  unlink helpers require it -- by exhibiting two distinct active nodes:
      --  X and either Before, or (when Before = 0) the successor Next (X),
      --  which is active and /= X here.

      Lemma_Length_Ge_2 (Container, Before, Position);

      --  Unlink X from wherever it currently sits, leaving it dangling

      if X = Container.First then
         Unlink_First_Node (Container);
      elsif X = Container.Last then
         Unlink_Last_Node (Container);
      else
         Unlink_Interior_Node (Container, X);
      end if;

      --  Relink the dangling X before Before (or at the end when Before = 0).
      --  Count = Length - 1: the field Length still carries the pre-move value
      --  (the unlink is Length-neutral), and X is not currently counted.

      if Before.Node = 0 then
         Insert_Last_Node (Container, X, Count => Container.Length - 1);
      elsif Before.Node = Container.First then
         Insert_First_Node (Container, X, Count => Container.Length - 1);
      else
         Insert_Interior_Node
           (Container, Before.Node, X, Count => Container.Length - 1);
      end if;
   end Splice;

   ----------
   -- Swap --
   ----------

   procedure Swap (Container : in out List; I : Cursor; J : Cursor) is
      M_Old : constant Nodes_Type_Base := Memory (Container)
      with Ghost => Static;

   begin
      if I.Node = 0 then
         raise Constraint_Error with "I cursor has no element";
      end if;

      if J.Node = 0 then
         raise Constraint_Error with "J cursor has no element";
      end if;

      if not Has_Element (Container, I) then
         raise Program_Error with "bad I cursor in Swap";
      end if;

      if not Has_Element (Container, J) then
         raise Program_Error with "bad J cursor in Swap";
      end if;

      if I.Node = J.Node then
         return;
      end if;

      declare
         NN : Node_Array renames Container.Nodes;
         NI : Node_Type renames NN (I.Node);
         NJ : Node_Type renames NN (J.Node);

         EI_Copy : constant Element_Type := NI.Element;

      begin
         NI.Element := NJ.Element;
         NJ.Element := EI_Copy;
      end;

      --  Only two elements changed; every Next link is intact, so the active
      --  list (from First) and the free chain (from Free, when explicit) are
      --  preserved unchanged.

      Lemma_Reachable_Preserved (Container.First, M_Old, Memory (Container));
      Lemma_Is_Acyclic_Preserved (Container.First, M_Old, Memory (Container));

      Lemma_Free_List_Preserved (Container.Free, M_Old, Memory (Container));

      pragma
        Assert (Static => Active_List_Valid (Container, Container.Length));
   end Swap;

   ----------------
   -- Swap_Links --
   ----------------

   procedure Swap_Links (Container : in out List; I : Cursor; J : Cursor) is
      I_Next : Cursor;
      J_Next : Cursor;

   begin
      if I.Node = 0 then
         raise Constraint_Error with "I cursor has no element";
      end if;

      if J.Node = 0 then
         raise Constraint_Error with "J cursor has no element";
      end if;

      if not Has_Element (Container, I) then
         raise Program_Error with "bad I cursor in Swap_Links";
      end if;

      if not Has_Element (Container, J) then
         raise Program_Error with "bad J cursor in Swap_Links";
      end if;

      if I.Node = J.Node then
         return;
      end if;

      --  I and J are active nodes and the active list is closed under Next, so
      --  their successors are active or No_Element -- hence valid cursors.

      Lemma_Reachable_Closed_By_Next (Container.First, Memory (Container));

      --  Read the successors directly (I and J are active, so the index is in
      --  range) rather than via Next, keeping the representation out of any
      --  spec-level contract while giving proof the link value.

      I_Next := (Node => Container.Nodes (I.Node).Next);

      if I_Next = J then
         Splice (Container, Before => I, Position => J);

      else
         J_Next := (Node => Container.Nodes (J.Node).Next);

         if J_Next = I then
            Splice (Container, Before => J, Position => I);

         else
            Splice (Container, Before => I_Next, Position => J);

            Splice (Container, Before => J_Next, Position => I);
         end if;
      end if;
   end Swap_Links;

   -----------------------
   -- Unlink_First_Node --
   -----------------------

   procedure Unlink_First_Node (Container : in out List) is
      N     : Node_Array renames Container.Nodes;
      X     : constant Count_Type := Container.First;
      M_Old : constant Nodes_Type_Base := Memory (Container)
      with Ghost => Static;
   begin
      --  Split the active head X off: its successor heads a strictly shorter
      --  acyclic list that no longer contains X.

      Lemma_Is_Acyclic_Def (X, M_Old);
      Lemma_Reachable_Def (X, M_Old);

      Container.First := N (X).Next;
      N (Container.First).Prev := 0;

      --  Only a Prev field changed, so every Next link is intact: the new
      --  active list and the free chain are preserved, leaving X off both.

      Lemma_Reachable_Preserved (Container.First, M_Old, Memory (Container));
      Lemma_Is_Acyclic_Preserved (Container.First, M_Old, Memory (Container));

      Lemma_Free_List_Preserved (Container.Free, M_Old, Memory (Container));

      pragma
        Assert (Static => Active_List_Valid (Container, Container.Length - 1));
   end Unlink_First_Node;

   --------------------------
   -- Unlink_Interior_Node --
   --------------------------

   procedure Unlink_Interior_Node (Container : in out List; X : Count_Type) is
      N     : Node_Array renames Container.Nodes;
      P     : constant Count_Type := N (X).Prev;
      Q     : constant Count_Type := N (X).Next;
      M_Old : constant Nodes_Type_Base := Memory (Container)
      with Ghost => Static;

   begin
      --  X is interior, so it lies strictly between its active neighbours
      --  P = Prev (X) and Q = Next (X). Both are reachable from First on the
      --  acyclic active list, and P reaches Q (through X) but not conversely.
      --  These facts feed the _Set lemma preconditions below.

      Lemma_Reachable_Is_Acyclic (Container.First, X, M_Old);
      Lemma_Reachable_Included (Container.First, X, M_Old);
      Lemma_Reachable_Def (X, M_Old);
      Lemma_Is_Acyclic_Def (X, M_Old);

      pragma
        Assert
          (Static => not Memory_Index_Sets.Is_Empty (Active_Set (Container)));

      --  P -> X (P = Prev (X)), so P reaches X. As the list is acyclic X does
      --  not reach P, and neither does its successor Q (Reachable_Set (Q) is a
      --  subset of Reachable_Set (X)). This is the disjointness the _Set
      --  lemmas require.

      Lemma_Reachable_Is_Acyclic (Container.First, P, M_Old);
      Lemma_Reachable_Def (P, M_Old);
      Lemma_Reachable_Antisymmetric (X, P, M_Old);

      --  Bypass X (P -> Q), leaving X off the active list

      N (Q).Prev := P;
      N (P).Next := Q;

      --  Only P's Next changed (from X to Q): the active list loses exactly X
      --  (the tail from Q is spliced directly onto the prefix ending at P).
      --  The free chain, disjoint from the active list, is preserved.

      Lemma_Reachable_After_Set
        (Container.First, P, Q, M_Old, Memory (Container));
      Lemma_Is_Acyclic_After_Set
        (Container.First, P, Q, M_Old, Memory (Container));

      Lemma_Add_Length
        (S1 => Reachable_Set (Container.First, Memory (Container)),
         S2 => Reachable_Set (Container.First, M_Old),
         E  => X);

      --  Pin the active-node count on its own so the Limbo_State Post's
      --  Active_List_Valid conjunct matches it directly (the merged VC times
      --  out otherwise).

      pragma
        Assert (Static => Active_List_Valid (Container, Container.Length - 1));

      Lemma_Free_List_Preserved (Container.Free, M_Old, Memory (Container));
   end Unlink_Interior_Node;

   ----------------------
   -- Unlink_Last_Node --
   ----------------------

   procedure Unlink_Last_Node (Container : in out List) is
      N     : Node_Array renames Container.Nodes;
      X     : constant Count_Type := Container.Last;
      Y     : constant Count_Type := N (X).Prev;
      M_Old : constant Nodes_Type_Base := Memory (Container)
      with Ghost => Static;

   begin
      --  X = Last is active. Length >= 2 forces First /= Last (a single-node
      --  list has Reachable_Set (First) = {First}), so X is not First and its
      --  predecessor Y is an active node -- a valid index that becomes the new
      --  last.

      Lemma_Reachable_Def (Container.First, M_Old);

      --  Cut Y's Next from X to 0, unlinking X

      Container.Last := Y;
      N (Y).Next := 0;

      --  Only Y's Next changed (from X to 0): the active list loses exactly
      --  the tail X, and the free chain (disjoint from it) is preserved.

      Lemma_Reachable_After_Set
        (Container.First, Y, 0, M_Old, Memory (Container));
      Lemma_Is_Acyclic_After_Set
        (Container.First, Y, 0, M_Old, Memory (Container));

      --  Reachable_Set (X, M_Old) = {X} (X = Last has Next 0), so the new
      --  active list is the old one with exactly X removed; Lemma_Add_Length
      --  then gives the node count.

      Lemma_Reachable_Is_Acyclic (Container.First, X, M_Old);
      Lemma_Reachable_Def (X, M_Old);
      Lemma_Add_Length
        (S1 => Reachable_Set (Container.First, Memory (Container)),
         S2 => Reachable_Set (Container.First, M_Old),
         E  => X);

      Lemma_Free_List_Preserved (Container.Free, M_Old, Memory (Container));

      pragma
        Assert (Static => Active_List_Valid (Container, Container.Length - 1));
   end Unlink_Last_Node;

   ----------------------
   -- Unlink_Sole_Node --
   ----------------------

   procedure Unlink_Sole_Node (Container : in out List) is
      X : constant Count_Type := Container.First;
   begin
      --  Length is 1, so the active list is exactly {X}: every other touched
      --  node is free, which is what Covered needs once X becomes dangling.

      Lemma_Reachable_Def (X, Memory (Container));

      Container.First := 0;
      Container.Last := 0;

      pragma Assert (Static => Active_List_Valid (Container, 0));
   end Unlink_Sole_Node;

end SPARK.Containers.Formal.Doubly_Linked_Lists.Impl;
