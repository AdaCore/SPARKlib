--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with SPARK.Pointers.Parameter_Checks;

generic
   type Index_Type is range <>;
   type Pointer_Array is array (Index_Type range <>) of Pointer;

package SPARK.Pointers.Poisoned.Pointers.Array_Operations with
    SPARK_Mode,
    Always_Terminates
is
   pragma Unevaluated_Use_Of_Old (Allow);

   --  Pointer_Array shall admit the same component states and bounds as an
   --  ordinary array of Index_Type and Pointer.

   package Array_Checks is new
     SPARK.Pointers.Parameter_Checks.Array_Checks
       (Index_Type,
        Pointer,
        Pointer_Array);

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
     (Source : in out Pointer_Array; Target : in out Pointer_Array)
   with
     --  Move all cells to an array of the same length. This is equivalent
     --  to:
     --
     --  Target := Source;

     Global => null,
     Pre    =>
       (Static =>
          Source'Length = Target'Length
          and then (for all P of Target => Is_Reclaimed (P))),
     Post   =>
       (Static =>
          (for all I in Source'Range =>
             (if Copy (Source)'Old (I) = Null_Pointer
              then Source (I) = Null_Pointer
              else Is_Poisoned (Source (I))))
          and then
            (for all I in Target'Range =>
               Extensional_Eq
                 (Target (I),
                  Copy (Source)'Old (Source'First + (I - Target'First))))
          and then
            (for all I in Source'Range =>
               Extensional_Eq
                 (Copy (Source)'Old (I),
                  Target (Target'First + (I - Source'First)))));

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

end SPARK.Pointers.Poisoned.Pointers.Array_Operations;
