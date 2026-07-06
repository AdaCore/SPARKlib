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
--  Formal.Doubly_Linked_Lists, which is SPARK_Mode => Off in normal builds;
--  proving this unit relies on the body-mode mechanism (the #BODYMODE
--  annotations and sparklib_bodymode) to switch it On in the proof test
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
with SPARK.Containers.Types; use SPARK.Containers.Types;

private generic
package SPARK.Containers.Formal.Doubly_Linked_Lists.Impl with
    SPARK_Mode,
    Always_Terminates
is

   use SPARK.Containers.Formal.Impl.Address_Space;

   --  Runtime-executable model functions (proved run-time-error-free).

   function Model (Container : List) return Formal_Model.M.Sequence
   with Ghost => SPARKlib_Logic;

   function Positions (Container : List) return Formal_Model.P.Map
   with Ghost => SPARKlib_Logic;

   --  Queries. Declared first so the contracts of the operations below may
   --  refer to them.

   function Length (Container : List) return Count_Type
   with Global => null;

   function Is_Empty (Container : List) return Boolean
   with Global => null;

   function Has_Element (Container : List; Position : Cursor) return Boolean
   with Global => null;

   --  The following ghost helpers express, without any model, the exact
   --  conditions under which the insertion operations raise en exception. They
   --  are used in the Exit_Cases below so that those contracts state precisely
   --  when, and which, exception is raised.

   function Is_Relevant (Container : List; Position : Cursor) return Boolean
   is (Position = No_Element or else Has_Element (Container, Position))
   with Ghost => Static;
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
   with Volatile_Function, Global => Address_State;

   function Empty_List (Capacity : Count_Type := 10) return List
   with Global => null;

   procedure Clear (Container : in out List)
   with Global => null;

   procedure Assign (Target : in out List; Source : List)
   with
     Global     => Address_State,
     Exit_Cases =>
       (Length (Source) > Target.Capacity =>
          (Exception_Raised => Capacity_Error),
        others                            => Normal_Return);

   function Copy (Source : List; Capacity : Count_Type := 0) return List
   with
     Side_Effects,
     Global     => null,
     Exit_Cases =>
       (Capacity /= 0 and then Capacity < Length (Source) =>
          (Exception_Raised => Capacity_Error),
        others                                            => Normal_Return);

   procedure Move (Target : in out List; Source : in out List)
   with
     Global     => Address_State,
     Exit_Cases =>
       (Length (Source) > Target.Capacity =>
          (Exception_Raised => Capacity_Error),
        others                            => Normal_Return);

   function Element (Container : List; Position : Cursor) return Element_Type
   with
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
     Exit_Cases =>
       (Has_Element (Container, Position) => Normal_Return,
        Position = No_Element             =>
          (Exception_Raised => Constraint_Error),
        others                            =>
          (Exception_Raised => Program_Error));

   function Constant_Reference
     (Container : aliased List; Position : Cursor)
      return not null access constant Element_Type
   with Global => null, Pre => (Static => Has_Element (Container, Position));

   function Reference
     (Container : aliased in out List; Position : Cursor)
      return not null access Element_Type
   with Global => null, Pre => (Static => Has_Element (Container, Position));

   procedure Insert
     (Container : in out List;
      Before    : Cursor;
      New_Item  : Element_Type;
      Count     : Count_Type)
   with
     Global     => null,
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
     Exit_Cases =>
       (Exceeds_Capacity (Length (Container), Container.Capacity, 1) =>
          (Exception_Raised => Constraint_Error),
        others                                                       =>
          Normal_Return);

   procedure Prepend
     (Container : in out List; New_Item : Element_Type; Count : Count_Type)
   with
     Global     => null,
     Exit_Cases =>
       (Exceeds_Capacity (Length (Container), Container.Capacity, Count) =>
          (Exception_Raised => Constraint_Error),
        others                                                           =>
          Normal_Return);

   procedure Append (Container : in out List; New_Item : Element_Type)
   with
     Global     => null,
     Exit_Cases =>
       (Exceeds_Capacity (Length (Container), Container.Capacity, 1) =>
          (Exception_Raised => Constraint_Error),
        others                                                       =>
          Normal_Return);

   procedure Append
     (Container : in out List; New_Item : Element_Type; Count : Count_Type)
   with
     Global     => null,
     Exit_Cases =>
       (Exceeds_Capacity (Length (Container), Container.Capacity, Count) =>
          (Exception_Raised => Constraint_Error),
        others                                                           =>
          Normal_Return);

   procedure Delete (Container : in out List; Position : in out Cursor)
   with
     Global     => null,
     Exit_Cases =>
       (Has_Element (Container, Position) => Normal_Return,
        others                            =>
          (Exception_Raised => Constraint_Error));

   procedure Delete
     (Container : in out List; Position : in out Cursor; Count : Count_Type)
   with
     Global     => null,
     Exit_Cases =>
       (Has_Element (Container, Position) => Normal_Return,
        others                            =>
          (Exception_Raised => Constraint_Error));

   procedure Delete_First (Container : in out List)
   with Global => null;

   procedure Delete_First (Container : in out List; Count : Count_Type)
   with Global => null;

   procedure Delete_Last (Container : in out List)
   with Global => null;

   procedure Delete_Last (Container : in out List; Count : Count_Type)
   with Global => null;

   procedure Reverse_Elements (Container : in out List)
   with Global => null;

   procedure Swap (Container : in out List; I : Cursor; J : Cursor)
   with
     Global     => null,
     Exit_Cases =>
       (I = No_Element or J = No_Element                                 =>
          (Exception_Raised => Constraint_Error),
        not Is_Relevant (Container, I) or not Is_Relevant (Container, J) =>
          (Exception_Raised => Program_Error),
        others                                                           =>
          Normal_Return);

   procedure Swap_Links (Container : in out List; I : Cursor; J : Cursor)
   with
     Global     => null,
     Exit_Cases =>
       (I = No_Element or J = No_Element                                 =>
          (Exception_Raised => Constraint_Error),
        not Is_Relevant (Container, I) or not Is_Relevant (Container, J) =>
          (Exception_Raised => Program_Error),
        others                                                           =>
          Normal_Return);

   procedure Splice
     (Target : in out List; Before : Cursor; Source : in out List)
   with
     Global     => Address_State,
     Exit_Cases =>
       (not Is_Relevant (Target, Before)
        => (Exception_Raised => Program_Error),
        Is_Relevant (Target, Before)
        and Exceeds_Count_Type (Length (Target), Length (Source))
        => (Exception_Raised => Constraint_Error),
        Is_Relevant (Target, Before)
        and
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
     Global     => Address_State,
     Exit_Cases =>
       (not Is_Relevant (Target, Before) or not Is_Relevant (Target, Before) =>
          (Exception_Raised => Program_Error),
        Is_Relevant (Target, Before) and then Position = No_Element          =>
          (Exception_Raised => Constraint_Error),
        Is_Relevant (Target, Before)
        and then Position /= No_Element
        and then Has_Element (Source, Position)
        and then Exceeds_Count_Type (Length (Target), 1)                     =>
          (Exception_Raised => Constraint_Error),
        Is_Relevant (Target, Before)
        and then Position /= No_Element
        and then Has_Element (Source, Position)
        and then Exceeds_Count_Type (Length (Target), 1)                     =>
          (Exception_Raised => Capacity_Error),
        others                                                               =>
          Normal_Return);

   procedure Splice
     (Container : in out List; Before : Cursor; Position : Cursor)
   with
     Global     => null,
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
     Side_Effects,
     Global     => null,
     Exit_Cases =>
       (not Is_Empty (Container) => Normal_Return,
        others                   => (Exception_Raised => Constraint_Error));

   function Last_Element (Container : List) return Element_Type
   with
     Side_Effects,
     Global     => null,
     Exit_Cases =>
       (not Is_Empty (Container) => Normal_Return,
        others                   => (Exception_Raised => Constraint_Error));

   function Next (Container : List; Position : Cursor) return Cursor
   with
     Side_Effects,
     Global     => null,
     Exit_Cases =>
       (Is_Relevant (Container, Position) => Normal_Return,
        others                            =>
          (Exception_Raised => Program_Error));

   procedure Next (Container : List; Position : in out Cursor)
   with
     Global     => null,
     Exit_Cases =>
       (Is_Relevant (Container, Position) => Normal_Return,
        others                            =>
          (Exception_Raised => Program_Error));

   function Previous (Container : List; Position : Cursor) return Cursor
   with
     Side_Effects,
     Global     => null,
     Exit_Cases =>
       (Is_Relevant (Container, Position) => Normal_Return,
        others                            =>
          (Exception_Raised => Program_Error));

   procedure Previous (Container : List; Position : in out Cursor)
   with
     Global     => null,
     Exit_Cases =>
       (Is_Relevant (Container, Position) => Normal_Return,
        others                            =>
          (Exception_Raised => Program_Error));

   function Find
     (Container : List; Item : Element_Type; Position : Cursor := No_Element)
      return Cursor
   with
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
     Side_Effects,
     Global     => null,
     Exit_Cases =>
       (Is_Relevant (Container, Position) => Normal_Return,
        others                            =>
          (Exception_Raised => Program_Error));

   function Contains (Container : List; Item : Element_Type) return Boolean
   with Global => null;

   generic
      with function "<" (Left, Right : Element_Type) return Boolean is <>;
   package Generic_Sorting with SPARK_Mode, Always_Terminates is

      function Is_Sorted (Container : List) return Boolean
      with Global => null;

      procedure Sort (Container : in out List)
      with
        Global => null,
        Post   => (Static => Length (Container) = Length (Container)'Old);

      procedure Merge (Target : in out List; Source : in out List)
      with
        Global     => SPARK.Containers.Formal.Impl.Address_Space.Address_State,
        Exit_Cases =>
          (Exceeds_Count_Type (Length (Target), Length (Source))
           => (Exception_Raised => Constraint_Error),
           Exceeds_Capacity (Length (Target), Target.Capacity, Length (Source))
           => (Exception_Raised => Capacity_Error),
           others
           => Normal_Return);
      --  May also raise Program_Error when Target and Source denote the same
      --  object; that guard is unreachable in SPARK (two in out parameters
      --  cannot alias) and relies on the volatile Same_Object function, which
      --  cannot appear in a contract.
   end Generic_Sorting;

end SPARK.Containers.Formal.Doubly_Linked_Lists.Impl;
