--
--  Copyright (C) 2022-2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Introduce a non executable type for maps with size 0. It can be used to
--  model a ghost subprogram parameter or a ghost component.

generic
   type Key_Type is private;
   No_Key : Key_Type;
   type Object_Type (<>) is private;

package SPARK.Pointers.Abstract_Maps with SPARK_Mode, Always_Terminates
is

   pragma
     Annotate
       (GNATcheck,
        Exempt_On,
        "Restrictions:No_Specification_Of_Aspect => Iterable",
        "The following usage of aspect Iterable has been reviewed"
          & "for compliance with GNATprove assumption"
          & " [SPARK_ITERABLE]");
   type Map is private
   with
     Default_Initial_Condition => Is_Empty (Map),
     Iterable                  =>
       (First => Iter_First, Next => Iter_Next, Has_Element => Has_Key);
   pragma
     Annotate
       (GNATcheck,
        Exempt_Off,
        "Restrictions:No_Specification_Of_Aspect => Iterable");

   function "=" (Left, Right : Map) return Boolean
   with Import, Global => null, Annotate => (GNATprove, Logical_Equal);

   function Empty_Map return Map
   with Global => null, Post => Is_Empty (Empty_Map'Result);

   function Has_Key (M : Map; K : Key_Type) return Boolean
   with Import, Global => null, Post => (if Has_Key'Result then K /= No_Key);

   function Get (M : Map; K : Key_Type) return Object_Type
   with Import, Global => null, Pre => Has_Key (M, K);

   --  For quantification only. Do not use to iterate through the map.
   function Iter_First (M : Map) return Key_Type
   with Global => null, Import;
   function Iter_Next (M : Map; K : Key_Type) return Key_Type
   with Global => null, Import;

   pragma Warnings (Off, "unused variable ""K""");
   function Is_Empty (M : Map) return Boolean
   is (for all K in M => False)
   with Global => null;
   pragma Warnings (On, "unused variable ""K""");

   type Ownership_Map is private
   with Annotate => (GNATprove, Ownership, "Needs_Reclamation");

   function "+" (M : Ownership_Map) return Map
   with Global => null;

   function "=" (Left, Right : Ownership_Map) return Boolean
   is (+Left = +Right);

   pragma Warnings (Off, "unused variable ""K""");
   function Is_Empty (M : Ownership_Map) return Boolean
   is (for all K in "+" (M) => False)
   with Global => null, Annotate => (GNATprove, Ownership, "Is_Reclaimed");
   pragma Warnings (On, "unused variable ""K""");

   function Empty_Map return Ownership_Map
   with Global => null, Post => Is_Empty (Empty_Map'Result);

   --  Keys and elements of abstract maps are (implicitely) copied in this
   --  package. These functions causes GNATprove to verify that such a copy
   --  is valid (in particular, it does not break the ownership policy of
   --  SPARK, i.e. it does not contain pointers that could be used to alias
   --  mutable data).

   function Copy_Key (K : Key_Type) return Key_Type
   is (K);
   function Copy_Object (O : Object_Type) return Object_Type
   is (O);

private
   pragma SPARK_Mode (Off);

   type Map is null record;

   function Empty_Map return Map
   is ((null record));

   type Ownership_Map is new Map;

   function "+" (M : Ownership_Map) return Map
   is (Map (M));

   function Empty_Map return Ownership_Map
   is ((null record));
end SPARK.Pointers.Abstract_Maps;
