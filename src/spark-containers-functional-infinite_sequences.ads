--
--  Copyright (C) 2022-2025, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

private with SPARK.Containers.Types;
private with SPARK.Containers.Functional.Base;

with SPARK.Big_Integers; use SPARK.Big_Integers;
with SPARK.Containers.Parameter_Checks;

generic
   type Element_Type (<>) is private;
   with function "=" (Left, Right : Element_Type) return Boolean is <>;
   with function Equivalent_Elements
     (Left, Right : Element_Type) return Boolean is "=";
   --  Function used to compare elements in Contains, Find, and
   --  Equivalent_Sequences.

   --  Ghost lemmas used to prove that "=" is an equivalence relation

   with procedure Eq_Reflexive (X : Element_Type) is null
     with Ghost;
   with procedure Eq_Symmetric (X, Y : Element_Type) is null
     with Ghost;
   with procedure Eq_Transitive (X, Y, Z : Element_Type) is null
     with Ghost;

   --  Ghost lemmas used to prove that Equivalent_Elements is an equivalence
   --  relation.

   with procedure Equivalent_Elements_Reflexive (X, Y : Element_Type) is null
     with Ghost;
   with procedure Equivalent_Elements_Symmetric (X, Y : Element_Type) is null
     with Ghost;
   with procedure Equivalent_Elements_Transitive
     (X, Y, Z : Element_Type) is null
     with Ghost;

package SPARK.Containers.Functional.Infinite_Sequences with
  SPARK_Mode,
  Always_Terminates
