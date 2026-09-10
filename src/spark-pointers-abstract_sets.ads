--
--  Copyright (C) 2023-2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Introduce a non executable type for possibly infinite sets with size 0. It
--  can be used to model a ghost subprogram parameter or a ghost component.

generic
   type Element_Type is private;
   No_Element : Element_Type;

package SPARK.Pointers.Abstract_Sets with SPARK_Mode, Always_Terminates
is

   pragma
     Annotate
       (GNATcheck,
        Exempt_On,
        "Restrictions:No_Specification_Of_Aspect => Iterable",
        "The following usage of aspect Iterable has been reviewed"
        & "for compliance with GNATprove assumption"
        & " [SPARK_ITERABLE]");
   type Set is private
   with
     Default_Initial_Condition => (Static => Is_Empty (Set)),
     Iterable                  =>
       (First => Iter_First, Next => Iter_Next, Has_Element => Contains),
     Annotate                  =>
       (GNATprove, Predefined_Equality, "No_Equality");
   pragma
     Annotate
       (GNATcheck,
        Exempt_Off,
        "Restrictions:No_Specification_Of_Aspect => Iterable");

   function "=" (Left, Right : Set) return Boolean is abstract;
   --  Sets have no content at run time, so the predefined equality would
   --  return True on any two sets. Use Logical_Eq below instead.

   --  For quantification only. Do not use to iterate through the set
   function Iter_First (S : Set) return Element_Type
   with Global => null, Import, Ghost => Static;
   function Iter_Next (S : Set; E : Element_Type) return Element_Type
   with Global => null, Import, Ghost => Static;

   function Contains (S : Set; E : Element_Type) return Boolean
   with
     Global => null,
     Post   => (if Contains'Result then E /= No_Element),
     Import,
     Ghost  => Static;

   function Logical_Eq (Left, Right : Set) return Boolean
   with
     Global   => null,
     Annotate => (GNATprove, Logical_Equal),
     Import,
     Ghost    => Static;

   function Is_Empty (S : Set) return Boolean
   is (for all E in S => False)
   with Global => null, Ghost => Static;

   function Empty_Set return Set
   with Global => null, Post => (Static => Is_Empty (Empty_Set'Result));

   function Element_Logic_Equal (E1, E2 : Element_Type) return Boolean
   with
     Import,
     Ghost    => Static,
     Global   => null,
     Annotate => (GNATprove, Logical_Equal);

   function Singleton (E : Element_Type) return Set
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => E /= No_Element),
     Post   =>
       (Static =>
          (for all F in Singleton'Result =>
             Element_Logic_Equal (F, Copy_Element (E)))
          and Contains (Singleton'Result, Copy_Element (E)));

   function Add (S : Set; E : Element_Type) return Set
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => E /= No_Element),
     Post   =>
       (Static =>
          Contains (Add'Result, Copy_Element (E))
          and (for all F in S => Contains (Add'Result, F))
          and
            (for all F in Add'Result =>
               Element_Logic_Equal (F, Copy_Element (E)) or Contains (S, F)));

   --  Elements implements simple set comprehension. It constructs the set of
   --  all elements on which Choose returns True. Such a set might not be
   --  finite.

   function Elements
     (Choose : not null access function (E : Element_Type) return Boolean)
      return Set
   with
     Global   => null,
     Pre      => (Static => not Choose (No_Element)),
     Post     => (Static => (for all E in Elements'Result => Choose (E))),
     Annotate => (GNATprove, Higher_Order_Specialization);

   procedure All_Elements_Chosen
     (Choose : not null access function (E : Element_Type) return Boolean;
      E      : Element_Type)
   with
     Import,
     Ghost    => Static,
     Global   => null,
     Pre      => (Static => not Choose (No_Element) and Choose (E)),
     Post     => (Static => Contains (Elements (Choose), E)),
     Annotate => (GNATprove, Automatic_Instantiation),
     Annotate => (GNATprove, Higher_Order_Specialization);

   --  Elements of abstract sets are (implicitly) copied in this
   --  package. This function causes GNATprove to verify that such a copy
   --  is valid (in particular, it does not break the ownership policy of
   --  SPARK, i.e. it does not contain pointers that could be used to alias
   --  mutable data).

   function Copy_Element (E : Element_Type) return Element_Type
   is (E)
   with Global => null;

private
   pragma SPARK_Mode (Off);

   type Set is null record;

   function Empty_Set return Set
   is ((null record));

   function Singleton (E : Element_Type) return Set
   is ((null record));

   function Add (S : Set; E : Element_Type) return Set
   is ((null record));

end SPARK.Pointers.Abstract_Sets;
