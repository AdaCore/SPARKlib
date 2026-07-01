--
--  Copyright (C) 2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Silver-level (absence of run-time errors) implementation of
--  SPARK.Containers.Formal.Vectors. This private generic child carries all
--  the operations of the bounded vector in SPARK_Mode => On, working on the
--  parent's Vector type rather than redefining the representation. That
--  representation lives in the private part of Formal.Vectors, which is
--  SPARK_Mode => Off in normal builds; proving this unit relies on the
--  body-mode mechanism (the #BODYMODE annotations and sparklib_bodymode) to
--  switch it On in the proof test tests/1376__formal_vectors_impl_proof.
--
--  It carries no gold (model-based) postconditions, only what silver needs:
--  the non-model preconditions guarding implicit run-time errors, the
--  Exit_Cases documenting explicit raises, and the cheap structural facts
--  carried in the type. It does include the runtime-executable model
--  functions (Model, at level SPARKlib_Logic), which are proved
--  run-time-error-free too.

pragma Ada_2022;

with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Containers.Formal.Impl.Address_Space;

private generic
package SPARK.Containers.Formal.Vectors.Impl with SPARK_Mode, Always_Terminates
is
   use SPARK.Containers.Formal.Impl.Address_Space;

   --  The following ghost helpers express, without any model, the exact
   --  conditions under which the insertion operations raise en exception. They
   --  are used in the Exit_Cases below so that those contracts state precisely
   --  when, and which, exception is raised.

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
   --  capacity, which raises Capacity_Error.

   function Model (Container : Vector) return Formal_Model.M.Sequence
   with Ghost => SPARKlib_Logic;

   function First_Index (Dummy_Container : Vector) return Index_Type
   with Global => null;

   function Last_Index (Container : Vector) return Extended_Index
   with Global => null;

   function Length (Container : Vector) return Capacity_Range
   with Global => null;

   function Capacity (Container : Vector) return Capacity_Range
   with Global => null;

   function Is_Empty (Container : Vector) return Boolean
   with Global => null;

   function "=" (Left, Right : Vector) return Boolean
   with Volatile_Function, Global => Address_State;

   function Empty_Vector (Capacity : Count_Type := 10) return Vector
   with
     Global     => null,
     Side_Effects,
     Exit_Cases =>
       ((Capacity in Capacity_Range) => Normal_Return,
        others                       =>
          (Exception_Raised => Constraint_Error)),
     Post       => (Static => Empty_Vector'Result.Capacity = Capacity);

   function To_Vector
     (New_Item : Element_Type; Length : Capacity_Range) return Vector
   with Global => null, Post => (Static => To_Vector'Result.Capacity = Length);

   procedure Reserve_Capacity
     (Container : in out Vector; Capacity : Capacity_Range)
   with
     Global     => null,
     Exit_Cases =>
       (Capacity <= Container.Capacity => Normal_Return,
        others                         =>
          (Exception_Raised => Capacity_Error)),
     Post       => (Static => Length (Container) = Length (Container)'Old);

   procedure Clear (Container : in out Vector)
   with Global => null, Post => Length (Container) = 0;

   procedure Assign (Target : in out Vector; Source : Vector)
   with
     Global     => Address_State,
     Exit_Cases =>
       (Target.Capacity < Length (Source) =>
          (Exception_Raised => Constraint_Error));

   function Copy
     (Source : Vector; Capacity : Capacity_Range := 0) return Vector
   with
     Side_Effects,
     Global     => null,
     Exit_Cases =>
       (Capacity /= 0 and then Capacity < Length (Source) =>
          (Exception_Raised => Capacity_Error),
        others                                            => Normal_Return),
     Post       =>
       (Static =>
          (if Capacity = 0
           then Copy'Result.Capacity = Length (Source)
           else Copy'Result.Capacity = Capacity));

   procedure Move (Target : in out Vector; Source : in out Vector)
   with
     Global     => Address_State,
     Exit_Cases =>
       (Target.Capacity < Length (Source) =>
          (Exception_Raised => Capacity_Error),
        others                            => Normal_Return);

   function Element
     (Container : Vector; Index : Extended_Index) return Element_Type
   with
     Side_Effects,
     Global     => null,
     Exit_Cases =>
       ((Index in First_Index (Container) .. Last_Index (Container)) =>
          Normal_Return,
        others                                                       =>
          (Exception_Raised => Constraint_Error));

   procedure Replace_Element
     (Container : in out Vector; Index : Index_Type; New_Item : Element_Type)
   with
     Global     => null,
     Exit_Cases =>
       (Index <= Last_Index (Container) => Normal_Return,
        others                          =>
          (Exception_Raised => Constraint_Error)),
     Post       => (Static => Length (Container) = Length (Container)'Old);

   function Constant_Reference
     (Container : aliased Vector; Index : Index_Type)
      return not null access constant Element_Type
   with
     Global => null,
     Pre    =>
       (Static => Index in First_Index (Container) .. Last_Index (Container));

   function Reference
     (Container : aliased in out Vector; Index : Index_Type)
      return not null access Element_Type
   with
     Global => null,
     Pre    =>
       (Static => Index in First_Index (Container) .. Last_Index (Container));

   procedure Insert_Vector
     (Container : in out Vector; Before : Extended_Index; New_Item : Vector)
   with
     Global     => Address_State,
     Exit_Cases =>
       (not Valid_Index_For_Insertion (Last_Index (Container), Before)
        or Exceeds_Last_Count (Length (Container), Length (New_Item))     =>
          (Exception_Raised => Constraint_Error),
        Valid_Index_For_Insertion (Last_Index (Container), Before)
        and
          Exceeds_Capacity
            (Length (Container), Capacity (Container), Length (New_Item)) =>
          (Exception_Raised => Capacity_Error),
        others                                                            =>
          Normal_Return);
   --  May also raise Program_Error when Container and New_Item denote the same
   --  object; that guard is unreachable in SPARK (no aliasing of in out and in
   --  parameters) and is justified at proof time rather than listed here, as a
   --  volatile function cannot appear in a contract.

   procedure Insert
     (Container : in out Vector;
      Before    : Extended_Index;
      New_Item  : Element_Type)
   with
     Global     => null,
     Exit_Cases =>
       (not Valid_Index_For_Insertion (Last_Index (Container), Before)
        or Exceeds_Last_Count (Length (Container), 1)                      =>
          (Exception_Raised => Constraint_Error),
        Valid_Index_For_Insertion (Last_Index (Container), Before)
        and Exceeds_Capacity (Length (Container), Capacity (Container), 1) =>
          (Exception_Raised => Capacity_Error),
        others                                                             =>
          Normal_Return);

   procedure Insert
     (Container : in out Vector;
      Before    : Extended_Index;
      New_Item  : Element_Type;
      Count     : Count_Type)
   with
     Global     => null,
     Exit_Cases =>
       (not Valid_Index_For_Insertion (Last_Index (Container), Before)
        or Exceeds_Last_Count (Length (Container), Count)
        => (Exception_Raised => Constraint_Error),
        Valid_Index_For_Insertion (Last_Index (Container), Before)
        and Exceeds_Capacity (Length (Container), Capacity (Container), Count)
        => (Exception_Raised => Capacity_Error),
        others
        => Normal_Return);

   procedure Prepend_Vector (Container : in out Vector; New_Item : Vector)
   with
     Global     => Address_State,
     Exit_Cases =>
       (Exceeds_Last_Count (Length (Container), Length (New_Item))      =>
          (Exception_Raised => Constraint_Error),
        Exceeds_Capacity
          (Length (Container), Capacity (Container), Length (New_Item)) =>
          (Exception_Raised => Capacity_Error),
        others                                                          =>
          Normal_Return);
   --  May also raise Program_Error on aliasing; see Insert_Vector.

   procedure Prepend (Container : in out Vector; New_Item : Element_Type)
   with
     Global     => null,
     Exit_Cases =>
       (Exceeds_Last_Count (Length (Container), 1)                     =>
          (Exception_Raised => Constraint_Error),
        Exceeds_Capacity (Length (Container), Capacity (Container), 1) =>
          (Exception_Raised => Capacity_Error),
        others                                                         =>
          Normal_Return);

   procedure Prepend
     (Container : in out Vector; New_Item : Element_Type; Count : Count_Type)
   with
     Global     => null,
     Exit_Cases =>
       (Exceeds_Last_Count (Length (Container), Count)                     =>
          (Exception_Raised => Constraint_Error),
        Exceeds_Capacity (Length (Container), Capacity (Container), Count) =>
          (Exception_Raised => Capacity_Error),
        others                                                             =>
          Normal_Return);

   procedure Append_Vector (Container : in out Vector; New_Item : Vector)
   with
     Global     => Address_State,
     Exit_Cases =>
       (Exceeds_Last_Count (Length (Container), Length (New_Item))      =>
          (Exception_Raised => Constraint_Error),
        Exceeds_Capacity
          (Length (Container), Capacity (Container), Length (New_Item)) =>
          (Exception_Raised => Capacity_Error),
        others                                                          =>
          Normal_Return);
   --  May also raise Program_Error on aliasing; see Insert_Vector.

   procedure Append (Container : in out Vector; New_Item : Element_Type)
   with
     Global     => null,
     Exit_Cases =>
       (Exceeds_Last_Count (Length (Container), 1)                     =>
          (Exception_Raised => Constraint_Error),
        Exceeds_Capacity (Length (Container), Capacity (Container), 1) =>
          (Exception_Raised => Capacity_Error),
        others                                                         =>
          Normal_Return);

   procedure Append
     (Container : in out Vector; New_Item : Element_Type; Count : Count_Type)
   with
     Global     => null,
     Exit_Cases =>
       (Exceeds_Last_Count (Length (Container), Count)                     =>
          (Exception_Raised => Constraint_Error),
        Exceeds_Capacity (Length (Container), Capacity (Container), Count) =>
          (Exception_Raised => Capacity_Error),
        others                                                             =>
          Normal_Return);

   procedure Delete (Container : in out Vector; Index : Extended_Index)
   with
     Global     => null,
     Exit_Cases =>
       ((Index in First_Index (Container) .. Last_Index (Container))
        or Index - 1 = Last_Index (Container) => Normal_Return,
        others                                =>
          (Exception_Raised => Constraint_Error));

   procedure Delete
     (Container : in out Vector; Index : Extended_Index; Count : Count_Type)
   with
     Global     => null,
     Exit_Cases =>
       ((Index in First_Index (Container) .. Last_Index (Container))
        or Index - 1 = Last_Index (Container) => Normal_Return,
        others                                =>
          (Exception_Raised => Constraint_Error));

   procedure Delete_First (Container : in out Vector)
   with Global => null;
   --  Never raises: on an empty container the body clears it (a no-op).

   procedure Delete_First (Container : in out Vector; Count : Count_Type)
   with Global => null;

   procedure Delete_Last (Container : in out Vector)
   with Global => null;

   procedure Delete_Last (Container : in out Vector; Count : Count_Type)
   with Global => null;

   procedure Reverse_Elements (Container : in out Vector)
   with Global => null, Post => Length (Container) = Length (Container)'Old;

   procedure Swap (Container : in out Vector; I : Index_Type; J : Index_Type)
   with
     Global     => null,
     Exit_Cases =>
       (I > Last_Index (Container) or else J > Last_Index (Container) =>
          (Exception_Raised => Constraint_Error),
        others                                                        =>
          Normal_Return),
     Post       => (Static => Length (Container) = Length (Container)'Old);

   function First_Element (Container : Vector) return Element_Type
   with
     Side_Effects,
     Global     => null,
     Exit_Cases =>
       (Is_Empty (Container) => (Exception_Raised => Constraint_Error),
        others               => Normal_Return);

   function Last_Element (Container : Vector) return Element_Type
   with
     Side_Effects,
     Global     => null,
     Exit_Cases =>
       (Is_Empty (Container) => (Exception_Raised => Constraint_Error),
        others               => Normal_Return);

   function Find_Index
     (Container : Vector;
      Item      : Element_Type;
      Index     : Index_Type := Index_Type'First) return Extended_Index
   with Global => null;

   function Reverse_Find_Index
     (Container : Vector;
      Item      : Element_Type;
      Index     : Index_Type := Index_Type'Last) return Extended_Index
   with Global => null;

   function Contains (Container : Vector; Item : Element_Type) return Boolean
   with Global => null;

   function Has_Element
     (Container : Vector; Position : Extended_Index) return Boolean
   with Global => null;

   generic
      with function "<" (Left, Right : Element_Type) return Boolean is <>;
   package Generic_Sorting with SPARK_Mode, Always_Terminates is

      function Is_Sorted (Container : Vector) return Boolean
      with Global => null;

      procedure Sort (Container : in out Vector)
      with
        Global => null,
        Post   => (Static => Length (Container) = Length (Container)'Old);

      procedure Merge (Target : in out Vector; Source : in out Vector)
      with
        Global     => SPARK.Containers.Formal.Impl.Address_Space.Address_State,
        Exit_Cases =>
          (Exceeds_Last_Count (Length (Target), Length (Source))   =>
             (Exception_Raised => Constraint_Error),
           Exceeds_Capacity
             (Length (Target), Capacity (Target), Length (Source)) =>
             (Exception_Raised => Capacity_Error),
           others                                                  =>
             Normal_Return);
      --  May also raise Program_Error on aliasing; see Insert_Vector.
   end Generic_Sorting;

   function Iter_First (Dummy_Container : Vector) return Extended_Index;

   function Iter_Has_Element
     (Container : Vector; Position : Extended_Index) return Boolean;

   function Iter_Next
     (Container : Vector; Position : Extended_Index) return Extended_Index
   with Pre => (Static => Iter_Has_Element (Container, Position));

end SPARK.Containers.Formal.Vectors.Impl;