is

   pragma Annotate (GNATcheck, Exempt_On,
                    "Restrictions:No_Specification_Of_Aspect => Iterable",
                    "The following usage of aspect Iterable has been reviewed"
                    & "for compliance with GNATprove assumption"
                    & " [SPARK_ITERABLE]");
   type Sequence is private with
     Default_Initial_Condition => Length (Sequence) = 0,
     Iterable                  => (First       => Iter_First,
                                   Has_Element => Iter_Has_Element,
                                   Next        => Iter_Next,
                                   Element     => Get),
     Aggregate                 => (Empty       => Empty_Sequence,
                                   Add_Unnamed => Aggr_Append),
     Annotate                  =>
       (GNATprove, Container_Aggregates, "Predefined_Sequences");
   pragma Annotate (GNATcheck, Exempt_Off,
                    "Restrictions:No_Specification_Of_Aspect => Iterable");

   --  Sequences are empty when default initialized.
   --  Quantification over sequences can be done using the regular
   --  quantification over its range or directly on its elements with "for of".

   -----------------------
   --  Basic operations --
   -----------------------

   --  Sequences are axiomatized using Length and Get, providing respectively
   --  the length of a sequence and an accessor to its Nth element:

   function Length (Container : Sequence) return Big_Natural with
   --  Length of a sequence

     Global   => null,
     Annotate => (GNATprove, Container_Aggregates, "Last");

   function Get
     (Container : Sequence;
      Position  : Big_Integer) return Element_Type
   --  Access the Element at position Position in Container

   with
     Global   => null,
     Pre      => Iter_Has_Element (Container, Position),
     Annotate => (GNATprove, Container_Aggregates, "Get");

   function Last (Container : Sequence) return Big_Natural with
   --  Last index of a sequence

     Global => null,
     Post =>
       Last'Result = Length (Container);
   pragma Annotate (GNATprove, Inline_For_Proof, Last);

   function First return Big_Positive is (1) with
   --  First index of a sequence

     Global   => null,
     Annotate => (GNATprove, Container_Aggregates, "First");

   ------------------------
   -- Property Functions --
   ------------------------

   function "=" (Left : Sequence; Right : Sequence) return Boolean with
   --  Extensional equality over sequences

     Global => null,
     Post   =>
       "="'Result =
         (Length (Left) = Length (Right)
           and then (for all N in Left => Get (Left, N) = Get (Right, N)));
   pragma Annotate (GNATprove, Inline_For_Proof, "=");

   function "<" (Left : Sequence; Right : Sequence) return Boolean with
   --  Left is a strict subsequence of Right

     Global => null,
     Post   =>
       "<"'Result =
         (Length (Left) < Length (Right)
           and then (for all N in Left => Get (Left, N) = Get (Right, N)));
   pragma Annotate (GNATprove, Inline_For_Proof, "<");

   function "<=" (Left : Sequence; Right : Sequence) return Boolean with
   --  Left is a subsequence of Right

     Global => null,
     Post   =>
       "<="'Result =
         (Length (Left) <= Length (Right)
           and then (for all N in Left => Get (Left, N) = Get (Right, N)));
   pragma Annotate (GNATprove, Inline_For_Proof, "<=");

   -----------------------------------------------------
   -- Properties handling elements modulo equivalence --
   -----------------------------------------------------

   function Equivalent_Sequences (Left, Right : Sequence) return Boolean
   with
   --  Equivalence over sequences

     Global => null,
     Post   =>
       Equivalent_Sequences'Result =
         (Length (Left) = Length (Right)
           and then
            (for all N in Left =>
               Equivalent_Elements (Get (Left, N), Get (Right, N))));
   pragma Annotate (GNATprove, Inline_For_Proof, Equivalent_Sequences);

   function Contains
     (Container : Sequence;
      Fst       : Big_Positive;
      Lst       : Big_Natural;
      Item      : Element_Type) return Boolean
   --  Returns True if Item occurs in the range from Fst to Lst of Container

   with
     Global => null,
     Pre    => Lst <= Last (Container),
     Post   =>
       Contains'Result =
           (for some J in Container =>
              Fst <= J and J <= Lst and
                Equivalent_Elements (Get (Container, J), Item));
   pragma Annotate (GNATprove, Inline_For_Proof, Contains);

   function Find
     (Container : Sequence;
      Item      : Element_Type) return Big_Natural
   --  Search for Item in Container

     with
       Global => null,
       Contract_Cases =>
         ((for all J in Container =>
             not Equivalent_Elements (Get (Container, J), Item))
          =>
            Find'Result = 0,
          others =>
            Find'Result > 0 and
            Find'Result <= Length (Container) and
            Equivalent_Elements (Item, Get (Container, Find'Result)));

   ----------------------------
   -- Construction Functions --
   ----------------------------

   function Empty_Sequence return Sequence with
   --  Return an empty Sequence

     Global => null,
     Post   => Length (Empty_Sequence'Result) = 0;

   --  For better efficiency of both proofs and execution, avoid using
   --  construction functions in annotations and rather use property functions.

   function Set
     (Container : Sequence;
      Position  : Big_Positive;
      New_Item  : Element_Type) return Sequence
   --  Returns a new sequence which contains the same elements as Container
   --  except for the one at position Position which is replaced by New_Item.

   with
     Global => null,
     Pre    => Position <= Last (Container),
     Post   =>
       Element_Logic_Equal
           (Get (Set'Result, Position), Copy_Element (New_Item))
         and then Equal_Except (Container, Set'Result, Position);

   function Add (Container : Sequence; New_Item : Element_Type) return Sequence
   --  Returns a new sequence which contains the same elements as Container
   --  plus New_Item at the end.

   with
     Global => null,
     Post   =>
       Length (Add'Result) = Length (Container) + 1
         and then Element_Logic_Equal
           (Get (Add'Result, Last (Add'Result)), Copy_Element (New_Item))
         and then Equal_Prefix (Container, Add'Result);

   function Add
     (Container : Sequence;
      Position  : Big_Positive;
      New_Item  : Element_Type) return Sequence
   with
   --  Returns a new sequence which contains the same elements as Container
   --  except that New_Item has been inserted at position Position.

     Global => null,
     Pre    => Position <= Last (Container) + 1,
     Post   =>
       Length (Add'Result) = Length (Container) + 1
         and then Element_Logic_Equal
           (Get (Add'Result, Position), Copy_Element (New_Item))
         and then Range_Equal
                    (Left  => Container,
                     Right => Add'Result,
                     Fst   => 1,
                     Lst   => Position - 1)
         and then Range_Shifted
                    (Left   => Container,
                     Right  => Add'Result,
                     Fst    => Position,
                     Lst    => Last (Container),
                     Offset => 1);

   function Remove
     (Container : Sequence;
      Position : Big_Positive) return Sequence
   --  Returns a new sequence which contains the same elements as Container
   --  except that the element at position Position has been removed.

   with
     Global => null,
     Pre    => Position <= Last (Container),
     Post   =>
       Length (Remove'Result) = Length (Container) - 1
         and then Range_Equal
                    (Left  => Container,
                     Right => Remove'Result,
                     Fst   => 1,
                     Lst   => Position - 1)
         and then Range_Shifted
                    (Left   => Remove'Result,
                     Right  => Container,
                     Fst    => Position,
                     Lst    => Last (Remove'Result),
                     Offset => 1);

   --------------------------
   -- Instantiation Checks --
   --------------------------

   --  Check that the actual parameters follow the appropriate assumptions.

   function Copy_Element (Item : Element_Type) return Element_Type is (Item)
     with Annotate => (GNATprove, Inline_For_Proof);
   --  Elements of containers are copied by numerous primitives in this
   --  package. This function causes GNATprove to verify that such a copy is
   --  valid (in particular, it does not break the ownership policy of SPARK,
   --  i.e. it does not contain pointers that could be used to alias mutable
   --  data).
   --  This function is also used to model the value of new elements after
   --  insertion inside the container. Indeed, a copy of an object might not
   --  be logically equal to the object, in particular in case of view
   --  conversions of tagged types.

   package Eq_Checks is new
     SPARK.Containers.Parameter_Checks.Equivalence_Checks
       (T                   => Element_Type,
        Eq                  => "=",
        Param_Eq_Reflexive  => Eq_Reflexive,
        Param_Eq_Symmetric  => Eq_Symmetric,
        Param_Eq_Transitive => Eq_Transitive);
   --  Check that the actual parameter for "=" is an equivalence relation

   package Eq_Elements_Checks is new
     SPARK.Containers.Parameter_Checks.Equivalence_Checks_Eq
       (T                     => Element_Type,
        Eq                    => Equivalent_Elements,
        "="                   => "=",
        Param_Equal_Reflexive => Eq_Checks.Eq_Reflexive,
        Param_Eq_Reflexive    => Equivalent_Elements_Reflexive,
        Param_Eq_Symmetric    => Equivalent_Elements_Symmetric,
        Param_Eq_Transitive   => Equivalent_Elements_Transitive);
   --  Check that the actual parameter for Equivalent_Elements is an
   --  equivalence relation with respect to the equality "=".

   ---------------------------
   --  Iteration Primitives --
   ---------------------------

   function Iter_First (Container : Sequence) return Big_Integer with
     Global => null,
     Post   => Iter_First'Result = 1;

   function Iter_Has_Element
     (Container : Sequence;
      Position  : Big_Integer) return Boolean
   with
     Global => null,
       Post   => Iter_Has_Element'Result =
                   In_Range (Position, 1, Length (Container));
   pragma Annotate (GNATprove, Inline_For_Proof, Iter_Has_Element);

   function Iter_Next
     (Container : Sequence;
      Position  : Big_Integer) return Big_Integer
   with
     Global => null,
     Pre    => Iter_Has_Element (Container, Position),
     Post   => Iter_Next'Result = Position + 1;

   -------------------------------------------------------------------------
   -- Ghost non-executable properties used only in internal specification --
   -------------------------------------------------------------------------

   --  Logical equality on elements cannot be safely executed on most element
   --  types. Thus, this package should only be instantiated with ghost code
   --  disabled. This is enforced by having a special imported procedure
   --  Check_Or_Fail that will lead to link-time errors otherwise.

   function Element_Logic_Equal (Left, Right : Element_Type) return Boolean
   with
     Ghost,
     Global => null,
     Annotate => (GNATprove, Logical_Equal);

   function Constant_Range
     (Container : Sequence;
      Fst       : Big_Positive;
      Lst       : Big_Natural;
      Item      : Element_Type) return Boolean
   --  Returns True if every element of the range from Fst to Lst of Container
   --  is equal to Item.

   with
     Ghost,
     Global => null,
     Pre    => Lst <= Last (Container),
     Post   =>
       Constant_Range'Result =
           (for all J in Container =>
              (if Fst <= J and J <= Lst
               then Element_Logic_Equal
                 (Get (Container, J), Copy_Element (Item))));
   pragma Annotate (GNATprove, Inline_For_Proof, Constant_Range);

   function Equal_Prefix (Left : Sequence; Right : Sequence) return Boolean
   with
   --  Left is a subsequence of Right

     Ghost,
     Global => null,
     Post   =>
       Equal_Prefix'Result =
         (Length (Left) <= Length (Right)
           and then
            (for all N in Left =>
               Element_Logic_Equal (Get (Left, N), Get (Right, N))));
   pragma Annotate (GNATprove, Inline_For_Proof, Equal_Prefix);

   function Equal_Except
     (Left     : Sequence;
      Right    : Sequence;
      Position : Big_Positive) return Boolean
   --  Returns True is Left and Right are the same except at position Position

   with
     Ghost,
     Global => null,
     Pre    => Position <= Last (Left),
     Post   =>
       Equal_Except'Result =
         (Length (Left) = Length (Right)
           and then
            (for all J in Left =>
               (if J /= Position
                then Element_Logic_Equal (Get (Left, J), Get (Right, J)))));
   pragma Annotate (GNATprove, Inline_For_Proof, Equal_Except);

   function Equal_Except
     (Left  : Sequence;
      Right : Sequence;
      X     : Big_Positive;
      Y     : Big_Positive) return Boolean
   --  Returns True is Left and Right are the same except at positions X and Y

   with
     Ghost,
     Global => null,
     Pre    => X <= Last (Left) and Y <= Last (Left),
     Post   =>
       Equal_Except'Result =
         (Length (Left) = Length (Right)
           and then
            (for all J in Left =>
               (if J /= X and J /= Y
                then Element_Logic_Equal (Get (Left, J), Get (Right, J)))));
   pragma Annotate (GNATprove, Inline_For_Proof, Equal_Except);

   function Range_Equal
     (Left  : Sequence;
      Right : Sequence;
      Fst   : Big_Positive;
      Lst   : Big_Natural) return Boolean
   --  Returns True if the ranges from Fst to Lst contain the same elements in
   --  Left and Right.

   with
     Ghost,
     Global => null,
     Pre    => Lst <= Last (Left) and Lst <= Last (Right),
     Post   =>
       Range_Equal'Result =
         (for all J in Left =>
            (if Fst <= J and J <= Lst
             then Element_Logic_Equal (Get (Left, J), Get (Right, J))));
   pragma Annotate (GNATprove, Inline_For_Proof, Range_Equal);

   function Range_Shifted
     (Left   : Sequence;
      Right  : Sequence;
      Fst    : Big_Positive;
      Lst    : Big_Natural;
      Offset : Big_Integer) return Boolean
   --  Returns True if the range from Fst to Lst in Left contains the same
   --  elements as the range from Fst + Offset to Lst + Offset in Right.

   with
     Ghost,
     Global => null,
     Pre    =>
       Lst <= Last (Left)
         and then
           (if Fst <= Lst then
              Offset + Fst >= 1 and Offset + Lst <= Length (Right)),
     Post   =>
       Range_Shifted'Result =
         ((for all J in Left =>
             (if Fst <= J and J <= Lst then
                Element_Logic_Equal (Get (Left, J), Get (Right, J + Offset))))
          and
            (for all J in Right =>
               (if Fst + Offset <= J and J <= Lst + Offset then
                  Element_Logic_Equal
                    (Get (Left, J - Offset), Get (Right, J)))));
   pragma Annotate (GNATprove, Inline_For_Proof, Range_Shifted);

   ------------------------------------------
   -- Additional Primitives For Aggregates --
   ------------------------------------------

   procedure Aggr_Append
     (Container : in out Sequence;
      New_Item  : Element_Type)
   with
     Global => null,
     Post   =>
       Last (Container) = Last (Container'Old) + 1
         and then Element_Logic_Equal
           (Get (Container, Last (Container)), Copy_Element (New_Item))
         and then Equal_Prefix (Container'Old, Container);

private
   pragma SPARK_Mode (Off);

   use SPARK.Containers.Types;

   subtype Positive_Count_Type is Count_Type range 1 .. Count_Type'Last;

   package Containers is new SPARK.Containers.Functional.Base
     (Index_Type   => Positive_Count_Type,
      Element_Type => Element_Type);

   type Sequence is record
      Content : Containers.Container;
   end record;

   function Iter_First (Container : Sequence) return Big_Integer is (1);

   function Iter_Next
     (Container : Sequence;
      Position  : Big_Integer) return Big_Integer
   is
     (Position + 1);

   function Iter_Has_Element
     (Container : Sequence;
      Position  : Big_Integer) return Boolean
   is
     (In_Range (Position, 1, Length (Container)));
end SPARK.Containers.Functional.Infinite_Sequences;
