--
--  Copyright (C) 2016-2025, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

private with SPARK.Containers.Functional.Base;
private with SPARK.Containers.Types;

with SPARK.Big_Integers; use SPARK.Big_Integers;
with SPARK.Containers.Parameter_Checks;

generic
   type Key_Type (<>) is private;
   type Element_Type (<>)  is private;

   with function Equivalent_Keys
     (Left  : Key_Type;
      Right : Key_Type) return Boolean is "=";
   with function "=" (Left, Right : Element_Type) return Boolean is <>;
   with function Equivalent_Elements
     (Left  : Element_Type;
      Right : Element_Type) return Boolean is "=";
   --  Function used to compare elements in Equivalent_Maps

   Enable_Handling_Of_Equivalence : Boolean := True;
   --  This constant should only be set to False when no particular handling
   --  of equivalence over keys is needed, that is, Equivalent_Keys defines a
   --  key uniquely.

   --  Ghost lemmas used to prove that "=" is an equivalence relation

   with procedure Eq_Reflexive (X : Element_Type) is null
     with Ghost;
   with procedure Eq_Symmetric (X, Y : Element_Type) is null
     with Ghost;
   with procedure Eq_Transitive (X, Y, Z : Element_Type) is null
     with Ghost;

   --  Ghost lemmas used to prove that Equivalent_Keys is an equivalence
   --  relation.

   with procedure Equivalent_Keys_Reflexive (X : Key_Type) is null
     with Ghost;
   with procedure Equivalent_Keys_Symmetric (X, Y : Key_Type) is null
     with Ghost;
   with procedure Equivalent_Keys_Transitive (X, Y, Z : Key_Type) is null
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

package SPARK.Containers.Functional.Maps with
  SPARK_Mode,
  Always_Terminates
