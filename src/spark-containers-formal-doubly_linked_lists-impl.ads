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
--  tests/665__formal_doubly_linked_lists_impl_proof.
--
--  It carries no gold (model-based) postconditions, only what silver needs:
--  the non-model preconditions guarding implicit run-time errors, the
--  Exit_Cases documenting explicit raises, and the cheap structural facts
--  carried in the type. It does include the runtime-executable model
--  functions (Model and Positions, at level SPARKlib_Logic), which are proved
--  run-time-error-free too.

pragma Ada_2022;

with SPARK.Containers.Types; use SPARK.Containers.Types;

private generic
package SPARK.Containers.Formal.Doubly_Linked_Lists.Impl with
    SPARK_Mode,
    Always_Terminates
is

   function Model (Container : List) return Formal_Model.M.Sequence
   with Ghost => SPARKlib_Logic;

   function Positions (Container : List) return Formal_Model.P.Map
   with Ghost => SPARKlib_Logic;

   function "=" (Left, Right : List) return Boolean
   with Global => null;

   function Length (Container : List) return Count_Type
   with Global => null;

   function Empty_List (Capacity : Count_Type := 10) return List
   with Global => null;

   function Is_Empty (Container : List) return Boolean
   with Global => null;

   procedure Clear (Container : in out List)
   with Global => null;

   procedure Assign (Target : in out List; Source : List)
   with Global => null;

   function Copy (Source : List; Capacity : Count_Type := 0) return List
   with Global => null;

   function Element (Container : List; Position : Cursor) return Element_Type
   with Global => null;

   procedure Replace_Element
     (Container : in out List; Position : Cursor; New_Item : Element_Type)
   with Global => null;

   function Constant_Reference
     (Container : aliased List; Position : Cursor)
      return not null access constant Element_Type
   with Global => null;

   function Reference
     (Container : aliased in out List; Position : Cursor)
      return not null access Element_Type
   with Global => null;

   procedure Move (Target : in out List; Source : in out List)
   with Global => null;

   procedure Insert
     (Container : in out List;
      Before    : Cursor;
      New_Item  : Element_Type;
      Count     : Count_Type)
   with Global => null;

   procedure Insert
     (Container : in out List; Before : Cursor; New_Item : Element_Type)
   with Global => null;

   procedure Insert
     (Container : in out List;
      Before    : Cursor;
      New_Item  : Element_Type;
      Position  : out Cursor;
      Count     : Count_Type)
   with Global => null;

   procedure Insert
     (Container : in out List;
      Before    : Cursor;
      New_Item  : Element_Type;
      Position  : out Cursor)
   with Global => null;

   procedure Prepend (Container : in out List; New_Item : Element_Type)
   with Global => null;

   procedure Prepend
     (Container : in out List; New_Item : Element_Type; Count : Count_Type)
   with Global => null;

   procedure Append (Container : in out List; New_Item : Element_Type)
   with Global => null;

   procedure Append
     (Container : in out List; New_Item : Element_Type; Count : Count_Type)
   with Global => null;

   procedure Delete (Container : in out List; Position : in out Cursor)
   with Global => null;

   procedure Delete
     (Container : in out List; Position : in out Cursor; Count : Count_Type)
   with Global => null;

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
   with Global => null;

   procedure Swap_Links (Container : in out List; I : Cursor; J : Cursor)
   with Global => null;

   procedure Splice
     (Target : in out List; Before : Cursor; Source : in out List)
   with Global => null;

   procedure Splice
     (Target   : in out List;
      Before   : Cursor;
      Source   : in out List;
      Position : in out Cursor)
   with Global => null;

   procedure Splice
     (Container : in out List; Before : Cursor; Position : Cursor)
   with Global => null;

   function First (Container : List) return Cursor
   with Global => null;

   function First_Element (Container : List) return Element_Type
   with Global => null;

   function Last (Container : List) return Cursor
   with Global => null;

   function Last_Element (Container : List) return Element_Type
   with Global => null;

   function Next (Container : List; Position : Cursor) return Cursor
   with Global => null;

   procedure Next (Container : List; Position : in out Cursor)
   with Global => null;

   function Previous (Container : List; Position : Cursor) return Cursor
   with Global => null;

   procedure Previous (Container : List; Position : in out Cursor)
   with Global => null;

   function Find
     (Container : List; Item : Element_Type; Position : Cursor := No_Element)
      return Cursor
   with Global => null;

   function Reverse_Find
     (Container : List; Item : Element_Type; Position : Cursor := No_Element)
      return Cursor
   with Global => null;

   function Contains (Container : List; Item : Element_Type) return Boolean
   with Global => null;

   function Has_Element (Container : List; Position : Cursor) return Boolean
   with Global => null;

   generic
      with function "<" (Left, Right : Element_Type) return Boolean is <>;
   package Generic_Sorting with SPARK_Mode, Always_Terminates is

      function Is_Sorted (Container : List) return Boolean
      with Global => null;

      procedure Sort (Container : in out List)
      with Global => null, Post => Length (Container) = Length (Container)'Old;

      procedure Merge (Target : in out List; Source : in out List)
      with Global => null;
   end Generic_Sorting;

end SPARK.Containers.Formal.Doubly_Linked_Lists.Impl;
