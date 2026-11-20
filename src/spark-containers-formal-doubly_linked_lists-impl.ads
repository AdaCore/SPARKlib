--
--  Copyright (C) 2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Silver-level (absence of run-time errors) implementation of
--  SPARK.Containers.Formal.Doubly_Linked_Lists. This private generic child
--  carries all the operations of the bounded list in SPARK_Mode => On,
--  working on the parent's List type rather than redefining the
--  representation. That representation lives in the private part of
--  Formal.Doubly_Linked_Lists, which is hidden from analysis in normal
--  builds; proving this unit relies on body mode (see SPARKlib_Config) to
--  expose it in the proof test
--  tests/library_proof/formal_doubly_linked_lists.
--
--  It carries no gold (model-based) postconditions, only what silver needs:
--  the non-model preconditions guarding implicit run-time errors, the
--  Exit_Cases documenting explicit raises, and the cheap structural facts
--  carried in the type. It does include the runtime-executable model
--  functions (Model and Positions, at level SPARKlib_Logic), which are
--  intended to be proved run-time-error-free too.
--
--  The aliasing guards that raise Program_Error when two container parameters
--  denote the same object are left out of the Exit_Cases: they are unreachable
--  in SPARK (an in out and an in/in out parameter cannot alias) and rely on
--  the volatile Same_Object function, which cannot appear in a contract. They
--  are justified at proof time and documented with a comment.

pragma Ada_2022;

with SPARK.Containers.Formal.Impl.Address_Space;
with SPARK.Containers.Types; use SPARK.Containers.Types;

private generic
package SPARK.Containers.Formal.Doubly_Linked_Lists.Impl with
    SPARK_Mode,
    Always_Terminates