is

   --  Local package for renamings to avoid polluting the namespace in user
   --  code.

   package Renamings is

      function "="
        (Left  : Key_Type;
         Right : Key_Type) return Boolean
      is
        (Equivalent_Keys (Left, Right))
      with Annotate => (GNATprove, Inline_For_Proof);
      --  Predefined equality on keys is never used in this package. Rename
      --  Equivalent_Keys instead.

   end Renamings;

   pragma Annotate (GNATcheck, Exempt_On,
                    "Restrictions:No_Specification_Of_Aspect => Iterable",
                    "The following usage of aspect Iterable has been reviewed"
                    & "for compliance with GNATprove assumption"
                    & " [SPARK_ITERABLE]");
   type Map is private with
     Default_Initial_Condition => Is_Empty (Map),
     Iterable                  => (First       => Iter_First,
                                   Next        => Iter_Next,
                                   Has_Element => Iter_Has_Element,
                                   Element     => Iter_Element),
     Aggregate                 => (Empty     => Empty_Map,
                                   Add_Named => Aggr_Include),
     Annotate                  =>
       (GNATprove, Container_Aggregates, "Predefined_Maps");
   pragma Annotate (GNATcheck, Exempt_Off,
                    "Restrictions:No_Specification_Of_Aspect => Iterable");
   --  Maps are empty when default initialized.
   --  "For in" quantification over maps should not be used.
   --  "For of" quantification over maps iterates over keys.
   --  Inclusion in a map works modulo equivalence, the whole equivalence class
   --  is included/excluded at once. As equivalence classes might be infinite,
   --  quantification over the keys of a finite map could be infinite. Thus,
   --  quantified expressions cannot be executed and should only be used in
   --  disabled ghost code. This is enforced by having a special imported
   --  procedure Check_Or_Fail that will lead to link-time errors otherwise.

   -----------------------
   --  Basic operations --
   -----------------------

   --  Maps are axiomatized using Has_Key and Get, encoding respectively the
   --  presence of a key in a map and an accessor to elements associated with
   --  its keys. The length of a map is also added to protect Add against
   --  overflows but it is not actually modeled.

   function Has_Key (Container : Map; Key : Key_Type) return Boolean with
     Global   => null,
     Annotate => (GNATprove, Iterable_For_Proof, "Contains"),
     Annotate => (GNATprove, Container_Aggregates, "Has_Key");
   --  Return True if Key is present in Container

   procedure Lemma_Has_Key_Equivalent
     (Container : Map;
      Key       : Key_Type)
   --  Has_Key returns the same result on all equivalent keys
   with
     Ghost,
     Global => null,
     Annotate => (GNATprove, Automatic_Instantiation),
     Pre  => Enable_Handling_Of_Equivalence
       and then not Has_Key (Container, Key),
     Post => (for all K of Container => not Equivalent_Keys (Key, K));

   function Get (Container : Map; Key : Key_Type) return Element_Type with
   --  Return the element associated with Key in Container

     Global   => null,
     Pre      => Has_Key (Container, Key),
     Annotate => (GNATprove, Container_Aggregates, "Get");

   procedure Lemma_Get_Equivalent
     (Container    : Map;
      Key_1, Key_2 : Key_Type)
   --  Get returns the same result on all equivalent keys
   with
     Ghost,
     Global => null,
     Annotate => (GNATprove, Automatic_Instantiation),
     Pre  => Enable_Handling_Of_Equivalence
       and then Equivalent_Keys (Key_1, Key_2)
       and then
         (Has_Key (Container, Key_1) or else Has_Key (Container, Key_2)),
     Post =>
       Element_Logic_Equal (Get (Container, Key_1), Get (Container, Key_2));

   function Choose (Container : Map) return Key_Type with
   --  Return an arbitrary key in container

     Global => null,
     Pre    => not Is_Empty (Container),
     Post   => Has_Key (Container, Choose'Result);

   function Length (Container : Map) return Big_Natural with
     Global   => null,
     Annotate => (GNATprove, Container_Aggregates, "Length");
   --  Return the number of mappings in Container

   ------------------------
   -- Property Functions --
   ------------------------

   function "<=" (Left : Map; Right : Map) return Boolean with
   --  Map inclusion

     Global => null,
     Post   =>
       "<="'Result =
         (for all Key of Left =>
           Has_Key (Right, Key) and then Get (Right, Key) = Get (Left, Key));

   function "=" (Left : Map; Right : Map) return Boolean with
   --  Extensional equality over maps

     Global => null,
     Post   =>
       "="'Result =
         ((for all Key of Left =>
            Has_Key (Right, Key)
              and then Get (Right, Key) = Get (Left, Key))
          and (for all Key of Right => Has_Key (Left, Key)));

   pragma Warnings (Off, "unused variable ""Key""");
   function Is_Empty (Container : Map) return Boolean with
   --  A map is empty if it contains no key

     Global => null,
     Post   => Is_Empty'Result = (for all Key of Container => False)
       and Is_Empty'Result = (Length (Container) = 0);
   pragma Warnings (On, "unused variable ""Key""");

   function Keys_Included (Left : Map; Right : Map) return Boolean
   --  Returns True if every Key of Left is in Right

   with
     Global => null,
     Post   =>
       Keys_Included'Result = (for all Key of Left => Has_Key (Right, Key));

   function Same_Keys (Left : Map; Right : Map) return Boolean
   --  Returns True if Left and Right have the same keys

   with
     Global => null,
     Post   =>
       Same_Keys'Result =
         (Keys_Included (Left, Right)
           and Keys_Included (Left => Right, Right => Left));
   pragma Annotate (GNATprove, Inline_For_Proof, Same_Keys);

   function Keys_Included_Except
     (Left    : Map;
      Right   : Map;
      New_Key : Key_Type) return Boolean
   --  Returns True if Left contains only keys of Right and possibly the
   --  equivalence class of New_Key.

   with
     Global => null,
     Post   =>
       Keys_Included_Except'Result =
         (for all Key of Left =>
           (if not Equivalent_Keys (Key, New_Key) then
               Has_Key (Right, Key)));

   function Keys_Included_Except
     (Left  : Map;
      Right : Map;
      X     : Key_Type;
      Y     : Key_Type) return Boolean
   --  Returns True if Left contains only keys of Right and possibly the
   --  equivalence classes of X and Y.

   with
     Global => null,
     Post   =>
       Keys_Included_Except'Result =
         (for all Key of Left =>
           (if not Equivalent_Keys (Key, X)
              and not Equivalent_Keys (Key, Y)
            then
               Has_Key (Right, Key)));

   -----------------------------------------------------
   -- Properties handling elements modulo equivalence --
   -----------------------------------------------------

   function Equivalent_Maps (Left : Map; Right : Map) return Boolean with
   --  Equivalence over maps

     Global => null,
     Post   =>
       Equivalent_Maps'Result =
         ((for all Key of Left =>
            Has_Key (Right, Key)
              and then Equivalent_Elements (Get (Right, Key), Get (Left, Key)))
           and (for all Key of Right => Has_Key (Left, Key)));

   ----------------------------
   -- Construction Functions --
   ----------------------------

   --  For better efficiency of both proofs and execution, avoid using
   --  construction functions in annotations and rather use property functions.

   function Empty_Map return Map with
   --  Return an empty Map

     Global => null,
     Post   => Is_Empty (Empty_Map'Result);

   function Add
     (Container : Map;
      New_Key   : Key_Type;
      New_Item  : Element_Type) return Map
   --  Returns Container augmented with the mapping K -> New_Item for all
   --  key K in the equivalence class of New_Key.

   with
     Global => null,
     Pre    => not Has_Key (Container, New_Key),
     Post   =>
       Length (Container) + 1 = Length (Add'Result)
         and Has_Key (Add'Result, New_Key)
         and Element_Logic_Equal
           (Get (Add'Result, New_Key), Copy_Element (New_Item))
         and Elements_Equal (Container, Add'Result)
         and Keys_Included_Except (Add'Result, Container, New_Key);

   function Remove
     (Container : Map;
      Key       : Key_Type) return Map
   --  Returns Container without any mapping for the equivalence class of Key

   with
     Global => null,
     Pre    => Has_Key (Container, Key),
     Post   =>
       Length (Container) = Length (Remove'Result) + 1
         and not Has_Key (Remove'Result, Key)
         and Elements_Equal (Remove'Result, Container)
         and Keys_Included_Except (Container, Remove'Result, Key);

   function Set
     (Container : Map;
      Key       : Key_Type;
      New_Item  : Element_Type) return Map
   --  Returns Container, where the element associated with the equivalence
   --  class of Key has been replaced by New_Item.

   with
     Global => null,
     Pre    => Has_Key (Container, Key),
     Post   =>
       Length (Container) = Length (Set'Result)
         and Element_Logic_Equal
           (Get (Set'Result, Key), Copy_Element (New_Item))
         and Same_Keys (Container, Set'Result)
         and Elements_Equal_Except (Container, Set'Result, Key);

   ----------------------------------
   -- Iteration on Functional Maps --
   ----------------------------------

   --  The Iterable aspect can be used to quantify over a functional map.
   --  However, if it is used to create a for loop, it will not allow users to
   --  prove their loops as there is no way to speak about the elements which
   --  have or have not been traversed already in a loop invariant. The
   --  function Iterate returns an object of a type Iterable_Map which can be
   --  used for iteration. The cursor is a functional map containing all the
   --  elements which have not been traversed yet. The current element being
   --  traversed being the result of Choose on this map.

   pragma Annotate (GNATcheck, Exempt_On,
                    "Restrictions:No_Specification_Of_Aspect => Iterable",
                    "The following usage of aspect Iterable has been reviewed"
                    & "for compliance with GNATprove assumption"
                    & " [SPARK_ITERABLE]");
   type Iterable_Map is private with
     Iterable =>
       (First       => First,
        Has_Element => Has_Element,
        Next        => Next,
        Element     => Element);
   pragma Annotate (GNATcheck, Exempt_Off,
                    "Restrictions:No_Specification_Of_Aspect => Iterable");

   function Map_Logic_Equal (Left, Right : Map) return Boolean with
     Ghost,
     Annotate => (GNATprove, Logical_Equal);
   --  Logical equality on maps

   function Iterate (Container : Map) return Iterable_Map with
     Global => null,
     Post   => Map_Logic_Equal (Get_Map (Iterate'Result), Container);
   --  Return an iterator over a functional map

   function Get_Map (Iterator : Iterable_Map) return Map with
     Global => null;
   --  Retrieve the map associated with an iterator

   function Valid_Submap
     (Iterator : Iterable_Map;
      Cursor   : Map) return Boolean
   with
     Global => null,
     Post   =>
         (if Valid_Submap'Result
          then Elements_Equal (Cursor, Get_Map (Iterator)));
   --  Return True on all maps which can be reached by iterating over
   --  Container.

   function Element (Iterator : Iterable_Map; Cursor : Map) return Key_Type
   with
     Global => null,
     Pre    => not Is_Empty (Cursor),
     Post   => Renamings."=" (Element'Result, Choose (Cursor)),
     Annotate => (GNATprove, Inline_For_Proof);
   --  The next element to be considered for the iteration is the result of
   --  choose on Cursor.

   function First (Iterator : Iterable_Map) return Map with
     Global => null,
     Post   => Map_Logic_Equal (First'Result, Get_Map (Iterator))
       and then Valid_Submap (Iterator, First'Result);
   --  In the first iteration, the cursor is the map associated with Iterator

   function Next (Iterator : Iterable_Map; Cursor : Map) return Map with
     Global => null,
     Pre    => Valid_Submap (Iterator, Cursor) and then not Is_Empty (Cursor),
     Post   => Valid_Submap (Iterator, Next'Result)
       and then
         Map_Logic_Equal (Next'Result, Remove (Cursor, Choose (Cursor)));
   --  At each iteration, remove the considered the equivalence class of the
   --  considered key from the Cursor map.

   function Has_Element
     (Iterator : Iterable_Map;
      Cursor   : Map) return Boolean
   with
     Global => null,
     Post   => Has_Element'Result =
       (Valid_Submap (Iterator, Cursor) and then not Is_Empty (Cursor));
   --  Return True on non-empty maps which can be reached by iterating over
   --  Container.

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

   function Elements_Equal (Left, Right : Map) return Boolean
   --  Returns True if all the keys of Left are mapped to the same elements in
   --  Left and Right.

   with
     Ghost,
     Global => null,
     Post   =>
       Elements_Equal'Result =
         (for all Key of Left =>
            Has_Key (Right, Key)
            and then Element_Logic_Equal
               (Get (Left, Key), Get (Right, Key)));

   function Elements_Equal_Except
     (Left    : Map;
      Right   : Map;
      New_Key : Key_Type) return Boolean
   --  Returns True if all the keys of Left are mapped to the same elements in
   --  Left and Right except the equivalence class of New_Key.

   with
     Ghost,
     Global => null,
     Post   =>
       Elements_Equal_Except'Result =
         (for all Key of Left =>
           (if not Equivalent_Keys (Key, New_Key) then
               Has_Key (Right, Key)
                 and then Element_Logic_Equal
                    (Get (Left, Key), Get (Right, Key))));

   function Elements_Equal_Except
     (Left  : Map;
      Right : Map;
      X     : Key_Type;
      Y     : Key_Type) return Boolean
   --  Returns True if all the keys of Left are mapped to the same elements in
   --  Left and Right except the equivalence classes of X and Y.

   with
     Ghost,
     Global => null,
     Post   =>
       Elements_Equal_Except'Result =
         (for all Key of Left =>
           (if not Equivalent_Keys (Key, X)
              and not Equivalent_Keys (Key, Y)
            then
               Has_Key (Right, Key)
                 and then Element_Logic_Equal
                    (Get (Left, Key), Get (Right, Key))));

   function Equal (Left, Right : Map) return Boolean
   --  Returns True if Left and Right have the same keys and these keys are
   --  mapped to the same elements in Left and Right.

   with
     Ghost,
     Global => null,
     Post   =>
       Equal'Result =
         ((for all Key of Left =>
             Has_Key (Right, Key)
             and then Element_Logic_Equal
                (Get (Left, Key), Get (Right, Key)))
          and (for all Key of Right => Has_Key (Left, Key)));

   --------------------------
   -- Instantiation Checks --
   --------------------------

   --  Check that the actual parameters follow the appropriate assumptions.

   function Copy_Key (Key : Key_Type) return Key_Type is (Key);
   function Copy_Element (Item : Element_Type) return Element_Type is (Item)
     with Annotate => (GNATprove, Inline_For_Proof);
   --  Elements and Keys of maps are copied by numerous primitives in this
   --  package. This function causes GNATprove to verify that such a copy is
   --  valid (in particular, it does not break the ownership policy of SPARK,
   --  i.e. it does not contain pointers that could be used to alias mutable
   --  data).
   --  Copy_Element is also used to model the value of new elements after
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

   package Eq_Keys_Checks is new
     SPARK.Containers.Parameter_Checks.Equivalence_Checks
       (T                   => Key_Type,
        Eq                  => Equivalent_Keys,
        Param_Eq_Reflexive  => Equivalent_Keys_Reflexive,
        Param_Eq_Symmetric  => Equivalent_Keys_Symmetric,
        Param_Eq_Transitive => Equivalent_Keys_Transitive);
   --  Check that the actual parameter for Equivalent_Keys is an equivalence
   --  relation.

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
   --  equivalence relation and that it is comptatible with "=".

   --------------------------------------------------
   -- Iteration Primitives Used For Quantification --
   --------------------------------------------------

   type Private_Key is private;

   function Iter_First (Container : Map) return Private_Key with
     Ghost,
     Global => null;

   function Iter_Has_Element
     (Container : Map;
      Key       : Private_Key) return Boolean
   with
     Ghost,
     Global => null;

   function Iter_Next (Container : Map; Key : Private_Key) return Private_Key
   with
     Ghost,
     Global => null,
     Pre    => Iter_Has_Element (Container, Key);

   function Iter_Element (Container : Map; Key : Private_Key) return Key_Type
   with
     Ghost,
     Global => null,
     Pre    => Iter_Has_Element (Container, Key);

   ------------------------------------------
   -- Additional Primitives For Aggregates --
   ------------------------------------------

   function Aggr_Eq_Keys (Left, Right : Key_Type) return Boolean is
     (Equivalent_Keys (Left, Right))
   with
     Global   => null,
     Annotate => (GNATprove, Inline_For_Proof),
     Annotate => (GNATprove, Container_Aggregates, "Equivalent_Keys");

   procedure Aggr_Include
     (Container : in out Map;
      New_Key   : Key_Type;
      New_Item  : Element_Type)
   with
     Global => null,
     Pre    => not Has_Key (Container, New_Key),
     Post   =>
       Length (Container'Old) + 1 = Length (Container)
       and Has_Key (Container, New_Key)
       and Element_Logic_Equal
           (Get (Container, New_Key), Copy_Element (New_Item))
       and Elements_Equal (Container'Old, Container)
       and Keys_Included_Except (Container, Container'Old, New_Key);

private

   pragma SPARK_Mode (Off);

   function "="
     (Left  : Key_Type;
      Right : Key_Type) return Boolean renames Equivalent_Keys;

   use SPARK.Containers.Types;

   subtype Positive_Count_Type is Count_Type range 1 .. Count_Type'Last;

   package Element_Containers is new SPARK.Containers.Functional.Base
     (Element_Type => Element_Type,
      Index_Type   => Positive_Count_Type);
   use all type Element_Containers.Container;

   package Key_Containers is new SPARK.Containers.Functional.Base
     (Element_Type => Key_Type,
      Index_Type   => Positive_Count_Type);
   use all type Key_Containers.Container;

   type Map is record
      Keys     : Key_Containers.Container;
      Elements : Element_Containers.Container;
   end record;

   type Private_Key is new Count_Type;

   ----------------------------------
   -- Iteration on Functional Maps --
   ----------------------------------

   type Iterable_Map is record
      Container : Map;
   end record;

   function Element (Iterator : Iterable_Map; Cursor : Map) return Key_Type is
     (Choose (Cursor));

   function First (Iterator : Iterable_Map) return Map is
     (Iterator.Container);

   function Get_Map (Iterator : Iterable_Map) return Map is
     (Iterator.Container);

   function Has_Element
     (Iterator : Iterable_Map;
      Cursor   : Map) return Boolean
   is
     (Valid_Submap (Iterator, Cursor) and then Length (Cursor) > 0);

   function Iterate (Container : Map) return Iterable_Map is
     (Iterable_Map'(Container => Container));

   function Map_Logic_Equal (Left, Right : Map) return Boolean is
     (Ptr_Eq (Left.Keys, Right.Keys)
      and then Length (Left.Keys) = Length (Right.Keys)
      and then Ptr_Eq (Left.Elements, Right.Elements));

   function Next (Iterator : Iterable_Map; Cursor : Map) return Map is
     (Remove (Cursor, Choose (Cursor)));

   function Valid_Submap
     (Iterator : Iterable_Map;
      Cursor   : Map) return Boolean
   is
     (Ptr_Eq (Cursor.Keys, Iterator.Container.Keys)
      and then Length (Cursor.Keys) <= Length (Iterator.Container.Keys)
      and then Ptr_Eq (Cursor.Elements, Iterator.Container.Elements));

end SPARK.Containers.Functional.Maps;
