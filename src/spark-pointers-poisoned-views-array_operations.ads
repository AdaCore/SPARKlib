--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with SPARK.Pointers.Parameter_Checks;

generic
   type Index_Type is range <>;
   type Object_Array is array (Index_Type range <>) of aliased Object;

package SPARK.Pointers.Poisoned.Views.Array_Operations with
    SPARK_Mode,
    Always_Terminates
is
   pragma Unevaluated_Use_Of_Old (Allow);

   --  Object_Array shall admit the same component states and bounds as an
   --  ordinary array of Index_Type and Object.

   package Array_Checks is new
     SPARK.Pointers.Parameter_Checks.Array_Checks
       (Index_Type,
        Object,
        Object_Array);

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

   --  Accessors for array cells

   function Constant_Element
     (V : aliased View) return not null access constant Object
   with
     Global => null,
     Pre    => (Static => not Is_Poisoned (V)),
     Post   =>
       (Static => Object_Logic_Equal (Constant_Element'Result.all, Peek (V)));

   function Reference_Element
     (V : aliased in out View) return not null access Object
   with
     Global => null,
     Pre    => (Static => not Is_Poisoned (V)),
     Post   =>
       (Static =>
          not Is_Poisoned (At_End (V))
          and then
            Object_Logic_Equal
              (Peek (At_End (V)), At_End (Reference_Element'Result).all));

   --  Construct a view from an existing array

   function At_End (A : Object_Array) return Object_Array
   with
     Import,
     Ghost    => Static,
     Global   => null,
     Annotate => (GNATprove, At_End_Borrow);

   function At_End
     (A : access constant Readable_Array) return access constant Readable_Array
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
             and then Source_Up_To - Source_From = Target_Up_To - Target_From
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

   procedure Move (Source : in out View_Array; Target : in out View_Array)
   with
     --  Move all cells to an array of the same length. This is equivalent
     --  to:
     --
     --  Target := Source;

     Global => null,
     Pre    =>
       (Static =>
          Source'Length = Target'Length
          and then (for all V of Target => Is_Reclaimed (V))),
     Post   =>
       (Static =>
          (for all V of Source => Is_Poisoned (V))
          and then
            (for all I in Target'Range =>
               Logical_Eq
                 (Target (I),
                  Copy (Source)'Old (Source'First + (I - Target'First))))
          and then
            (for all I in Source'Range =>
               Logical_Eq
                 (Copy (Source)'Old (I),
                  Target (Target'First + (I - Source'First)))));

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
             and then Source_Up_To - Source_From = Target_Up_To - Target_From
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

end SPARK.Pointers.Poisoned.Views.Array_Operations;
