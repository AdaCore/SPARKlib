--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Use traversal functions to provide a view of an existing object of a
--  type Object (subject to ownership) with a poisoned value to represent a
--  value that has been moved and cannot be read.

pragma Extensions_Allowed (On);

with SPARK.Pointers.Parameter_Checks;

generic
   type Object is private;
   pragma Warnings (Off, "unused variable ""X""");
   with
     function Is_Reclaimed (X : Object) return Boolean
     is (True)
     with Ghost => Static;
   pragma Warnings (On, "unused variable ""X""");

package SPARK.Pointers.Poisoned.Views with SPARK_Mode, Always_Terminates
is
   pragma Unevaluated_Use_Of_Old (Allow);

   --  The Is_Reclaimed function shall only return True on reclaimed values

   package Reclamation_Checks is new
     Parameter_Checks.Is_Reclaimed_Checks (Object, Is_Reclaimed);

   --  Assigning an object should preserve the object. This might not be
   --  True for tagged records in particular. It is necessary for the
   --  postconditions of Take and Move to be correct.

   package Assignment_Checks is new
     Parameter_Checks.Assignment_Checks (Object);

   function Object_Logic_Equal (Left, Right : Object) return Boolean
   with
     Import,
     Ghost    => Static,
     Global   => null,
     Annotate => (GNATprove, Logical_Equal);
   --  Logical equality on objects. It is marked as import as it cannot be
   --  safely executed on most object types.

   type View is private
   with
     Default_Initial_Condition => (Static => Is_Poisoned (View)),
     Annotate                  => (GNATprove, Ownership, "Needs_Reclamation"),
     Annotate                  =>
       (GNATprove, Predefined_Equality, "No_Equality");

   --  Model of the poisoned view

   function Is_Poisoned (V : View) return Boolean
   with Import, Ghost => Static, Global => null;

   subtype Readable_View is View
   with Ghost_Predicate => (Static => not Is_Poisoned (Readable_View));

   function Peek (V : Readable_View) return Object
   with Import, Ghost => Static, Global => null;

   function Is_Reclaimed (V : View) return Boolean
   with
     Ghost    => Static,
     Global   => null,
     Post     =>
       Is_Reclaimed'Result = (Is_Poisoned (V) or else Is_Reclaimed (Peek (V))),
     Annotate => (GNATprove, Inline_For_Proof),
     Annotate => (GNATprove, Ownership, "Is_Reclaimed");

   function Logical_Eq (X, Y : View) return Boolean
   with
     Import,
     Ghost    => Static,
     Global   => null,
     Annotate => (GNATprove, Logical_Equal);

   function Extensional_Eq (X, Y : View) return Boolean
   with
     Ghost  => Static,
     Global => null,
     Post   =>
       Extensional_Eq'Result
       = (Is_Poisoned (X) = Is_Poisoned (Y)
          and then
            (if not Is_Poisoned (X)
             then Object_Logic_Equal (Peek (X), Peek (Y))))
       and Extensional_Eq'Result = Logical_Eq (X, Y);
   --  Extensional equality on views. It is also the logical equality.

   function Copy (V : View) return View
   with
     Ghost    => Static,
     Global   => null,
     Post     => Logical_Eq (Copy'Result, V),
     Annotate => (GNATprove, Inline_For_Proof);

   --  Accessors

   function Constant_Reference
     (V : aliased Readable_View) return not null access constant Object
   with
     Global => null,
     Post   =>
       (Static =>
          Object_Logic_Equal (Constant_Reference'Result.all, Peek (V)));

   function At_End (V : View) return View
   with
     Import,
     Ghost    => Static,
     Global   => null,
     Annotate => (GNATprove, At_End_Borrow);

   function At_End (X : Object) return Object
   with
     Import,
     Ghost    => Static,
     Global   => null,
     Annotate => (GNATprove, At_End_Borrow);

   function At_End
     (V : access constant Readable_View) return access constant Readable_View
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
     (V : aliased in out Readable_View) return not null access Object
   with
     Global => null,
     Post   =>
       (Static =>
          Object_Logic_Equal
            (Peek (At_End (V)), At_End (Reference'Result).all));

   --  Construct a view from an existing object

   function Get_View
     (X : aliased in out Object) return not null access Readable_View
   with
     Global => null,
     Post   =>
       (Static =>
          Object_Logic_Equal
            (Peek (At_End (Get_View'Result).all), At_End (X)));
   --  Get_View returns an access to a clean view, as it expects it to be clean
   --  at the end of the borrow. Pass it as a parameter of a subprogram with a
   --  formal of type View to break it temporarily.

   --  Construct a view from a new value. It can be used to fill a poisoned
   --  view.

   generic
      type Input (<>) is private;
      with function Create_Object (X : Input) return Object;
   function Create (X : Input) return View
   with
     Global => null,
     Post   =>
       (Static =>
          not Is_Poisoned (Create'Result)
          and then
            Object_Logic_Equal (Peek (Create'Result), Create_Object (X)));

   --  Move operations

   function Take (Source : in out View) return View
   with
     --  Return the object in Source leaving it in the poisoned state

     Side_Effects,
     Global => null,
     Pre    => (Static => not Is_Poisoned (Source)),
     Post   =>
       (Static =>
          Is_Poisoned (Source)
          and then not Is_Poisoned (Take'Result)
          and then Object_Logic_Equal (Peek (Take'Result), Peek (Source)'Old));

   procedure Move (Source : in out View; Target : in out View)
   with
     --  Move an object from Source to Target, leaving Source in the poisoned
     --  state. As Source and Target are both in out parameters, using Move on
     --  the cells of the same array will result in a failed aliasing check. It
     --  is possible to use Relocate from Array_Operations instead.

     Global => null,
     Pre    => (Static => not Is_Poisoned (Source) and Is_Reclaimed (Target)),
     Post   =>
       (Static =>
          Is_Poisoned (Source)
          and then not Is_Poisoned (Target)
          and then Object_Logic_Equal (Peek (Target), Peek (Source)'Old));

   --  Move operations whose target is an object. They give back the object
   --  in a view as an owner, for example to link it into another structure.
   --  There are no operations in the other direction, as moving an object
   --  would leave it as it was, duplicating what it owns. Use Create instead.

   function Take (Source : in out View) return Object
   with
     --  Return the object in Source leaving it in the poisoned state

     Side_Effects,
     Global => null,
     Pre    => (Static => not Is_Poisoned (Source)),
     Post   =>
       (Static =>
          Is_Poisoned (Source)
          and then Object_Logic_Equal (Take'Result, Peek (Source)'Old));

   procedure Move (Source : in out View; Target : in out Object)
   with
     --  Move the object in Source to Target, leaving Source in the poisoned
     --  state.

     Global => null,
     Pre    => (Static => not Is_Poisoned (Source) and Is_Reclaimed (Target)),
     Post   =>
       (Static =>
          Is_Poisoned (Source)
          and then Object_Logic_Equal (Target, Peek (Source)'Old));

   generic
      type Index_Type is range <>;
      type Object_Array is array (Index_Type range <>) of aliased Object;

   package Array_Operations
   is

      type View_Array is array (Index_Type range <>) of aliased View;
      pragma
        Compile_Time_Error
          (View_Array'Component_Size /= Object_Array'Component_Size,
           "views assume the layout of the objects they view");
      --  Get_View below reinterprets an Object_Array as a View_Array. This
      --  is only correct if both have the same component size.

      subtype Readable_Array is View_Array
      with
        Ghost_Predicate =>
          (Static => (for all E of Readable_Array => not Is_Poisoned (E)));

      function Logical_Eq (X, Y : View_Array) return Boolean
      with
        Import,
        Ghost    => Static,
        Global   => null,
        Annotate => (GNATprove, Logical_Equal);

      function Copy (A : View_Array) return View_Array
      with
        Import,
        Ghost    => Static,
        Global   => null,
        Post     => Logical_Eq (Copy'Result, A),
        Annotate => (GNATprove, Inline_For_Proof);

      --  Construct a view from an existing array

      function At_End (A : Object_Array) return Object_Array
      with
        Import,
        Ghost    => Static,
        Global   => null,
        Annotate => (GNATprove, At_End_Borrow);

      function At_End
        (A : access constant Readable_Array)
         return access constant Readable_Array
      with
        Import,
        Ghost    => Static,
        Global   => null,
        Annotate => (GNATprove, At_End_Borrow);

      function Get_View
        (A : aliased in out Object_Array) return not null access Readable_Array
      with
        Global => null,
        Post   =>
          (Static =>
             Get_View'Result'First = A'First
             and then Get_View'Result'Last = A'Last
             and then
               (for all I in A'Range =>
                  Object_Logic_Equal
                    (Peek (At_End (Get_View'Result) (I)), At_End (A) (I))));
      --  Get_View returns an access to a clean array, as it expects it to be
      --  clean at the end of the borrow. Pass it as a parameter of a
      --  subprogram with a formal of type View_Array to break it temporarily.

      --  Move operations

      procedure Relocate
        (A : in out View_Array; Source : Index_Type; Target : Index_Type)
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
             Logical_Eq (A (Target), Copy (A (Source))'Old)
             and then (if Source /= Target then Is_Poisoned (A (Source)))
             and then
               (for all I in A'Range =>
                  (if I not in Target | Source
                   then Logical_Eq (A (I), Copy (A)'Old (I)))));

      procedure Relocate
        (A            : in out View_Array;
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
                   Logical_Eq
                     (A (I), Copy (A)'Old (I - Target_From + Source_From))
                 elsif I in Source_From .. Source_Up_To
                 then Is_Poisoned (A (I))
                 else Logical_Eq (A (I), Copy (A)'Old (I))))
             and
               (for all I in Source_From .. Source_Up_To =>
                  Logical_Eq
                    (Copy (A)'Old (I), A (I - Source_From + Target_From))));

      procedure Move
        (Source       : in out View_Array;
         Source_From  : Index_Type'Base;
         Source_Up_To : Index_Type'Base;
         Target       : in out View_Array;
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
                   Logical_Eq
                     (Target (I),
                      Copy (Source)'Old (I - Target_From + Source_From))
                 else Logical_Eq (Target (I), Copy (Target)'Old (I))))
             and
               (for all I in Source_From .. Source_Up_To =>
                  Logical_Eq
                    (Copy (Source)'Old (I),
                     Target (I - Source_From + Target_From)))
             and
               (for all I in Source'Range =>
                  (if I in Source_From .. Source_Up_To
                   then Is_Poisoned (Source (I))
                   else Logical_Eq (Source (I), Copy (Source)'Old (I)))));

   end Array_Operations;

private
   pragma SPARK_Mode (Off);

   type View is record
      Value : Object;
   end record;

end SPARK.Pointers.Poisoned.Views;
