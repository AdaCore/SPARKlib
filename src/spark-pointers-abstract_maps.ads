--
--  Copyright (C) 2022-2026, AdaCore
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
     Default_Initial_Condition => (Static => Is_Empty (Map)),
     Iterable                  =>
       (First => Iter_First, Next => Iter_Next, Has_Element => Has_Key),
     Annotate                  =>
       (GNATprove, Predefined_Equality, "No_Equality");
   pragma
     Annotate
       (GNATcheck,
        Exempt_Off,
        "Restrictions:No_Specification_Of_Aspect => Iterable");

   function "=" (Left, Right : Map) return Boolean is abstract;
   --  Maps have no content at run time, so the predefined equality would
   --  return True on any two maps. Use Logical_Eq below instead.

   function Logical_Eq (Left, Right : Map) return Boolean
   with
     Global   => null,
     Ghost    => Static,
     Import,
     Annotate => (GNATprove, Logical_Equal);

   function Empty_Map return Map
   with Global => null, Post => (Static => Is_Empty (Empty_Map'Result));

   function Has_Key (M : Map; K : Key_Type) return Boolean
   with
     Global => null,
     Ghost  => Static,
     Import,
     Post   => (if Has_Key'Result then K /= No_Key);

   function Get
     (M : Map; K : Key_Type) return not null access constant Object_Type
   with Global => null, Ghost => Static, Import, Pre => Has_Key (M, K);

   --  For quantification only. Do not use to iterate through the map.
   function Iter_First (M : Map) return Key_Type
   with Global => null, Import, Ghost => Static;
   function Iter_Next (M : Map; K : Key_Type) return Key_Type
   with Global => null, Import, Ghost => Static;

   function Is_Empty (M : Map) return Boolean
   is (for all K in M => False)
   with Global => null, Ghost => Static;

   --  A map subject to ownership with reclamation checks: assignment moves it,
   --  and a reclamation check is emitted when it goes out of scope.

   type Owning_Map_Needs_Reclamation is private
   with
     Default_Initial_Condition =>
       (Static => Is_Empty (Owning_Map_Needs_Reclamation)),
     Annotate                  => (GNATprove, Ownership, "Needs_Reclamation"),
     Annotate                  =>
       (GNATprove, Predefined_Equality, "No_Equality");

   function "=" (Left, Right : Owning_Map_Needs_Reclamation) return Boolean
   is abstract;

   function "+" (M : Owning_Map_Needs_Reclamation) return Map
   with Global => null;

   function Logical_Eq
     (Left, Right : Owning_Map_Needs_Reclamation) return Boolean
   is (Logical_Eq (+Left, +Right))
   with Global => null, Ghost => Static;

   function Is_Empty (M : Owning_Map_Needs_Reclamation) return Boolean
   is (for all K in "+" (M) => False)
   with
     Global   => null,
     Annotate => (GNATprove, Ownership, "Is_Reclaimed"),
     Ghost    => Static;

   function Empty_Map return Owning_Map_Needs_Reclamation
   with Global => null, Post => (Static => Is_Empty (Empty_Map'Result));

   --  A map subject to ownership but with no reclamation checks: assignment
   --  moves it, so there is never a second name for one map, and no
   --  reclamation check is emitted when it goes out of scope. Use the flavor
   --  above for a map that must be emptied before it dies.

   type Owning_Map is private
   with
     Default_Initial_Condition => (Static => Is_Empty (Owning_Map)),
     Annotate                  => (GNATprove, Ownership),
     Annotate                  =>
       (GNATprove, Predefined_Equality, "No_Equality");

   function "=" (Left, Right : Owning_Map) return Boolean is abstract;

   function "+" (M : Owning_Map) return Map
   with Global => null;

   function Logical_Eq (Left, Right : Owning_Map) return Boolean
   is (Logical_Eq (+Left, +Right))
   with Global => null, Ghost => Static;

   function Is_Empty (M : Owning_Map) return Boolean
   is (for all K in "+" (M) => False)
   with Global => null, Ghost => Static;

   function Empty_Map return Owning_Map
   with Global => null, Post => (Static => Is_Empty (Empty_Map'Result));

   --  Keys are copied by this package, they should not be subject to ownership

   function Copy_Key (K : Key_Type) return Key_Type
   is (K)
   with Global => null;

private
   pragma SPARK_Mode (Off);

   type Map is null record;

   function Empty_Map return Map
   is ((null record));

   type Owning_Map_Needs_Reclamation is record
      M : Map;
   end record;

   function "+" (M : Owning_Map_Needs_Reclamation) return Map
   is (M.M);

   function Empty_Map return Owning_Map_Needs_Reclamation
   is (M => (null record));

   type Owning_Map is record
      M : Map;
   end record;

   function "+" (M : Owning_Map) return Map
   is (M.M);

   function Empty_Map return Owning_Map
   is (M => (null record));
end SPARK.Pointers.Abstract_Maps;
