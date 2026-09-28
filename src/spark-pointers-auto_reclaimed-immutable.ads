--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Auto_Reclaimed pointers to immutable data.
--
--  Values of type Pointer are not subject to ownership: they can be freely
--  copied. The designated value is reference counted, and the cell holding it
--  is reclaimed when the last pointer to it disappears.
--
--  A pointer is modelled by the value it designates rather than by the
--  identity of its cell: two pointers to equal values are logically equal.

pragma Extensions_Allowed (On);
with SPARK.Big_Integers; use SPARK.Big_Integers;
with SPARK.Pointers.Handles.Auto_Reclaimed_Handles;
with SPARK.Pointers.Parameter_Checks;
private with SPARK.Pointers.Ref_Counting;

generic
   type Object (<>) is private;
   with procedure Reclaim (X : in out Object) is null;

package SPARK.Pointers.Auto_Reclaimed.Immutable with
    SPARK_Mode,
    Always_Terminates
is

   --  The Reclaim procedure shall reclaim a value of type Object

   package Reclamation_Checks is new
     Parameter_Checks.Reclamation_Checks (Object, Reclaim);

   type Pointer is private
   with
     Default_Initial_Condition => (Static => Pointer = Null_Pointer),
     Annotate                  =>
       (GNATprove, Predefined_Equality, "Only_Null");

   Null_Pointer : constant Pointer
   with Annotate => (GNATprove, Predefined_Equality, "Null_Value");

   function Object_Logic_Equal (Left, Right : Object) return Boolean
   with
     Import,
     Ghost    => Static,
     Global   => null,
     Annotate => (GNATprove, Logical_Equal);
   --  Logical equality on objects. It is marked as import as it cannot be
   --  safely executed on most object types.

   function Logical_Eq (X, Y : Pointer) return Boolean
   with
     Import,
     Ghost    => Static,
     Global   => null,
     Annotate => (GNATprove, Logical_Equal);
   --  Logical equality on shared pointers

   function Constant_Reference
     (P : Pointer) return not null access constant Object
   with Global => null, Pre => (SPARKlib_Defensive => P /= Null_Pointer);

   function Extensional_Eq (X, Y : Pointer) return Boolean
   with
     Import,
     Ghost  => Static,
     Global => null,
     Post   =>
       Extensional_Eq'Result
       = ((X = Null_Pointer) = (Y = Null_Pointer)
          and then
            (if X /= Null_Pointer
             then
               Object_Logic_Equal
                 (Constant_Reference (X).all, Constant_Reference (Y).all)))
       and Extensional_Eq'Result = Logical_Eq (X, Y);
   --  Extensional equality on shared pointers. It is also the logical
   --  equality.

   generic
      with function Copy (O : Object) return Object;
      --  A copy of the designated value

   package Copy_Operations with Always_Terminates
   is

      function Create_Copy (O : Object) return Pointer
      with
        Global => null,
        Post   =>
          (Static =>
             Create_Copy'Result /= Null_Pointer
             and then
               Object_Logic_Equal
                 (Constant_Reference (Create_Copy'Result).all, Copy (O)));

      --  Deref will copy the designated value

      function Deref (P : Pointer) return Object
      with
        Global   => null,
        Post     =>
          (Static =>
             Object_Logic_Equal
               (Deref'Result, Copy (Constant_Reference (P).all))),
        Annotate => (GNATprove, Inline_For_Proof);

   end Copy_Operations;

   --  Construct a shared pointer

   generic
      type Input (<>) is private;
      with function Create_Object (X : Input) return Object;
   function Create (X : Input) return Pointer
   with
     Global => null,
     Post   =>
       (Static =>
          Create'Result /= Null_Pointer
          and then
            Object_Logic_Equal
              (Constant_Reference (Create'Result).all, Create_Object (X)));

   --  Abstract handles can be used to create recursive data structure. As the
   --  Pointer has automated reclamation, use handles with reclamation.
   --  The handle package given as parameter should have the same
   --  accessibility level as the generic instance.

   generic
      with package Auto_Reclaimed_Handles is new
        SPARK.Pointers.Handles.Auto_Reclaimed_Handles.Without_Weak_Handles;
   package Handle_Operations is

      use Auto_Reclaimed_Handles;

      function Valid_Handle (H : Handle) return Boolean
      with Ghost => SPARKlib_Full, Global => null;

      function To_Handle (P : Pointer) return Handle
      with
        Global => null,
        Post   =>
          (SPARKlib_Full => Valid_Handle (To_Handle'Result),
           Static        => Logical_Eq (Of_Handle (To_Handle'Result), P));

      function Of_Handle (H : Handle) return Pointer
      with Global => null, Pre => (SPARKlib_Full => Valid_Handle (H));

      function Logical_Eq (X, Y : Handle) return Boolean
      with
        Import,
        Ghost    => Static,
        Global   => null,
        Annotate => (GNATprove, Logical_Equal);

      function Extensional_Eq (X, Y : Handle) return Boolean
      with
        Import,
        Ghost  => Static,
        Global => null,
        Pre    => (SPARKlib_Full => Valid_Handle (X) and Valid_Handle (Y)),
        Post   =>
          Extensional_Eq'Result = Logical_Eq (X, Y)
          and
            Extensional_Eq'Result
            = Extensional_Eq (Of_Handle (X), Of_Handle (Y));
      --  Extensional equality on handles. Unlike the mutable flavours, there
      --  is no executable equality here: as for a regular SPARK access type,
      --  cell identity is not observable.

      --  Provide ghost functions that can be used as a variant to prove
      --  termination of pointer-based recursive structures. They rely on the
      --  fact that Next necessarily returns a part of its input object and
      --  immutable structures cannot contain cycles. A null pointer and a
      --  handle which is not valid are both read as the end of the structure,
      --  and are strictly smaller than any cell holding a valid handle.
      --
      --  Next may return null for a way along which the object has no
      --  successor, so a structure whose nodes do not all have the same
      --  arity can be handled.

      generic
         with
           function Next
             (O : not null access constant Object)
              return access constant Handle;
      package Structural_Variant with Ghost => Static is

         function Weight (P : Pointer) return Big_Natural
         with
           Import,
           Global => null,
           Post   =>
             (if P /= Null_Pointer
                and then Next (Constant_Reference (P)) /= null
                and then Valid_Handle (Next (Constant_Reference (P)).all)
              then
                Weight'Result
                > Weight (Of_Handle (Next (Constant_Reference (P)).all)));

      end Structural_Variant;

      generic
         type Way_Type is (<>);
         with
           function Next
             (O : not null access constant Object; W : Way_Type)
              return access constant Handle;
      package Multiway_Structural_Variant with Ghost => Static is

         function Weight (P : Pointer) return Big_Natural
         with
           Import,
           Global => null,
           Post   =>
             (for all W in Way_Type =>
                (if P /= Null_Pointer
                   and then Next (Constant_Reference (P), W) /= null
                   and then Valid_Handle (Next (Constant_Reference (P), W).all)
                 then
                   Weight'Result
                   > Weight
                       (Of_Handle (Next (Constant_Reference (P), W).all))));

      end Multiway_Structural_Variant;

   private
      pragma SPARK_Mode (Off);

      use Link_Utilities;

      procedure Reclaim (X : in out Data_Placeholder_Access);

      Reclamation_Access : constant Reclamation_Procedure := Reclaim'Access;

   end Handle_Operations;

private
   pragma SPARK_Mode (Off);

   type Object_Access is access Object;
   for Object_Access'Size use Standard'Address_Size;
   --  A thin pointer. The handle layer reinterprets a value of this
   --  type as a one-word Handle, which would be wrong for a fat
   --  pointer, as GNAT uses for an access to an indefinite type.
   type No_Extra_Data is null record;

   procedure Reclaim (D : in out Object_Access; P : No_Extra_Data);

   package Ref_Counted_Data is new
     SPARK.Pointers.Ref_Counting (Object_Access, No_Extra_Data, Reclaim);
   use Ref_Counted_Data;

   type Pointer is record
      Data : Ref_Counted_Data.Shared_Ref;
   end record;

   Null_Pointer : constant Pointer :=
     (Data => (Shared_Data => null, Extra_Data => (null record)));

end SPARK.Pointers.Auto_Reclaimed.Immutable;
