--
--  Copyright (C) 2004-2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with SPARK.Containers.Formal.Generic_List_Operations;

package body SPARK.Containers.Formal.Doubly_Linked_Lists.Impl
  with SPARK_Mode => On
is

   package Address_Comparisons is new
     SPARK.Containers.Formal.Impl.Address_Space.Address_Comparison (List);

   function Same_Object (Left, Right : List) return Boolean
   renames Address_Comparisons.Same_Object;

   function Is_Initialized (H : Relaxed_Element) return Boolean
   is (H.V'Initialized)
   with Ghost => Static;

   function Is_Reclaimed (H : Relaxed_Element) return Boolean
   is (True)
   with Ghost => Static;

   function Constant_Access
     (H : aliased Relaxed_Element) return not null access constant Element_Type
   is (H.V'Access)
   with Global => null, Pre => (Static => Is_Initialized (H));

   procedure Fill (H : out Relaxed_Element; Item : Element_Type)
   with Global => null, Post => (Static => Is_Initialized (H)), Inline;

   procedure Move_Element
     (Source : in out Relaxed_Element; Target : in out Relaxed_Element)
   with
     Global => null,
     Pre    =>
       (Static => Is_Initialized (Source) and then Is_Reclaimed (Target)),
     Post   =>
       (Static =>
          Is_Initialized (Target)
          and then Is_Initialized (Source)
          and then Is_Reclaimed (Source)),
     Inline;

   procedure Reclaim (H : in out Relaxed_Element)
   with
     Global => null,
     Post   => (Static => Is_Initialized (H) = Is_Initialized (H'Old)),
     Inline;

   procedure Copy_Elements
     (Target : in out Elements_Array;
      Source : Elements_Array;
      Nodes  : Node_Array;
      Free   : Count_Type'Base)
   with
     Global => null,
     Pre    =>
       (Static =>
          Storage.Valid_Links (Nodes, Free)
          and then Target'First = Source'First
          and then Target'Last = Source'Last
          and then Source'First = Nodes'First
          and then Source'Last = Nodes'Last),
     Post   =>
       (Static =>
          (for all I in Target'Range =>
             Is_Initialized (Target (I)) = Is_Initialized (Source (I)))),
     Inline;

   procedure Exchange (Elements : in out Elements_Array; I, J : Count_Type)
   with
     Global => null,
     Pre    =>
       (Static =>
          I in Elements'Range
          and then J in Elements'Range
          and then I /= J
          and then Is_Initialized (Elements (I))
          and then Is_Initialized (Elements (J))),
     Post   =>
       (Static =>
          (for all K in Elements'Range =>
             Is_Initialized (Elements (K))
             = Is_Initialized (Elements'Old (K)))),
     Inline;

   package Ops is new
     Generic_List_Operations
       (Element_Type    => Element_Type,
        "="             => "=",
        Holder_Type     => Relaxed_Element,
        Storage         => Storage,
        Is_Initialized  => Is_Initialized,
        Is_Reclaimed    => Is_Reclaimed,
        Constant_Access => Constant_Access,
        Fill            => Fill,
        Reclaim         => Reclaim,
        Move_Element    => Move_Element,
        Copy_Elements   => Copy_Elements,
        Exchange        => Exchange);

   function To_Cursor (Index : Count_Type) return Cursor
   is ((Node => Index))
   with Ghost => SPARKlib_Logic;

   function Node (Position : Cursor) return Count_Type
   is (Position.Node)
   with Ghost => SPARKlib_Logic;

   package Model_Ops is new
     Ops.Generic_Model
       (Cursor,
        To_Cursor,
        Node,
        Formal_Model.M,
        Formal_Model.P);

   ---------
   -- "=" --
   ---------

   function "=" (Left : List; Right : List) return Boolean is
      Same : constant Boolean := Same_Object (Left, Right);
      --  Volatile read in a non-interfering context (object initialization)

   begin
      if Same then
         return True;
      end if;

      return
        Ops.Equal
          (Left.Nodes,
           Left.Elements,
           Left.Free,
           Left.First,
           Left.Last,
           Left.Length,
           Right.Nodes,
           Right.Elements,
           Right.Free,
           Right.First,
           Right.Last,
           Right.Length);
   end "=";

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

   begin
      if Same then
         return;
      end if;

      if Target.Capacity < Source.Length then
         raise Capacity_Error with "Source length exceeds Target capacity";
      end if;

      Ops.Assign
        (Target.Nodes,
         Target.Elements,
         Target.Free,
         Target.First,
         Target.Last,
         Target.Length,
         Source.Nodes,
         Source.Elements,
         Source.Free,
         Source.First,
         Source.Last,
         Source.Length);
   end Assign;

   -----------
   -- Clear --
   -----------

   procedure Clear (Container : in out List) is
   begin
      Ops.Clear
        (Container.Nodes,
         Container.Elements,
         Container.Free,
         Container.First,
         Container.Last,
         Container.Length);
   end Clear;

   ------------------------
   -- Constant_Reference --
   ------------------------

   function Constant_Reference
     (Container : aliased List; Position : Cursor)
      return not null access constant Element_Type is
   begin
      if Position.Node = 0 then
         raise Constraint_Error with "Position cursor has no element";
      elsif not Has_Element (Container, Position) then
         raise Program_Error
           with "Position cursor designates no element in Container";
      end if;

      return Container.Elements (Position.Node).V'Access;
   end Constant_Reference;

   --------------
   -- Contains --
   --------------

   function Contains (Container : List; Item : Element_Type) return Boolean is
      Position : Cursor;
   begin
      Position := Find (Container, Item);
      return Position.Node /= 0;
   end Contains;

   ----------
   -- Copy --
   ----------

   function Copy (Source : List; Capacity : Count_Type := 0) return List is
      C : constant Count_Type := Count_Type'Max (Source.Capacity, Capacity);
      P : List (C);

   begin
      if Capacity < Source.Length and then Capacity /= 0 then
         raise Capacity_Error
           with "Requested capacity is less than Source length";
      end if;

      Ops.Copy
        (P.Nodes,
         P.Elements,
         P.Free,
         P.First,
         P.Last,
         P.Length,
         Source.Nodes,
         Source.Elements,
         Source.Free,
         Source.First,
         Source.Last,
         Source.Length);

      return P;
   end Copy;

   -------------------
   -- Copy_Elements --
   -------------------

   procedure Copy_Elements
     (Target : in out Elements_Array;
      Source : Elements_Array;
      Nodes  : Node_Array;
      Free   : Count_Type'Base) is
   begin
      Target := Source;
   end Copy_Elements;

   ------------
   -- Delete --
   ------------

   procedure Delete (Container : in out List; Position : in out Cursor) is
      X : constant Count_Type := Position.Node;
   begin
      if Position.Node = 0 then
         raise Constraint_Error with "Position cursor has no element";
      elsif not Has_Element (Container => Container, Position => Position) then
         raise Program_Error
           with "Position cursor designates no element in Container";
      end if;

      Position := No_Element;
      Ops.Delete
        (Container.Nodes,
         Container.Elements,
         Container.Free,
         Container.First,
         Container.Last,
         Container.Length,
         X);
   end Delete;

   procedure Delete
     (Container : in out List; Position : in out Cursor; Count : Count_Type) is
   begin
      if Position.Node = 0 then
         raise Constraint_Error with "Position cursor has no element";
      elsif not Has_Element (Container => Container, Position => Position) then
         raise Program_Error
           with "Position cursor designates no element in Container";
      end if;

      Ops.Delete
        (Container.Nodes,
         Container.Elements,
         Container.Free,
         Container.First,
         Container.Last,
         Container.Length,
         Position.Node,
         Count);
   end Delete;

   ------------------
   -- Delete_First --
   ------------------

   procedure Delete_First (Container : in out List) is
   begin
      Delete_First (Container => Container, Count => 1);
   end Delete_First;

   procedure Delete_First (Container : in out List; Count : Count_Type) is
   begin
      Ops.Delete_First
        (Container.Nodes,
         Container.Elements,
         Container.Free,
         Container.First,
         Container.Last,
         Container.Length,
         Count);
   end Delete_First;

   -----------------
   -- Delete_Last --
   -----------------

   procedure Delete_Last (Container : in out List) is
   begin
      Delete_Last (Container => Container, Count => 1);
   end Delete_Last;

   procedure Delete_Last (Container : in out List; Count : Count_Type) is
   begin
      Ops.Delete_Last
        (Container.Nodes,
         Container.Elements,
         Container.Free,
         Container.First,
         Container.Last,
         Container.Length,
         Count);
   end Delete_Last;

   -------------
   -- Element --
   -------------

   function Element (Container : List; Position : Cursor) return Element_Type
   is
   begin
      if Position.Node = 0 then
         raise Constraint_Error with "Position cursor has no element";
      elsif not Has_Element (Container => Container, Position => Position) then
         raise Program_Error
           with "Position cursor designates no element in Container";
      end if;

      return Ops.Element (Container.Elements, Position.Node);
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
       Nodes    => (1 .. Capacity => <>),
       Elements => (1 .. Capacity => <>));

   --------------
   -- Exchange --
   --------------

   procedure Exchange (Elements : in out Elements_Array; I, J : Count_Type) is
      EI : Element_Type renames Elements (I).V;
      EJ : Element_Type renames Elements (J).V;

      EI_Copy : constant Element_Type := EI;

   begin
      EI := EJ;
      EJ := EI_Copy;
   end Exchange;

   ----------
   -- Fill --
   ----------

   procedure Fill (H : out Relaxed_Element; Item : Element_Type) is
   begin
      H.V := Item;
   end Fill;

   ----------
   -- Find --
   ----------

   function Find
     (Container : List; Item : Element_Type; Position : Cursor := No_Element)
      return Cursor is
   begin
      if Position.Node /= 0 and then not Has_Element (Container, Position) then
         raise Program_Error
           with "Position cursor designates no element in Container";
      end if;

      return
        (Node =>
           Ops.Find
             (Container.Nodes,
              Container.Elements,
              Container.Free,
              Container.First,
              Container.Last,
              Container.Length,
              Item,
              Position.Node));
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
         pragma Assert (Static => Container.Length > 0);
         return Ops.Element (Container.Elements, F);
      end if;
   end First_Element;

   ---------------------
   -- Generic_Sorting --
   ---------------------

   package body Generic_Sorting is

      package Sorting_Ops is new Ops.Generic_Sorting ("<");

      ---------------
      -- Is_Sorted --
      ---------------

      function Is_Sorted (Container : List) return Boolean is
      begin
         return
           Sorting_Ops.Is_Sorted
             (Container.Nodes,
              Container.Elements,
              Container.Free,
              Container.First,
              Container.Last,
              Container.Length);
      end Is_Sorted;

      -----------
      -- Merge --
      -----------

      procedure Merge (Target : in out List; Source : in out List) is
         Same : constant Boolean := Same_Object (Target, Source);
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

         Sorting_Ops.Merge
           (Target.Nodes,
            Target.Elements,
            Target.Free,
            Target.First,
            Target.Last,
            Target.Length,
            Source.Nodes,
            Source.Elements,
            Source.Free,
            Source.First,
            Source.Last,
            Source.Length);
      end Merge;

      ----------
      -- Sort --
      ----------

      procedure Sort (Container : in out List) is
      begin
         Sorting_Ops.Sort
           (Container.Nodes,
            Container.Elements,
            Container.Free,
            Container.First,
            Container.Last,
            Container.Length);
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
      Count     : Count_Type) is
   begin
      if Before.Node /= 0 and then not Has_Element (Container, Before) then
         raise Program_Error
           with "Before cursor designates no element in Container";
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

      Ops.Insert
        (Container.Nodes,
         Container.Elements,
         Container.Free,
         Container.First,
         Container.Last,
         Container.Length,
         Before.Node,
         New_Item,
         Position.Node,
         Count);
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
         return Ops.Element (Container.Elements, L);
      end if;
   end Last_Element;

   ----------------
   -- List_Model --
   ----------------

   package body List_Model is

      ---------------------
      -- Generic_Sorting --
      ---------------------

      package body Generic_Sorting is
         package Sorting_Model is new Model_Ops.Generic_Sorting ("<");

         -----------------------
         -- M_Elements_Sorted --
         -----------------------

         function M_Elements_Sorted (Container : M.Sequence) return Boolean
         renames Sorting_Model.M_Elements_Sorted;
      end Generic_Sorting;

      -------------------------
      -- M_Elements_In_Union --
      -------------------------

      function M_Elements_In_Union
        (Container, Left, Right : M.Sequence) return Boolean
      renames Model_Ops.M_Elements_In_Union;

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
      renames Model_Ops.M_Elements_Included;

      -------------------------
      -- M_Elements_Reversed --
      -------------------------

      function M_Elements_Reversed (Left, Right : M.Sequence) return Boolean
      renames Model_Ops.M_Elements_Reversed;

      ------------------------
      -- M_Elements_Swapped --
      ------------------------

      function M_Elements_Swapped
        (Left, Right : M.Sequence; X, Y : Positive_Count_Type) return Boolean
      renames Model_Ops.M_Elements_Swapped;

      -----------------------
      -- Mapping_Preserved --
      -----------------------

      function Mapping_Preserved
        (M_Left, M_Right : M.Sequence; P_Left, P_Right : P.Map) return Boolean
      renames Model_Ops.Mapping_Preserved;

      -------------------------
      -- P_Positions_Shifted --
      -------------------------

      function P_Positions_Shifted
        (Small, Big : P.Map;
         Cut        : Positive_Count_Type;
         Count      : Count_Type := 1) return Boolean
      renames Model_Ops.P_Positions_Shifted;

      -------------------------
      -- P_Positions_Swapped --
      -------------------------

      function P_Positions_Swapped
        (Left, Right : P.Map; X, Y : Cursor) return Boolean
      renames Model_Ops.P_Positions_Swapped;

      ---------------------------
      -- P_Positions_Truncated --
      ---------------------------

      function P_Positions_Truncated
        (Small, Big : P.Map;
         Cut        : Positive_Count_Type;
         Count      : Count_Type := 1) return Boolean
      renames Model_Ops.P_Positions_Truncated;

   end List_Model;

   -----------
   -- Model --
   -----------

   function Model (Container : List) return M.Sequence
   is (Model_Ops.Model
         (Container.Nodes,
          Container.Elements,
          Container.Free,
          Container.First,
          Container.Last,
          Container.Length));

   ----------
   -- Move --
   ----------

   procedure Move (Target : in out List; Source : in out List) is
      Same : constant Boolean := Same_Object (Target, Source);
   begin
      if Same then
         return;
      end if;

      if Target.Capacity < Source.Length then
         raise Capacity_Error with "Source length exceeds Target capacity";
      end if;

      Ops.Move
        (Target.Nodes,
         Target.Elements,
         Target.Free,
         Target.First,
         Target.Last,
         Target.Length,
         Source.Nodes,
         Source.Elements,
         Source.Free,
         Source.First,
         Source.Last,
         Source.Length);
   end Move;

   ------------------
   -- Move_Element --
   ------------------

   procedure Move_Element
     (Source : in out Relaxed_Element; Target : in out Relaxed_Element) is
   begin
      Target.V := Source.V;
   end Move_Element;

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
      elsif not Has_Element (Container, Position) then
         raise Program_Error
           with "Position cursor designates no element in Container";
      end if;

      return (Node => Container.Nodes (Position.Node).Next);
   end Next;

   ---------------
   -- Positions --
   ---------------

   function Positions (Container : List) return P.Map
   is (Model_Ops.Positions
         (Container.Nodes,
          Container.Free,
          Container.First,
          Container.Last,
          Container.Length));

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
      elsif not Has_Element (Container, Position) then
         raise Program_Error
           with "Position cursor designates no element in Container";
      end if;

      return (Node => Container.Nodes (Position.Node).Prev);
   end Previous;

   -------------
   -- Reclaim --
   -------------

   procedure Reclaim (H : in out Relaxed_Element) is
   begin
      null;
   end Reclaim;

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
      if Position.Node = 0 then
         raise Constraint_Error with "Position cursor has no element";
      elsif not Has_Element (Container, Position) then
         raise Program_Error
           with "Position cursor designates no element in Container";
      end if;

      --  Use an extended return so the borrow is live in the do-block, where
      --  At_End (Container) is meaningful. The borrow can only change the
      --  designated element, never a link, so the active list (from First) and
      --  the free chain (from Free) are unchanged when the borrow ends and the
      --  structural invariant is restored.

      return
         R : constant not null access Element_Type :=
           Container.Elements (Position.Node).V'Access
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
      if Position.Node = 0 then
         raise Constraint_Error with "Position cursor has no element";
      elsif not Has_Element (Container, Position) then
         raise Program_Error
           with "Position cursor designates no element in Container";
      end if;

      Ops.Replace_Element (Container.Elements (Position.Node), New_Item);

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
   begin
      Ops.Reverse_Elements
        (Container.Nodes,
         Container.Free,
         Container.First,
         Container.Last,
         Container.Length);
   end Reverse_Elements;

   ------------------
   -- Reverse_Find --
   ------------------

   function Reverse_Find
     (Container : List; Item : Element_Type; Position : Cursor := No_Element)
      return Cursor is
   begin
      if Position.Node /= 0 and then not Has_Element (Container, Position) then
         raise Program_Error
           with "Position cursor designates no element in Container";
      end if;

      return
        (Node =>
           Ops.Reverse_Find
             (Container.Nodes,
              Container.Elements,
              Container.Free,
              Container.First,
              Container.Last,
              Container.Length,
              Item,
              Position.Node));
   end Reverse_Find;

   ------------
   -- Splice --
   ------------

   procedure Splice
     (Target : in out List; Before : Cursor; Source : in out List)
   is
      Same : constant Boolean := Same_Object (Target, Source);

   begin
      --  Name the volatile aliasing outcome as a pre-state ghost fact so the
      --  Exit_Cases can refer to it (Same_Object cannot appear in a contract).

      pragma Assume (Static => Same = Same_Object_Ghost);

      if Before.Node /= 0 and then not Has_Element (Target, Before) then
         raise Program_Error
           with "Before cursor designates no element in Target";
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

      Ops.Splice
        (Target.Nodes,
         Target.Elements,
         Target.Free,
         Target.First,
         Target.Last,
         Target.Length,
         Source.Nodes,
         Source.Elements,
         Source.Free,
         Source.First,
         Source.Last,
         Source.Length,
         Before.Node);
   end Splice;

   procedure Splice
     (Target   : in out List;
      Before   : Cursor;
      Source   : in out List;
      Position : in out Cursor)
   is
      Same : constant Boolean := Same_Object (Target, Source);

   begin
      --  Name the volatile aliasing outcome as a pre-state ghost fact so the
      --  Exit_Cases can refer to it (Same_Object cannot appear in a contract).

      pragma Assume (Static => Same = Same_Object_Ghost);

      if Same then
         Splice (Target, Before, Position);
         return;
      end if;

      if Position.Node = 0 then
         raise Constraint_Error with "Position cursor has no element";
      elsif not Has_Element (Source, Position) then
         raise Program_Error
           with "Position cursor designates no element in Source";
      end if;

      if Before.Node /= 0 and then not Has_Element (Target, Before) then
         raise Program_Error
           with "Before cursor designates no element in Target";
      end if;

      if Target.Length = Count_Type'Last then
         raise Constraint_Error with "Target exceeds maximum";
      elsif Target.Length >= Target.Capacity then
         raise Capacity_Error with "Target is full";
      end if;

      Ops.Splice
        (Target.Nodes,
         Target.Elements,
         Target.Free,
         Target.First,
         Target.Last,
         Target.Length,
         Source.Nodes,
         Source.Elements,
         Source.Free,
         Source.First,
         Source.Last,
         Source.Length,
         Before.Node,
         Position.Node);
   end Splice;

   procedure Splice
     (Container : in out List; Before : Cursor; Position : Cursor) is
   begin
      if Position.Node = 0 then
         raise Constraint_Error with "Position cursor has no element";
      elsif not Has_Element (Container, Position) then
         raise Program_Error
           with "Position cursor designates no element in Container";
      end if;

      if Before.Node /= 0 and then not Has_Element (Container, Before) then
         raise Program_Error
           with "Before cursor designates no element in Container";
      end if;

      Ops.Splice
        (Container.Nodes,
         Container.Free,
         Container.First,
         Container.Last,
         Container.Length,
         Before.Node,
         Position.Node);
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
         raise Program_Error
           with "I cursor designates no element in Container";
      end if;

      if not Has_Element (Container, J) then
         raise Program_Error
           with "J cursor designates no element in Container";
      end if;

      if I.Node = J.Node then
         return;
      end if;

      Ops.Swap
        (Container.Nodes, Container.Elements, Container.Free, I.Node, J.Node);

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
   begin
      if I.Node = 0 then
         raise Constraint_Error with "I cursor has no element";
      end if;

      if J.Node = 0 then
         raise Constraint_Error with "J cursor has no element";
      end if;

      if not Has_Element (Container, I) then
         raise Program_Error
           with "I cursor designates no element in Container";
      end if;

      if not Has_Element (Container, J) then
         raise Program_Error
           with "J cursor designates no element in Container";
      end if;

      Ops.Swap_Links
        (Container.Nodes,
         Container.Free,
         Container.First,
         Container.Last,
         Container.Length,
         I.Node,
         J.Node);
   end Swap_Links;

end SPARK.Containers.Formal.Doubly_Linked_Lists.Impl;
