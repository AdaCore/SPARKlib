--
--  Copyright (C) 2016-2025, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

private with SPARK.Containers.Functional.Base;

with SPARK.Big_Integers; use SPARK.Big_Integers;
with SPARK.Containers.Parameter_Checks;

generic
   type Index_Type is range <>;
   --  To avoid Constraint_Error being raised at run time, Index_Type'Base
   --  should have at least one more element at the low end than Index_Type.

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

package SPARK.Containers.Functional.Vectors with
  SPARK_Mode,
  Always_Terminates
is

   subtype Extended_Index is Index_Type'Base range
     Index_Type'Pred (Index_Type'First) .. Index_Type'Last;
   --  Index_Type with one more element at the low end of the range.
   --  This type is never used but it forces GNATprove to check that there is
   --  room for one more element at the low end of Index_Type.

   package Index_Conversions is
     new Signed_Conversions (Int => Extended_Index);

   function Big (J : Extended_Index) return Big_Integer renames
     Index_Conversions.To_Big_Integer;
   function Of_Big (J : Big_Integer) return Extended_Index renames
     Index_Conversions.From_Big_Integer;

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

   --  Sequences are axiomatized using Last and Get, providing respectively
   --  the index of last element of a sequence and an accessor to its
   --  Nth element:

   function Last (Container : Sequence) return Extended_Index
   --  Last index of a sequence. Index_Type'First - 1 if empty.

   with
     Global   => null,
     Annotate => (GNATprove, Container_Aggregates, "Last");

   function Get
     (Container : Sequence;
      Position  : Extended_Index) return Element_Type
   --  Access the Element at position Position in Container

   with
     Global   => null,
     Pre      => Position in Index_Type'First .. Last (Container),
     Annotate => (GNATprove, Container_Aggregates, "Get");

   function Length (Container : Sequence) return Big_Natural with
   --  Length of a sequence

     Global => null,
     Post   =>
       Length'Result = (Big (Last (Container)) + 1) - Big (Index_Type'First);
   pragma Annotate (GNATprove, Inline_For_Proof, Length);

   function First return Extended_Index is (Index_Type'First) with
     Global   => null,
     Annotate => (GNATprove, Container_Aggregates, "First");
   --  First index of a sequence

   ------------------------
   -- Property Functions --
   ------------------------

   function "=" (Left : Sequence; Right : Sequence) return Boolean with
   --  Extensional equality over sequences

     Global => null,
     Post   =>
       "="'Result =
         (Length (Left) = Length (Right)
           and then (for all N in Index_Type'First .. Last (Left) =>
                      Get (Left, N) = Get (Right, N)));
   pragma Annotate (GNATprove, Inline_For_Proof, "=");

   function "<" (Left : Sequence; Right : Sequence) return Boolean with
   --  Left is a strict subsequence of Right

     Global => null,
     Post   =>
       "<"'Result =
         (Length (Left) < Length (Right)
           and then (for all N in Index_Type'First .. Last (Left) =>
                      Get (Left, N) = Get (Right, N)));
   pragma Annotate (GNATprove, Inline_For_Proof, "<");

   function "<=" (Left : Sequence; Right : Sequence) return Boolean with
   --  Left is a subsequence of Right

     Global => null,
     Post   =>
       "<="'Result =
         (Length (Left) <= Length (Right)
           and then (for all N in Index_Type'First .. Last (Left) =>
                      Get (Left, N) = Get (Right, N)));
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
         (Last (Left) = Last (Right)
           and then
            (for all N in Index_Type'First .. Last (Left) =>
               Equivalent_Elements (Get (Left, N), Get (Right, N))));
   pragma Annotate (GNATprove, Inline_For_Proof, Equivalent_Sequences);

   function Contains
     (Container : Sequence;
      Fst       : Index_Type;
      Lst       : Extended_Index;
      Item      : Element_Type) return Boolean
   --  Returns True if Item occurs in the range from Fst to Lst of Container

   with
     Global => null,
     Pre    => Lst <= Last (Container),
     Post   =>
       Contains'Result =
         (for some I in Fst .. Lst =>
            Equivalent_Elements (Get (Container, I), Item));
   pragma Annotate (GNATprove, Inline_For_Proof, Contains);

   function Find
     (Container : Sequence;
      Item      : Element_Type) return Extended_Index
   --  Search for Item in Container

     with
       Global => null,
       Contract_Cases =>
         ((for all J in Container =>
             not Equivalent_Elements (Get (Container, J), Item))
          =>
            Find'Result = Extended_Index'First,
          others =>
            Find'Result in Index_Type'First .. Last (Container) and
            Equivalent_Elements (Item, Get (Container, Find'Result)));

   ----------------------------
   -- Construction Functions --
   ----------------------------

   --  For better efficiency of both proofs and execution, avoid using
   --  construction functions in annotations and rather use property functions.

   function Empty_Sequence return Sequence with
   --  Return an empty Sequence

     Global => null,
     Post   => Length (Empty_Sequence'Result) = 0;

   function Set
     (Container : Sequence;
      Position  : Index_Type;
      New_Item  : Element_Type) return Sequence
   --  Returns a new sequence which contains the same elements as Container
   --  except for the one at position Position which is replaced by New_Item.

   with
     Global => null,
     Pre    => Position in Index_Type'First .. Last (Container),
     Post   =>
       Element_Logic_Equal
           (Get (Set'Result, Position), Copy_Element (New_Item))
         and then Equal_Except (Container, Set'Result, Position);

   function Add (Container : Sequence; New_Item : Element_Type) return Sequence
   --  Returns a new sequence which contains the same elements as Container
   --  plus New_Item at the end.

   with
     Global => null,
     Pre    => Last (Container) < Index_Type'Last,
     Post   =>
       Last (Add'Result) = Last (Container) + 1
         and then Element_Logic_Equal
           (Get (Add'Result, Last (Add'Result)), Copy_Element (New_Item))
         and then Equal_Prefix (Container, Add'Result);

   function Add
     (Container : Sequence;
      Position  : Index_Type;
      New_Item  : Element_Type) return Sequence
   with
   --  Returns a new sequence which contains the same elements as Container
   --  except that New_Item has been inserted at position Position.

     Global => null,
     Pre    =>
         Last (Container) < Index_Type'Last
         and then Position <= Extended_Index'Succ (Last (Container)),
     Post   =>
       Last (Add'Result) = Last (Container) + 1
         and then Element_Logic_Equal
           (Get (Add'Result, Position), Copy_Element (New_Item))
         and then Range_Equal
                    (Left  => Container,
                     Right => Add'Result,
                     Fst   => Index_Type'First,
                     Lst   => Index_Type'Pred (Position))
         and then Range_Shifted
                    (Left   => Container,
                     Right  => Add'Result,
                     Fst    => Position,
                     Lst    => Last (Container),
                     Offset => 1);

   function Remove
     (Container : Sequence;
      Position : Index_Type) return Sequence
   --  Returns a new sequence which contains the same elements as Container
   --  except that the element at position Position has been removed.

   with
     Global => null,
     Pre    => Position in Index_Type'First .. Last (Container),
     Post   =>
       Last (Remove'Result) = Last (Container) - 1
         and then Range_Equal
                    (Left  => Container,
                     Right => Remove'Result,
                     Fst   => Index_Type'First,
                     Lst   => Index_Type'Pred (Position))
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

   function Iter_First (Container : Sequence) return Extended_Index with
     Global => null;

   function Iter_Has_Element
     (Container : Sequence;
      Position  : Extended_Index) return Boolean
   with
     Global => null,
     Post   =>
       Iter_Has_Element'Result =
         (Position in Index_Type'First .. Last (Container));
   pragma Annotate (GNATprove, Inline_For_Proof, Iter_Has_Element);

   function Iter_Next
     (Container : Sequence;
      Position  : Extended_Index) return Extended_Index
   with
     Global => null,
     Pre    => Iter_Has_Element (Container, Position);

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
      Fst       : Index_Type;
      Lst       : Extended_Index;
      Item      : Element_Type) return Boolean
   --  Returns True if every element of the range from Fst to Lst of Container
   --  is equal to Item.

   with
     Ghost,
     Global => null,
     Pre    => Lst <= Last (Container),
     Post   =>
       Constant_Range'Result =
         (for all I in Fst .. Lst =>
            Element_Logic_Equal (Get (Container, I), Copy_Element (Item)));
   pragma Annotate (GNATprove, Inline_For_Proof, Constant_Range);

   function Equal
     (Left  : Sequence;
      Right : Sequence) return Boolean
   --  Returns True is Left and Right have the same elements using logical
   --  equality to compare elements.

   with
     Ghost,
     Global => null,
     Post   =>
       Equal'Result =
         (Length (Left) = Length (Right)
           and then (for all N in Index_Type'First .. Last (Left) =>
                       Element_Logic_Equal (Get (Left, N), Get (Right, N))));
   pragma Annotate (GNATprove, Inline_For_Proof, Equal);

   function Equal_Prefix
     (Left  : Sequence;
      Right : Sequence) return Boolean
   --  Returns True is Left is a subsequence of Right using logical equality to
   --  compare elements.

   with
     Ghost,
     Global => null,
     Post   =>
       Equal_Prefix'Result =
         (Length (Left) <= Length (Right)
           and then (for all N in Index_Type'First .. Last (Left) =>
                       Element_Logic_Equal (Get (Left, N), Get (Right, N))));
   pragma Annotate (GNATprove, Inline_For_Proof, Equal_Prefix);

   function Equal_Except
     (Left     : Sequence;
      Right    : Sequence;
      Position : Index_Type) return Boolean
   --  Returns True is Left and Right are the same except at position Position

   with
     Ghost,
     Global => null,
     Pre    => Position <= Last (Left),
     Post   =>
       Equal_Except'Result =
         (Length (Left) = Length (Right)
           and then
            (for all I in Index_Type'First .. Last (Left) =>
               (if I /= Position
                then Element_Logic_Equal (Get (Left, I), Get (Right, I)))));
   pragma Annotate (GNATprove, Inline_For_Proof, Equal_Except);

   function Equal_Except
     (Left  : Sequence;
      Right : Sequence;
      X     : Index_Type;
      Y     : Index_Type) return Boolean
   --  Returns True is Left and Right are the same except at positions X and Y

   with
     Ghost,
     Global => null,
     Pre    => X <= Last (Left) and Y <= Last (Left),
     Post   =>
       Equal_Except'Result =
         (Last (Left) = Last (Right)
           and then
            (for all I in Index_Type'First .. Last (Left) =>
               (if I /= X and I /= Y
                then Element_Logic_Equal (Get (Left, I), Get (Right, I)))));
   pragma Annotate (GNATprove, Inline_For_Proof, Equal_Except);

   function Range_Equal
     (Left  : Sequence;
      Right : Sequence;
      Fst   : Index_Type;
      Lst   : Extended_Index) return Boolean
   --  Returns True if the ranges from Fst to Lst contain the same elements in
   --  Left and Right.

   with
     Ghost,
     Global => null,
     Pre    => Lst <= Last (Left) and Lst <= Last (Right),
     Post   =>
       Range_Equal'Result =
         (for all I in Fst .. Lst =>
            Element_Logic_Equal (Get (Left, I), Get (Right, I)));
   pragma Annotate (GNATprove, Inline_For_Proof, Range_Equal);

   function Range_Shifted
     (Left   : Sequence;
      Right  : Sequence;
      Fst    : Index_Type;
      Lst    : Extended_Index;
      Offset : Big_Integer) return Boolean
   --  Returns True if the range from Fst to Lst in Left contains the same
   --  elements as the range from Fst + Offset to Lst + Offset in Right.

   with
     Ghost,
     Global => null,
     Pre    =>
       Lst <= Last (Left)
         and then Big (Index_Type'First) <= Big (Fst) + Offset
         and then Big (Lst) + Offset <= Big (Last (Right)),
     Post   =>
       Range_Shifted'Result =
         (Fst > Lst
          or else
            ((for all I in Fst .. Lst =>
               Element_Logic_Equal
                 (Get (Left, I),
                  Get (Right, Of_Big (Big (I) + Offset))))
             and
               (for all I in Of_Big (Big (Fst) + Offset) ..
                  Of_Big (Big (Lst) + Offset)
                =>
                  Element_Logic_Equal
                    (Get (Left, Of_Big (Big (I) - Offset)),
                     Get (Right, I)))));
   pragma Annotate (GNATprove, Inline_For_Proof, Range_Shifted);

   ------------------------------------------
   -- Additional Primitives For Aggregates --
   ------------------------------------------

   procedure Aggr_Append
     (Container : in out Sequence;
      New_Item  : Element_Type)
   with
     Global => null,
     Pre    => Last (Container) < Index_Type'Last,
     Post   =>
       Last (Container) = Last (Container'Old) + 1
         and then Element_Logic_Equal
           (Get (Container, Last (Container)), Copy_Element (New_Item))
         and then Equal_Prefix (Container'Old, Container);

private

   pragma SPARK_Mode (Off);

   package Containers is new SPARK.Containers.Functional.Base
     (Index_Type   => Index_Type,
      Element_Type => Element_Type);

   type Sequence is record
      Content : Containers.Container;
   end record;

   function Iter_First (Container : Sequence) return Extended_Index is
     (Index_Type'First);

   function Iter_Next
     (Container : Sequence;
      Position  : Extended_Index) return Extended_Index
   is
     (if Position = Extended_Index'Last then
         Extended_Index'First
      else
         Extended_Index'Succ (Position));

   function Iter_Has_Element
     (Container : Sequence;
      Position  : Extended_Index) return Boolean
   is
     (Position in Index_Type'First .. Last (Container));

end SPARK.Containers.Functional.Vectors;
