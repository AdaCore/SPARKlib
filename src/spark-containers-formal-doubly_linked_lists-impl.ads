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
--  builds; proving this unit relies on body mode (see SPARK.Body_Mode) to
--  expose it in the proof test
--  tests/1376__formal_doubly_linked_lists_impl_proof.
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
with SPARK.Containers.Functional.Infinite_Sequences;
with SPARK.Containers.Functional.Sets;
with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Higher_Order.Reachability;

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

   --  Reachability model over the Next links, used at silver to express
   --  acyclicity of the active and free lists, the node count, the
   --  doubly-linked consistency, and the loop variants for the traversal
   --  loops.

   package Structural_Model
     with Ghost => Static
   is

      package Memory_Index_Sets is new
        SPARK.Containers.Functional.Sets (Positive_Count_Type);

      package Memory_Index_Sequences is new
        SPARK.Containers.Functional.Infinite_Sequences
          (Positive_Count_Type,
           Use_Logical_Equality => True);

      type Nodes_Type_Base is array (Positive_Count_Type range <>) of Node_Type
      with Predicate => (for all N of Nodes_Type_Base => N.Next'Initialized);

      function Next_Link (N : Node_Type) return Count_Type
      is (N.Next)
      with
        Annotate => (GNATprove, Inline_For_Proof),
        Pre      => N.Next'Initialized;

      package Node_Reachability is new
        SPARK.Higher_Order.Reachability
          (Index_Type                            => Positive_Count_Type,
           No_Index                              => 0,
           Cell_Type                             => Node_Type,
           Memory_Type                           => Nodes_Type_Base,
           Next                                  => Next_Link,
           Memory_Index_Sets                     => Memory_Index_Sets,
           Memory_Index_Sequences                => Memory_Index_Sequences,
           Automatically_Instantiate_Definitions => False);

   end Structural_Model;

   use Structural_Model;
   use Structural_Model.Node_Reachability;

   function Memory (Container : List) return Nodes_Type_Base
   is (if Container.Free >= 0
       then Nodes_Type_Base (Container.Nodes)
       else Nodes_Type_Base (Container.Nodes (1 .. -(Container.Free + 1))))
   with Ghost => Static;
   --  The node array as a Positive_Count_Type-indexed memory for the
   --  reachability model. When Free is negative only the touched prefix
   --  (1 .. abs Free - 1) has initialized links, so the never-used tail is
   --  sliced off (Valid_Memory would otherwise read uninitialized Next).

   function Active_Set (Container : List) return Memory_Index_Set
   is (Reachable_Set (Container.First, Memory (Container)))
   with
     Ghost => Static,
     Pre   =>
       Valid_Memory (Memory (Container))
       and then Container.First in Memory (Container)'Range | 0;
   --  The set of nodes on the active list (reachable from First via Next)

   function Active_List_Valid
     (Container : List; Count : Count_Type) return Boolean
   is (Is_Acyclic (Container.First, Memory (Container))

       --  The active list from First is acyclic and has exactly Count nodes

       and then
         Memory_Index_Sets.Length (Active_Set (Container))
         = Big_Conversions.To_Big (Count)

       --  Every node reachable from First is allocated (Prev /= -1) and
       --  doubly linked with its neighbours.

       and then
         (for all I of Active_Set (Container) =>
            Container.Nodes (I).Prev /= -1)
       and then
         (for all I of Active_Set (Container) =>
            (if Container.Nodes (I).Next = 0 then I = Container.Last))
       and then
         (for all I of Active_Set (Container) =>
            (if Container.Nodes (I).Prev = 0
             then I = Container.First
             else
               Memory_Index_Sets.Contains
                 (Active_Set (Container), Container.Nodes (I).Prev)
               and then Container.Nodes (Container.Nodes (I).Prev).Next = I))

       --  First and Last are the endpoints of the active list

       and then
         (if Container.First = 0
          then Container.Last = 0 and Count = 0
          else
            Container.Nodes (Container.First).Prev = 0
            and then Container.Last in Memory (Container)'Range
            and then
              Reachable (Container.First, Memory (Container), Container.Last)
            and then Container.Nodes (Container.Last).Next = 0))
   with
     Ghost => Static,
     Pre   =>
       Valid_Memory (Memory (Container))
       and then Container.First in Memory (Container)'Range | 0;
   --  Structural facts about the active list

   function Free_Chain_Valid
     (Container : List; Excluded : Memory_Index_Set) return Boolean
   is (Container.Free < 0
       or else
         (Is_Acyclic (Container.Free, Memory (Container))
          and then
            (for all I of Reachable_Set (Container.Free, Memory (Container)) =>
               not Memory_Index_Sets.Contains (Excluded, I)
               and then Container.Nodes (I).Prev = -1)))
   with
     Ghost => Static,
     Pre   =>
       Valid_Memory (Memory (Container))
       and then Container.First in Memory (Container)'Range | 0;
   --  Structural part of the free list, without its length: when Free is
   --  non-negative the free nodes form an explicit acyclic chain, each
   --  deallocated (Prev = -1) and outside the Excluded set (the used nodes).
   --  When Free is negative the free nodes are the implicit never-used tail,
   --  so there is no chain to constrain. Kept length-free so the limbo state
   --  between Allocate and Insert_Internal (which has a different count and a
   --  larger used set) can reuse it.

   function Free_Count_Correct
     (Container : List; Used : Count_Type) return Boolean
   is (if Container.Free < 0
       then Container.Free = -Used - 1
       else
         Memory_Index_Sets.Length
           (Reachable_Set (Container.Free, Memory (Container)))
         = Big_Conversions.To_Big (Container.Capacity - Used))
   with
     Ghost => Static,
     Pre   =>
       Valid_Memory (Memory (Container))
       and then Container.First in Memory (Container)'Range | 0;
   --  The free nodes number Capacity - Used, where Used is the number of
   --  touched nodes. When Free is negative the touched region is 1 .. Used, so
   --  Free = -Used - 1 encodes the count directly.

   function Covered (Container : List; Extra : Extended_Index) return Boolean
   is (if Container.Free >= 0
       then
         (for all I in 1 .. Container.Capacity =>
            I = Extra
            or else
              (if Container.Nodes (I).Prev = -1
               then Reachable (Container.Free, Memory (Container), I)
               else Memory_Index_Sets.Contains (Active_Set (Container), I)))
       else
         (for all I in Memory (Container)'Range =>
            I = Extra
            or else Memory_Index_Sets.Contains (Active_Set (Container), I)))
   with
     Ghost => Static,
     Pre   =>
       Valid_Memory (Memory (Container))
       and then Container.First in Memory (Container)'Range | 0;
   --  Partition of the touched region: when Free is negative, every touched
   --  node is then active or the exceptional dangling node Extra (a node in
   --  limbo between the active and free lists; 0 means none). Otherwise, it is
   --  active if its Prev field is positive and free otherwise.

   function Structural_Invariant
     (Container : List; Count : Count_Type) return Boolean
   is (Valid_Memory (Memory (Container))
       and then Container.First in Memory (Container)'Range | 0
       and then Active_List_Valid (Container, Count)
       and then Free_Chain_Valid (Container, Active_Set (Container))
       and then Free_Count_Correct (Container, Count)
       and then Covered (Container, 0))
   with Ghost => Static;
   --  The structural invariant with the active-node count given explicitly as
   --  Count rather than read from Container.Length. Used by the Length-neutral
   --  Insert_*_Node primitives, whose Post is Structural_Invariant (Container,
   --  Count + 1) while Container.Length still holds the pre-insert value; the
   --  caller's single Length write then reconciles the field with the count.

   function Structural_Invariant (Container : List) return Boolean
   is (Structural_Invariant (Container, Container.Length))
   with Ghost => Static;
   --  Silver structural invariant. Carried as Static Pre/Post on the
   --  operations and threaded through their loop invariants/variants.

   function Is_Add
     (S1, S2 : Memory_Index_Set; E : Positive_Count_Type) return Boolean
   is (not Memory_Index_Sets.Contains (S1, E)
       and then Memory_Index_Sets.Contains (S2, E)
       and then Memory_Index_Sets."<=" (S1, S2)
       and then Memory_Index_Sets.Included_Except (S2, S1, E))
   with Ghost => Static;
   --  Return True if S2 is obtained by adding E to S1

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
        others                            =>
          (Exception_Raised => Constraint_Error));

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
        others                            =>
          (Exception_Raised => Constraint_Error));

   procedure Delete
     (Container : in out List; Position : in out Cursor; Count : Count_Type)
   with
     Global     => null,
     Pre        => (Static => Structural_Invariant (Container)),
     Post       => (Static => Structural_Invariant (Container)),
     Exit_Cases =>
       (Has_Element (Container, Position) => Normal_Return,
        others                            =>
          (Exception_Raised => Constraint_Error));

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
       (not Is_Relevant (Target, Before)
        or else
          (Position /= No_Element and then not Has_Element (Source, Position))
        => (Exception_Raised => Program_Error),
        Is_Relevant (Target, Before) and then Position = No_Element
        => (Exception_Raised => Constraint_Error),
        Is_Relevant (Target, Before)
        and then Position /= No_Element
        and then Has_Element (Source, Position)
        and then not Same_Object_Ghost
        and then Exceeds_Count_Type (Length (Target), 1)
        => (Exception_Raised => Constraint_Error),
        Is_Relevant (Target, Before)
        and then Position /= No_Element
        and then Has_Element (Source, Position)
        and then not Same_Object_Ghost
        and then Exceeds_Capacity (Length (Target), Target.Capacity, 1)
        => (Exception_Raised => Capacity_Error),
        others
        => Normal_Return);

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
       (not Is_Relevant (Container, Before)
        or not Is_Relevant (Container, Position)                       =>
          (Exception_Raised => Program_Error),
        Is_Relevant (Container, Before) and then Position = No_Element =>
          (Exception_Raised => Constraint_Error),
        others                                                         =>
          Normal_Return);

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
