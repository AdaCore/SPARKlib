--
--  Copyright (C) 2023-2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Introduce a non executable type for sets with size 0. It can be used to
--  model a ghost subprogram parameter or a ghost component.

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
     Default_Initial_Condition => Is_Empty (Set),
     Iterable                  =>
       (First => Iter_First, Next => Iter_Next, Has_Element => Contains);
   pragma
     Annotate
       (GNATcheck,
        Exempt_Off,
        "Restrictions:No_Specification_Of_Aspect => Iterable");

   --  For quantification only. Do not use to iterate through the set
   function Iter_First (S : Set) return Element_Type
   with Global => null, Import;
   function Iter_Next (S : Set; E : Element_Type) return Element_Type
   with Global => null, Import;

   function Contains (S : Set; E : Element_Type) return Boolean
   with
     Import,
     Global => null,
     Post   => (if Contains'Result then E /= No_Element);

   function "=" (Left, Right : Set) return Boolean
   with Import, Global => null, Annotate => (GNATprove, Logical_Equal);

   pragma Warnings (Off, "unused variable ""E""");
   function Is_Empty (S : Set) return Boolean
   is (for all E in S => False)
   with Global => null;
   pragma Warnings (On, "unused variable ""E""");

   function Empty_Set return Set
   with Global => null, Post => Is_Empty (Empty_Set'Result);

   function Element_Logic_Equal (E1, E2 : Element_Type) return Boolean
   with Import, Ghost, Global => null, Annotate => (GNATprove, Logical_Equal);

   function Singleton (E : Element_Type) return Set
   with
     Global => null,
     Pre    => E /= No_Element,
     Post   =>
       (for all F in Singleton'Result =>
          Element_Logic_Equal (F, Copy_Element (E)))
       and Contains (Singleton'Result, E);

   --  Elements implements simple set comprehension. It constructs the set of
   --  all elements on which Choose returns True.

   function Elements
     (Choose : not null access function (E : Element_Type) return Boolean)
      return Set
   with
     Global   => null,
     Pre      => not Choose (No_Element),
     Post     => (for all E in Elements'Result => Choose (E)),
     Annotate => (GNATprove, Higher_Order_Specialization);

   procedure All_Elements_Chosen
     (Choose : not null access function (E : Element_Type) return Boolean;
      E      : Element_Type)
   with
     Ghost,
     Global   => null,
     Pre      => not Choose (No_Element) and Choose (E),
     Post     => Contains (Elements (Choose), E),
     Annotate => (GNATprove, Automatic_Instantiation),
     Annotate => (GNATprove, Higher_Order_Specialization);

   --  Elements of abstract sets are (implicitely) copied in this
   --  package. Tihs function causes GNATprove to verify that such a copy
   --  is valid (in particular, it does not break the ownership policy of
   --  SPARK, i.e. it does not contain pointers that could be used to alias
   --  mutable data).

   function Copy_Element (E : Element_Type) return Element_Type
   is (E);

private
   pragma SPARK_Mode (Off);

   type Set is null record;

   function Empty_Set return Set
   is ((null record));

   function Singleton (E : Element_Type) return Set
   is ((null record));

end SPARK.Pointers.Abstract_Sets;
