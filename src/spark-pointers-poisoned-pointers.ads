--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Pointer type designating a type Object with a poisoned value to
--  represent a value that has been moved and cannot be read.

pragma Extensions_Allowed (On);

with SPARK.Pointers.Parameter_Checks;
with SPARK.Pointers.Handles.Owning_Handles;

generic
   type Object (<>) is private;
   with
     function Is_Reclaimed (X : Object) return Boolean
     with Ghost => Static;

package SPARK.Pointers.Poisoned.Pointers with SPARK_Mode, Always_Terminates
is
   pragma Unevaluated_Use_Of_Old (Allow);

   --  The Is_Reclaimed function shall only return True on reclaimed values

   package Reclamation_Checks is new
     Parameter_Checks.Is_Reclaimed_Checks (Object, Is_Reclaimed);

   function Object_Logic_Equal (Left, Right : Object) return Boolean
   with
     Import,
     Ghost    => Static,
     Global   => null,
     Annotate => (GNATprove, Logical_Equal);
   --  Logical equality on objects. It is marked as import as it cannot be
   --  safely executed on most object types.

   type Pointer is private
   with
     Default_Initial_Condition => (Static => Pointer = Null_Pointer),
     Annotate                  => (GNATprove, Ownership, "Needs_Reclamation"),
     Annotate                  =>
       (GNATprove, Predefined_Equality, "Only_Null");

   Null_Pointer : constant Pointer
   with Annotate => (GNATprove, Predefined_Equality, "Null_Value");

   --  Model of the poisoned holder

   function Is_Poisoned (P : Pointer) return Boolean
   with
     Import,
     Ghost  => Static,
     Global => null,
     Post   => (if P = Null_Pointer then not Is_Poisoned'Result);
   --  Null_Pointer is never poisoned: there is nothing to move out of it. It
   --  is reclaimed all the same, see Is_Reclaimed below.

   subtype Readable_Pointer is Pointer
   with Ghost_Predicate => (Static => not Is_Poisoned (Readable_Pointer));

   function Peek (P : Readable_Pointer) return Object
   with Import, Ghost => Static, Global => null, Pre => P /= Null_Pointer;

   function Is_Reclaimed (P : Pointer) return Boolean
   with
     Ghost    => Static,
     Global   => null,
     Post     =>
       Is_Reclaimed'Result = (Is_Poisoned (P) or else P = Null_Pointer),
     Annotate => (GNATprove, Inline_For_Proof),
     Annotate => (GNATprove, Ownership, "Is_Reclaimed");

   function Logical_Eq (X, Y : Pointer) return Boolean
   with
     Import,
     Ghost    => Static,
     Global   => null,
     Annotate => (GNATprove, Logical_Equal);

   function Extensional_Eq (X, Y : Pointer) return Boolean
   with
     Ghost  => Static,
     Global => null,
     Post   =>
       Extensional_Eq'Result
       = (Is_Poisoned (X) = Is_Poisoned (Y)
          and then (X = Null_Pointer) = (Y = Null_Pointer)
          and then
            (if X /= Null_Pointer and not Is_Poisoned (X)
             then Object_Logic_Equal (Peek (X), Peek (Y))))
       and Extensional_Eq'Result = Logical_Eq (X, Y);
   --  Extensional equality on holders. It is also the logical equality.

   function Copy (P : Pointer) return Pointer
   with
     Import,
     Ghost    => Static,
     Global   => null,
     Post     => Logical_Eq (Copy'Result, P),
     Annotate => (GNATprove, Inline_For_Proof);

   --  Accessors

   function Constant_Reference
     (P : Readable_Pointer) return not null access constant Object
   with
     Global => null,
     Pre    => P /= Null_Pointer,
     Post   =>
       (Static =>
          Object_Logic_Equal (Constant_Reference'Result.all, Peek (P)));

   function At_End (P : Pointer) return Pointer
   with
     Import,
     Ghost    => Static,
     Global   => null,
     Annotate => (GNATprove, At_End_Borrow);

   function At_End (X : access constant Object) return access constant Object
   with
     Import,
     Ghost    => Static,
     Global   => null,
     Annotate => (GNATprove, At_End_Borrow);

   function Reference
     (P : in out Readable_Pointer) return not null access Object
   with
     Global => null,
     Pre    => P /= Null_Pointer,
     Post   =>
       (Static =>
          Object_Logic_Equal
            (Peek (At_End (P)), At_End (Reference'Result).all));

   --  Construct or reclaim a holder

   generic
      type Input (<>) is private;
      with function Create_Object (X : Input) return Object;
   function Create (X : Input) return Pointer
   with
     Global => null,
     Post   =>
       (Static =>
          Create'Result /= Null_Pointer
          and then not Is_Poisoned (Create'Result)
          and then
            Object_Logic_Equal (Peek (Create'Result), Create_Object (X)));

   procedure Reclaim (P : in out Pointer)
   with
     Global  => null,
     Depends => (P => null, null => P),
     Pre     =>
       (Static =>
          not Is_Poisoned (P)
          and then (P = Null_Pointer or else Is_Reclaimed (Peek (P)))),
     Post    => (Static => P = Null_Pointer);

   --  Move operations

   function Take (Source : in out Pointer) return Pointer
   with
     --  Return the object in Source leaving it in the poisoned state

     Side_Effects,
     Global         => null,
     Pre            => (Static => not Is_Poisoned (Source)),
     Contract_Cases =>
       (Static =>
          (Source = Null_Pointer =>
             Source = Null_Pointer and Take'Result = Null_Pointer,
           others                =>
             Is_Poisoned (Source)
             and then Take'Result /= Null_Pointer
             and then not Is_Poisoned (Take'Result)
             and then
               Object_Logic_Equal (Peek (Take'Result), Peek (Source)'Old)));

   procedure Move (Source : in out Pointer; Target : in out Pointer)
   with
     --  Move an object from Source to Target, leaving Source in the poisoned
     --  state. As Source and Target are both in out parameters, using Move on
     --  the cells of the same array will result in a failed aliasing check. It
     --  is possible to use Relocate from Array_Operations instead.

     Global         => null,
     Pre            =>
       (Static => not Is_Poisoned (Source) and Is_Reclaimed (Target)),
     Contract_Cases =>
       (Static =>
          (Source = Null_Pointer =>
             Source = Null_Pointer and Target = Null_Pointer,
           others                =>
             Is_Poisoned (Source)
             and then Target /= Null_Pointer
             and then not Is_Poisoned (Target)
             and then Object_Logic_Equal (Peek (Target), Peek (Source)'Old)));

   --  Operations copying the designated value

   generic
      with function Copy (O : Object) return Object;
      --  A copy of the designated value, as SPARK understands copies: if
      --  Object is subject to ownership, Copy has to duplicate what it owns.

   package Copy_Operations with Always_Terminates
   is

      function Create_Copy (O : Object) return Pointer
      with
        Global => null,
        Post   =>
          (Static =>
             Create_Copy'Result /= Null_Pointer
             and then not Is_Poisoned (Create_Copy'Result)
             and then
               Object_Logic_Equal (Peek (Create_Copy'Result), Copy (O)));
      --  Use this rather than Assign to fill a poisoned holder, which has no
      --  designated value to overwrite.

      function Deref (P : Pointer) return Object
      with
        Global   => null,
        Pre      => (Static => not Is_Poisoned (P) and then P /= Null_Pointer),
        Post     =>
          (Static => Object_Logic_Equal (Deref'Result, Copy (Peek (P)))),
        Annotate => (GNATprove, Inline_For_Proof);

      procedure Assign (P : in out Pointer; O : Object)
      with
        Global => null,
        Pre    =>
          (Static =>
             not Is_Poisoned (P)
             and then P /= Null_Pointer
             and then Is_Reclaimed (Peek (P))),
        Post   =>
          (Static =>
             not Is_Poisoned (P)
             and then P /= Null_Pointer
             and then Object_Logic_Equal (Peek (P), Copy (O)));

   end Copy_Operations;

   generic
      type Index_Type is range <>;

   package Array_Operations
   is

      type Pointer_Array is array (Index_Type range <>) of Pointer;

      subtype Readable_Array is Pointer_Array
      with
        Ghost_Predicate =>
          (Static => (for all E of Readable_Array => not Is_Poisoned (E)));

      function Logical_Eq (X, Y : Pointer_Array) return Boolean
      with
        Import,
        Ghost    => Static,
        Global   => null,
        Annotate => (GNATprove, Logical_Equal);

      function Copy (A : Pointer_Array) return Pointer_Array
      with
        Import,
        Ghost    => Static,
        Global   => null,
        Post     => Logical_Eq (Copy'Result, A),
        Annotate => (GNATprove, Inline_For_Proof);

      --  Move operations

      procedure Relocate
        (A : in out Pointer_Array; Source : Index_Type; Target : Index_Type)
      with
        --  Move an element in an array A. This is equivalent to:
        --
        --  A (Target) := A (Source);

        Global => null,
        Pre    =>
          (Static =>
             Source in A'Range
             and then Target in A'Range
             and then (Source = Target or else Is_Reclaimed (A (Target)))),
        Post   =>
          (Static =>
             Extensional_Eq (A (Target), Copy (A (Source))'Old)
             and then
               (if Source /= Target
                then
                  (if Copy (A (Source))'Old = Null_Pointer
                   then A (Source) = Null_Pointer
                   else Is_Poisoned (A (Source))))
             and then
               (for all I in A'Range =>
                  (if I not in Target | Source
                   then Extensional_Eq (A (I), Copy (A)'Old (I)))));

      procedure Relocate
        (A            : in out Pointer_Array;
         Source_From  : Index_Type'Base;
         Source_Up_To : Index_Type'Base;
         Target_From  : Index_Type'Base;
         Target_Up_To : Index_Type'Base)
      with
        --  Move a slice in an array A. This is equivalent to:
        --
        --  A (Target_From .. Target_Up_To) := A (Source_From .. Source_Up_To);

        Global => null,
        Pre    =>
          (Static =>
             (if Source_From <= Source_Up_To
              then
                Target_From <= Target_Up_To
                and then Source_From in A'Range
                and then Source_Up_To in A'Range
                and then Target_From in A'Range
                and then Target_Up_To in A'Range
                and then
                  Source_Up_To - Source_From = Target_Up_To - Target_From
                and then
                  (for all I in Target_From .. Target_Up_To =>
                     I in Source_From .. Source_Up_To
                     or else Is_Reclaimed (A (I)))
              else Target_From > Target_Up_To)),
        Post   =>
          (Static =>
             (for all I in A'Range =>
                (if I in Target_From .. Target_Up_To
                 then
                   Extensional_Eq
                     (A (I), Copy (A)'Old (I - Target_From + Source_From))
                 elsif I in Source_From .. Source_Up_To
                 then
                   (if Copy (A)'Old (I) = Null_Pointer
                    then A (I) = Null_Pointer
                    else Is_Poisoned (A (I)))
                 else Extensional_Eq (A (I), Copy (A)'Old (I))))
             and
               (for all I in Source_From .. Source_Up_To =>
                  Extensional_Eq
                    (Copy (A)'Old (I), A (I - Source_From + Target_From))));

      procedure Move
        (Source       : in out Pointer_Array;
         Source_From  : Index_Type'Base;
         Source_Up_To : Index_Type'Base;
         Target       : in out Pointer_Array;
         Target_From  : Index_Type'Base;
         Target_Up_To : Index_Type'Base)
      with
        --  Move a slice from Source to Target. This is equivalent to:
        --
        --  Target (Target_From .. Target_Up_To) :=
        --    Source (Source_From .. Source_Up_To);
        --
        --  As both Target and Source are in out parameters, this cannot be
        --  called with the same array as source and target. Use Relocate
        --  instead.

        Global => null,
        Pre    =>
          (Static =>
             (if Source_From <= Source_Up_To
              then
                Target_From <= Target_Up_To
                and then Source_From in Source'Range
                and then Source_Up_To in Source'Range
                and then Target_From in Target'Range
                and then Target_Up_To in Target'Range
                and then
                  Source_Up_To - Source_From = Target_Up_To - Target_From
                and then
                  (for all I in Target_From .. Target_Up_To =>
                     Is_Reclaimed (Target (I)))
              else Target_From > Target_Up_To)),
        Post   =>
          (Static =>
             (for all I in Target'Range =>
                (if I in Target_From .. Target_Up_To
                 then
                   Extensional_Eq
                     (Target (I),
                      Copy (Source)'Old (I - Target_From + Source_From))
                 else Extensional_Eq (Target (I), Copy (Target)'Old (I))))
             and
               (for all I in Source_From .. Source_Up_To =>
                  Extensional_Eq
                    (Copy (Source)'Old (I),
                     Target (I - Source_From + Target_From)))
             and
               (for all I in Source'Range =>
                  (if I in Source_From .. Source_Up_To
                   then
                     (if Copy (Source)'Old (I) = Null_Pointer
                      then Source (I) = Null_Pointer
                      else Is_Poisoned (Source (I)))
                   else Extensional_Eq (Source (I), Copy (Source)'Old (I)))));

   end Array_Operations;

   --  Abstract handles can be used to create recursive data structures. As
   --  the Pointer type is subject to ownership, owning handles should be
   --  used here.

   package Handle_Operations is

      use SPARK.Pointers.Handles.Owning_Handles;

      function Valid_Handle (H : Handle) return Boolean
      with Import, Ghost => Static, Global => null;

      function Peek (H : Handle) return Pointer
      with
        Import,
        Ghost  => Static,
        Global => null,
        Pre    => (Static => Valid_Handle (H)),
        Post   => Is_Reclaimed (Peek'Result) = Is_Reclaimed (H);

      --  Accessors

      function Constant_Reference
        (H : aliased Handle) return not null access constant Pointer
      with
        Global => null,
        Pre    => (Static => Valid_Handle (H)),
        Post   =>
          (Static => Logical_Eq (Constant_Reference'Result.all, Peek (H)));

      function At_End (H : Handle) return Handle
      with
        Import,
        Ghost    => Static,
        Global   => null,
        Annotate => (GNATprove, At_End_Borrow);

      function At_End
        (P : access constant Pointer) return access constant Pointer
      with
        Import,
        Ghost    => Static,
        Global   => null,
        Annotate => (GNATprove, At_End_Borrow);

      function Reference
        (H : aliased in out Handle) return not null access Pointer
      with
        Global => null,
        Pre    => (Static => Valid_Handle (H)),
        Post   =>
          (Static =>
             Valid_Handle (At_End (H))
             and then
               Logical_Eq (Peek (At_End (H)), At_End (Reference'Result).all));

      --  Construct a handle

      generic
         type Input (<>) is private;
         with function Create_Pointer (X : Input) return Pointer;
      function Create_Handle (X : Input) return Handle
      with
        Global => null,
        Post   =>
          (Static =>
             Valid_Handle (Create_Handle'Result)
             and then
               Logical_Eq (Peek (Create_Handle'Result), Create_Pointer (X)));

   end Handle_Operations;

private
   pragma SPARK_Mode (Off);

   type Object_Access is access Object;
   for Object_Access'Size use Standard'Address_Size;
   --  A thin pointer. The handle layer reinterprets a value of this
   --  type as a one-word Handle, which would be wrong for a fat
   --  pointer, as GNAT uses for an access to an indefinite type.

   type Pointer is record
      Value : Object_Access;
   end record;

   Null_Pointer : constant Pointer := (Value => null);

end SPARK.Pointers.Poisoned.Pointers;