is

   use SPARK.Containers.Formal.Impl.Address_Space;

   Same_Object_Ghost : Boolean := False
   with Ghost => Static;
   --  Ghost proxy for the address-identity outcome of the aliasing
   --  short-circuits. Same_Object is a Volatile_Function and so cannot appear
   --  in a contract; an operation that short-circuits on aliasing assumes this
   --  variable equals its Same_Object result -- a pre-state fact (whether the
   --  two arguments denote the same object) -- so that its Exit_Cases can name
   --  it. It is only ever read, never assigned, and each assume is local to
   --  one operation, so no cross-operation constraint is introduced.

   -------------------------------
   -- Structural (ghost) model  --
   -------------------------------

   --  Bounded views of the shared structural model. The predicates retain
   --  record-based interfaces and delegate to Storage's link-array model.

   package Structural_Model renames Storage.Structural_Model;

   use Structural_Model;
   use Structural_Model.Node_Reachability;

   function Memory (Container : List) return Nodes_Type_Base
   is (Storage.Memory (Container.Nodes, Container.Free))
   with Ghost => Static, Annotate => (GNATprove, Inline_For_Proof);
   --  Shared link memory restricted to the container's touched prefix

   function Active_Set (Container : List) return Memory_Index_Set
   is (Storage.Active_Set (Container.Nodes, Container.Free, Container.First))
   with
     Ghost    => Static,
     Annotate => (GNATprove, Inline_For_Proof),
     Pre      =>
       Valid_Memory (Memory (Container))
       and then Container.First in Memory (Container)'Range | 0;
   --  The shared active-node set for the bounded container

   function Active_List_Valid
     (Container : List; Count : Count_Type) return Boolean
   is (Storage.Active_List_Valid
         (Container.Nodes,
          Container.Free,
          Container.First,
          Container.Last,
          Count))
   with
     Ghost    => Static,
     Annotate => (GNATprove, Inline_For_Proof),
     Pre      =>
       Valid_Memory (Memory (Container))
       and then Container.First in Memory (Container)'Range | 0;
   --  The shared structural predicate for the active list

   function Free_Chain_Valid
     (Container : List; Excluded : Memory_Index_Set) return Boolean
   is (Storage.Free_Chain_Valid (Container.Nodes, Container.Free, Excluded))
   with
     Ghost    => Static,
     Annotate => (GNATprove, Inline_For_Proof),
     Pre      =>
       Valid_Memory (Memory (Container))
       and then Container.First in Memory (Container)'Range | 0;
   --  The shared free-chain predicate, excluding the supplied node set

   function Free_Count_Correct
     (Container : List; Used : Count_Type) return Boolean
   is (Storage.Free_Count_Correct (Container.Nodes, Container.Free, Used))
   with
     Ghost    => Static,
     Annotate => (GNATprove, Inline_For_Proof),
     Pre      =>
       Valid_Memory (Memory (Container))
       and then Container.First in Memory (Container)'Range | 0;
   --  The shared free-storage cardinality constraint for Used active nodes

   function Covered (Container : List; Extra : Extended_Index) return Boolean
   is (Storage.Covered
         (Container.Nodes, Container.Free, Container.First, Extra))
   with
     Ghost    => Static,
     Annotate => (GNATprove, Inline_For_Proof),
     Pre      =>
       Valid_Memory (Memory (Container))
       and then Container.First in Memory (Container)'Range | 0;
   --  Shared coverage of touched nodes, with Extra naming a detached node.

   function Structural_Invariant
     (Container : List; Count : Count_Type) return Boolean
   is (Storage.Structural_Invariant
         (Container.Nodes,
          Container.Free,
          Container.First,
          Container.Last,
          Count))
   with Ghost => Static, Annotate => (GNATprove, Inline_For_Proof);
   --  The shared structural invariant with an explicit active-node count

   function Structural_Invariant (Container : List) return Boolean
   is (Structural_Invariant (Container, Container.Length))
   with Ghost => Static, Annotate => (GNATprove, Inline_For_Proof);
   --  The shared structural invariant at the container's current length

   function Is_Add
     (S1, S2 : Memory_Index_Set; E : Positive_Count_Type) return Boolean
   renames Storage.Is_Add;
   --  The shared predicate for adding exactly E to S1

   package List_Model
     with Ghost => SPARKlib_Logic
   is

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

      function P_Positions_Shifted
        (Small, Big : P.Map;
         Cut        : Positive_Count_Type;
         Count      : Count_Type := 1) return Boolean
      with Global => null;

      function P_Positions_Swapped
        (Left, Right : P.Map; X, Y : Cursor) return Boolean
      with Global => null;

      function P_Positions_Truncated
        (Small, Big : P.Map;
         Cut        : Positive_Count_Type;
         Count      : Count_Type := 1) return Boolean
      with Global => null;

   end List_Model;
   --  Shared model predicates exposed to the public model delegation body

   --  Runtime-executable model functions (proved run-time-error-free)

   function Model (Container : List) return Formal_Model.M.Sequence
   with
     Ghost => SPARKlib_Logic,
     Pre   => (Static => Structural_Invariant (Container));

   function Positions (Container : List) return Formal_Model.P.Map
   with
     Ghost => SPARKlib_Logic,
     Pre   => (Static => Structural_Invariant (Container));

   --  Queries. Declared first so the contracts of the operations below may
   --  refer to them.

   function Has_Element (Container : List; Position : Cursor) return Boolean
   with
     Global => null,
     Pre    => (Static => Structural_Invariant (Container)),
     Post   =>
       (Static =>
          Has_Element'Result
          = (Position /= No_Element
             and then
               Memory_Index_Sets.Contains
                 (Active_Set (Container), Position.Node)));

   --  The following ghost helpers express, without any model, the exact
   --  conditions under which the operations raise an exception. They are used
   --  in the Exit_Cases below so that those contracts state precisely when,
   --  and which, exception is raised.

   function Is_Relevant (Container : List; Position : Cursor) return Boolean
   is (Position = No_Element or else Has_Element (Container, Position))
   with Ghost => Static, Pre => Structural_Invariant (Container);
   --  Position is a cursor which is relevant for Container: it is No_Element
   --  or it designates an element in Container.

   function Exceeds_Count_Type
     (Length : Count_Type; Count : Count_Type) return Boolean
   is (Count > 0 and then Length > Count_Type'Last - Count)
   with Ghost => Static;
   --  Inserting Count items would push the length past the maximum length
   --  Count_Type'Last, which raises Constraint_Error.

   function Exceeds_Capacity
     (Length : Count_Type; Capacity : Count_Type; Count : Count_Type)
      return Boolean
   is (Count > 0
       and then Length <= Count_Type'Last - Count
       and then Length > Capacity - Count)
   with Ghost => Static;
   --  Inserting Count items fits within Count_Type but exceeds the allocated
   --  capacity, which raises Capacity_Error.

   function First (Container : List) return Cursor
   with Global => null;

   function Last (Container : List) return Cursor
   with Global => null;

   function "=" (Left, Right : List) return Boolean
   with
     Volatile_Function,
     Global => Address_State,
     Pre    =>
       (Static =>
          Structural_Invariant (Left) and then Structural_Invariant (Right));

   function Empty_List (Capacity : Count_Type := 10) return List
   with
     Global => null,
     Post   => (Static => Structural_Invariant (Empty_List'Result));

   procedure Clear (Container : in out List)
   with
     Global => null,
     Pre    => (Static => Structural_Invariant (Container)),
     Post   =>
       (Static =>
          Structural_Invariant (Container) and then Length (Container) = 0);

   procedure Assign (Target : in out List; Source : List)
   with
     Global     => Address_State,
     Pre        =>
       (Static =>
          Structural_Invariant (Target)
          and then Structural_Invariant (Source)),
     Post       => (Static => Structural_Invariant (Target)),
     Exit_Cases =>
       (Length (Source) > Target.Capacity =>
          (Exception_Raised => Capacity_Error),
        others                            => Normal_Return);

   function Copy (Source : List; Capacity : Count_Type := 0) return List
   with
     Side_Effects,
     Global     => null,
     Pre        => (Static => Structural_Invariant (Source)),
     Post       => (Static => Structural_Invariant (Copy'Result)),
     Exit_Cases =>
       (Capacity /= 0 and then Capacity < Length (Source) =>
          (Exception_Raised => Capacity_Error),
        others                                            => Normal_Return);

   procedure Move (Target : in out List; Source : in out List)
   with
     Global     => Address_State,
     Pre        =>
       (Static =>
          Structural_Invariant (Target)
          and then Structural_Invariant (Source)),
     Post       =>
       (Static =>
          Structural_Invariant (Target)
          and then Structural_Invariant (Source)),
     Exit_Cases =>
       (Length (Source) > Target.Capacity =>
          (Exception_Raised => Capacity_Error),
        others                            => Normal_Return);

   function Element (Container : List; Position : Cursor) return Element_Type
   with
     Pre        => (Static => Structural_Invariant (Container)),
     Side_Effects,
     Global     => null,
     Exit_Cases =>
       (Has_Element (Container, Position) => Normal_Return,
        Position = No_Element             =>
          (Exception_Raised => Constraint_Error),
        others                            =>
          (Exception_Raised => Program_Error));

   procedure Replace_Element
     (Container : in out List; Position : Cursor; New_Item : Element_Type)
   with
     Global     => null,
     Pre        => (Static => Structural_Invariant (Container)),
     Post       => (Static => Structural_Invariant (Container)),
     Exit_Cases =>
       (Has_Element (Container, Position) => Normal_Return,
        Position = No_Element             =>
          (Exception_Raised => Constraint_Error),
        others                            =>
          (Exception_Raised => Program_Error));

   function At_End (E : List) return List
   is (E)
   with Ghost => Static, Annotate => (GNATprove, At_End_Borrow);
   --  The value of the borrowed container when the borrow expires; used to
   --  state that Reference restores the structural invariant at that point.

   function Constant_Reference
     (Container : aliased List; Position : Cursor)
      return not null access constant Element_Type
   with
     Global => null,
     Pre    =>
       (Static =>
          Structural_Invariant (Container)
          and then Has_Element (Container, Position));

   function Reference
     (Container : aliased in out List; Position : Cursor)
      return not null access Element_Type
   with
     Global => null,
     Pre    =>
       (Static =>
          Structural_Invariant (Container)
          and then Has_Element (Container, Position)),
     Post   => (Static => Structural_Invariant (At_End (Container)));

   procedure Insert
     (Container : in out List;
      Before    : Cursor;
      New_Item  : Element_Type;
      Count     : Count_Type)
   with
     Global     => null,
     Pre        => (Static => Structural_Invariant (Container)),
     Post       =>
       (Static =>
          Structural_Invariant (Container)
          and then Length (Container) = Length (Container'Old) + Count),
     Exit_Cases =>
       (not Is_Relevant (Container, Before)                                =>
          (Exception_Raised => Program_Error),
        Is_Relevant (Container, Before)
        and then Exceeds_Count_Type (Length (Container), Count)            =>
          (Exception_Raised => Constraint_Error),
        Is_Relevant (Container, Before)
        and then
          Exceeds_Capacity (Length (Container), Container.Capacity, Count) =>
          (Exception_Raised => Capacity_Error),
        others                                                             =>
          Normal_Return);

   procedure Insert
     (Container : in out List; Before : Cursor; New_Item : Element_Type)
   with
     Global     => null,
     Pre        => (Static => Structural_Invariant (Container)),
     Post       =>
       (Static =>
          Structural_Invariant (Container)
          and then Length (Container) = Length (Container'Old) + 1
          and then Is_Relevant (Container, Before)),
     Exit_Cases =>
       (not Is_Relevant (Container, Before)
        => (Exception_Raised => Program_Error),
        Is_Relevant (Container, Before)
        and then Exceeds_Count_Type (Length (Container), 1)
        => (Exception_Raised => Constraint_Error),
        Is_Relevant (Container, Before)
        and then Exceeds_Capacity (Length (Container), Container.Capacity, 1)
        => (Exception_Raised => Capacity_Error),
        others
        => Normal_Return);

   procedure Insert
     (Container : in out List;
      Before    : Cursor;
      New_Item  : Element_Type;
      Position  : out Cursor;
      Count     : Count_Type)
   with
     Inline,
     Global     => null,
     Pre        => (Static => Structural_Invariant (Container)),
     Post       =>
       (Static =>
          Structural_Invariant (Container)
          and then Length (Container) = Length (Container'Old) + Count
          and then Is_Relevant (Container, Before)),
     Exit_Cases =>
       (not Is_Relevant (Container, Before)                                =>
          (Exception_Raised => Program_Error),
        Is_Relevant (Container, Before)
        and then Exceeds_Count_Type (Length (Container), Count)            =>
          (Exception_Raised => Constraint_Error),
        Is_Relevant (Container, Before)
        and then
          Exceeds_Capacity (Length (Container), Container.Capacity, Count) =>
          (Exception_Raised => Capacity_Error),
        others                                                             =>
          Normal_Return);

   procedure Insert
     (Container : in out List;
      Before    : Cursor;
      New_Item  : Element_Type;
      Position  : out Cursor)
   with
     Global     => null,
     Pre        => (Static => Structural_Invariant (Container)),
     Post       =>
       (Static =>
          Structural_Invariant (Container)
          and then Length (Container) = Length (Container'Old) + 1
          and then Is_Relevant (Container, Before)),
     Exit_Cases =>
       (not Is_Relevant (Container, Before)
        => (Exception_Raised => Program_Error),
        Is_Relevant (Container, Before)
        and then Exceeds_Count_Type (Length (Container), 1)
        => (Exception_Raised => Constraint_Error),
        Is_Relevant (Container, Before)
        and then Exceeds_Capacity (Length (Container), Container.Capacity, 1)
        => (Exception_Raised => Capacity_Error),
        others
        => Normal_Return);

   procedure Prepend (Container : in out List; New_Item : Element_Type)
   with
     Global     => null,
     Pre        => (Static => Structural_Invariant (Container)),
     Post       => (Static => Structural_Invariant (Container)),
     Exit_Cases =>
       (Exceeds_Count_Type (Length (Container), 1)                   =>
          (Exception_Raised => Constraint_Error),
        Exceeds_Capacity (Length (Container), Container.Capacity, 1) =>
          (Exception_Raised => Capacity_Error),
        others                                                       =>
          Normal_Return);

   procedure Prepend
     (Container : in out List; New_Item : Element_Type; Count : Count_Type)
   with
     Global     => null,
     Pre        => (Static => Structural_Invariant (Container)),
     Post       => (Static => Structural_Invariant (Container)),
     Exit_Cases =>
       (Exceeds_Count_Type (Length (Container), Count)                   =>
          (Exception_Raised => Constraint_Error),
        Exceeds_Capacity (Length (Container), Container.Capacity, Count) =>
          (Exception_Raised => Capacity_Error),
        others                                                           =>
          Normal_Return);

   procedure Append (Container : in out List; New_Item : Element_Type)
   with
     Global     => null,
     Pre        => (Static => Structural_Invariant (Container)),
     Post       =>
       (Static =>
          Structural_Invariant (Container)
          and then Length (Container) = Length (Container'Old) + 1),
     Exit_Cases =>
       (Exceeds_Count_Type (Length (Container), 1)                   =>
          (Exception_Raised => Constraint_Error),
        Exceeds_Capacity (Length (Container), Container.Capacity, 1) =>
          (Exception_Raised => Capacity_Error),
        others                                                       =>
          Normal_Return);

   procedure Append
     (Container : in out List; New_Item : Element_Type; Count : Count_Type)
   with
     Global     => null,
     Pre        => (Static => Structural_Invariant (Container)),
     Post       =>
       (Static =>
          Structural_Invariant (Container)
          and then Length (Container) = Length (Container'Old) + Count),
     Exit_Cases =>
       (Exceeds_Count_Type (Length (Container), Count)                   =>
          (Exception_Raised => Constraint_Error),
        Exceeds_Capacity (Length (Container), Container.Capacity, Count) =>
          (Exception_Raised => Capacity_Error),
        others                                                           =>
          Normal_Return);

   procedure Delete (Container : in out List; Position : in out Cursor)
   with
     Global     => null,
     Pre        => (Static => Structural_Invariant (Container)),
     Post       =>
       (Static =>
          Structural_Invariant (Container)

          --  Deleting takes exactly Position's node off the active list, so a
          --  caller keeps any other cursor valid across the call (Splice
          --  relies on it, and Merge in turn on Splice).

          and then Length (Container) = Length (Container'Old) - 1
          and then
            Is_Add
              (Active_Set (Container),
               Active_Set (Container'Old),
               Position'Old.Node)),
     Exit_Cases =>
       (Has_Element (Container, Position) => Normal_Return,
        Position = No_Element             =>
          (Exception_Raised => Constraint_Error),
        others                            =>
          (Exception_Raised => Program_Error));

   procedure Delete
     (Container : in out List; Position : in out Cursor; Count : Count_Type)
   with
     Global     => null,
     Pre        => (Static => Structural_Invariant (Container)),
     Post       => (Static => Structural_Invariant (Container)),
     Exit_Cases =>
       (Has_Element (Container, Position) => Normal_Return,
        Position = No_Element             =>
          (Exception_Raised => Constraint_Error),
        others                            =>
          (Exception_Raised => Program_Error));

   procedure Delete_First (Container : in out List)
   with
     Global => null,
     Pre    => (Static => Structural_Invariant (Container)),
     Post   => (Static => Structural_Invariant (Container));

   procedure Delete_First (Container : in out List; Count : Count_Type)
   with
     Global => null,
     Pre    => (Static => Structural_Invariant (Container)),
     Post   => (Static => Structural_Invariant (Container));

   procedure Delete_Last (Container : in out List)
   with
     Global => null,
     Pre    => (Static => Structural_Invariant (Container)),
     Post   => (Static => Structural_Invariant (Container));

   procedure Delete_Last (Container : in out List; Count : Count_Type)
   with
     Global => null,
     Pre    => (Static => Structural_Invariant (Container)),
     Post   => (Static => Structural_Invariant (Container));

   procedure Reverse_Elements (Container : in out List)
   with
     Global => null,
     Pre    => (Static => Structural_Invariant (Container)),
     Post   => (Static => Structural_Invariant (Container));

   procedure Swap (Container : in out List; I : Cursor; J : Cursor)
   with
     Global     => null,
     Pre        => (Static => Structural_Invariant (Container)),
     Post       => (Static => Structural_Invariant (Container)),
     Exit_Cases =>
       (I = No_Element or else J = No_Element                             =>
          (Exception_Raised => Constraint_Error),
        (not Is_Relevant (Container, I) and then J /= No_Element)
        or else (not Is_Relevant (Container, J) and then I /= No_Element) =>
          (Exception_Raised => Program_Error),
        others                                                            =>
          Normal_Return);

   procedure Swap_Links (Container : in out List; I : Cursor; J : Cursor)
   with
     Global     => null,
     Pre        => (Static => Structural_Invariant (Container)),
     Post       => (Static => Structural_Invariant (Container)),
     Exit_Cases =>
       (I = No_Element or J = No_Element                                  =>
          (Exception_Raised => Constraint_Error),
        (not Is_Relevant (Container, I) and then J /= No_Element)
        or else (not Is_Relevant (Container, J) and then I /= No_Element) =>
          (Exception_Raised => Program_Error),
        others                                                            =>
          Normal_Return);

   procedure Splice
     (Target : in out List; Before : Cursor; Source : in out List)
   with
     Global     => (Input => Address_State, Proof_In => Same_Object_Ghost),
     Pre        =>
       (Static =>
          Structural_Invariant (Target)
          and then Structural_Invariant (Source)),
     Post       =>
       (Static =>
          Structural_Invariant (Target)
          and then Structural_Invariant (Source)),
     Exit_Cases =>
       (not Is_Relevant (Target, Before)
        => (Exception_Raised => Program_Error),
        Is_Relevant (Target, Before)
        and then not Same_Object_Ghost
        and then Exceeds_Count_Type (Length (Target), Length (Source))
        => (Exception_Raised => Constraint_Error),
        Is_Relevant (Target, Before)
        and then not Same_Object_Ghost
        and then
          Exceeds_Capacity (Length (Target), Target.Capacity, Length (Source))
        => (Exception_Raised => Capacity_Error),
        others
        => Normal_Return);

   procedure Splice
     (Target   : in out List;
      Before   : Cursor;
      Source   : in out List;
      Position : in out Cursor)
   with
     Global     => (Input => Address_State, Proof_In => Same_Object_Ghost),
     Pre        =>
       (Static =>
          Structural_Invariant (Target)
          and then Structural_Invariant (Source)),
     Post       =>
       (Static =>
          Structural_Invariant (Target)
          and then Structural_Invariant (Source)

          --  Moving a node from Source to Target adds exactly one element to
          --  Target and takes exactly Position's node off Source, so a caller
          --  keeps both its Before cursor in Target and any other cursor in
          --  Source valid across the call (Merge relies on both). Nothing of
          --  the kind holds on the aliased path, which relinks a single list.

          and then
            (if not Same_Object_Ghost
             then
               Length (Target) = Length (Target'Old) + 1
               and then Length (Source) = Length (Source'Old) - 1
               and then Is_Relevant (Target, Before)
               and then
                 Is_Add
                   (Active_Set (Source),
                    Active_Set (Source'Old),
                    Position'Old.Node))),
     Exit_Cases =>
       (Position = No_Element                                           =>
          (Exception_Raised => Constraint_Error),
        Position /= No_Element
        and then
          (not Is_Relevant (Target, Before)
           or else not Has_Element (Source, Position))                  =>
          (Exception_Raised => Program_Error),
        Is_Relevant (Target, Before)
        and then Position /= No_Element
        and then Has_Element (Source, Position)
        and then not Same_Object_Ghost
        and then Exceeds_Count_Type (Length (Target), 1)                =>
          (Exception_Raised => Constraint_Error),
        Is_Relevant (Target, Before)
        and then Position /= No_Element
        and then Has_Element (Source, Position)
        and then not Same_Object_Ghost
        and then Exceeds_Capacity (Length (Target), Target.Capacity, 1) =>
          (Exception_Raised => Capacity_Error),
        others                                                          =>
          Normal_Return);

   procedure Splice
     (Container : in out List; Before : Cursor; Position : Cursor)
   with
     Global     => null,
     Pre        => (Static => Structural_Invariant (Container)),
     Post       =>
       (Static =>
          Structural_Invariant (Container)

          --  Splice relinks nodes but neither adds nor removes any, so the
          --  active set is preserved. This lets a caller transfer a cursor's
          --  active-set membership (hence its validity) across the call.

          and then
            Memory_Index_Sets."="
              (Active_Set (Container), Active_Set (Container'Old))),
     Exit_Cases =>
       (Position = No_Element                             =>
          (Exception_Raised => Constraint_Error),
        Position /= No_Element
        and then
          (not Is_Relevant (Container, Before)
           or else not Is_Relevant (Container, Position)) =>
          (Exception_Raised => Program_Error),
        others                                            => Normal_Return);

   function First_Element (Container : List) return Element_Type
   with
     Pre        => (Static => Structural_Invariant (Container)),
     Side_Effects,
     Global     => null,
     Exit_Cases =>
       (not Is_Empty (Container) => Normal_Return,
        others                   => (Exception_Raised => Constraint_Error));

   function Last_Element (Container : List) return Element_Type
   with
     Pre        => (Static => Structural_Invariant (Container)),
     Side_Effects,
     Global     => null,
     Exit_Cases =>
       (not Is_Empty (Container) => Normal_Return,
        others                   => (Exception_Raised => Constraint_Error));

   function Next (Container : List; Position : Cursor) return Cursor
   with
     Pre        => (Static => Structural_Invariant (Container)),
     Side_Effects,
     Global     => null,
     Exit_Cases =>
       (Is_Relevant (Container, Position) => Normal_Return,
        others                            =>
          (Exception_Raised => Program_Error));

   procedure Next (Container : List; Position : in out Cursor)
   with
     Pre        => (Static => Structural_Invariant (Container)),
     Global     => null,
     Exit_Cases =>
       (Is_Relevant (Container, Position) => Normal_Return,
        others                            =>
          (Exception_Raised => Program_Error));

   function Previous (Container : List; Position : Cursor) return Cursor
   with
     Pre        => (Static => Structural_Invariant (Container)),
     Side_Effects,
     Global     => null,
     Exit_Cases =>
       (Is_Relevant (Container, Position) => Normal_Return,
        others                            =>
          (Exception_Raised => Program_Error));

   procedure Previous (Container : List; Position : in out Cursor)
   with
     Pre        => (Static => Structural_Invariant (Container)),
     Global     => null,
     Exit_Cases =>
       (Is_Relevant (Container, Position) => Normal_Return,
        others                            =>
          (Exception_Raised => Program_Error));

   function Find
     (Container : List; Item : Element_Type; Position : Cursor := No_Element)
      return Cursor
   with
     Pre        => (Static => Structural_Invariant (Container)),
     Side_Effects,
     Global     => null,
     Exit_Cases =>
       (Is_Relevant (Container, Position) => Normal_Return,
        others                            =>
          (Exception_Raised => Program_Error));

   function Reverse_Find
     (Container : List; Item : Element_Type; Position : Cursor := No_Element)
      return Cursor
   with
     Pre        => (Static => Structural_Invariant (Container)),
     Side_Effects,
     Global     => null,
     Exit_Cases =>
       (Is_Relevant (Container, Position) => Normal_Return,
        others                            =>
          (Exception_Raised => Program_Error));

   function Contains (Container : List; Item : Element_Type) return Boolean
   with Global => null, Pre => (Static => Structural_Invariant (Container));

   generic
      with function "<" (Left, Right : Element_Type) return Boolean is <>;
   package Generic_Sorting with SPARK_Mode, Always_Terminates is

      function Is_Sorted (Container : List) return Boolean
      with Global => null, Pre => (Static => Structural_Invariant (Container));

      procedure Sort (Container : in out List)
      with
        Global => null,
        Pre    => (Static => Structural_Invariant (Container)),
        Post   =>
          (Static =>
             Structural_Invariant (Container)
             and then Length (Container) = Length (Container'Old));

      procedure Merge (Target : in out List; Source : in out List)
      with
        Global     =>
          (Input    =>
             SPARK.Containers.Formal.Impl.Address_Space.Address_State,
           Proof_In => Same_Object_Ghost),
        Pre        =>
          (Static =>
             Structural_Invariant (Target)
             and then Structural_Invariant (Source)),
        Post       =>
          (Static =>
             Structural_Invariant (Target)
             and then Structural_Invariant (Source)),
        Exit_Cases =>
          (Exceeds_Count_Type (Length (Target), Length (Source))
           => (Exception_Raised => Constraint_Error),
           Exceeds_Capacity (Length (Target), Target.Capacity, Length (Source))
           => (Exception_Raised => Capacity_Error),
           others
           => Normal_Return);
      pragma
        Annotate
          (GNATprove,
           Intentional,
           "exit case might fail",
           "unreachable in SPARK: on the aliased path Merge raises "
           & "Program_Error instead, and two in out parameters cannot alias");
      --  May also raise Program_Error when Target and Source denote the same
      --  object; that guard is unreachable in SPARK (two in out parameters
      --  cannot alias) and relies on the volatile Same_Object function, which
      --  cannot appear in a contract.
   end Generic_Sorting;

end SPARK.Containers.Formal.Doubly_Linked_Lists.Impl;
