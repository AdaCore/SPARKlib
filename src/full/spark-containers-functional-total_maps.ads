--
--  Copyright (C) 2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

private with SPARK.Containers.Functional.Maps;

with SPARK.Containers.Parameter_Checks;

generic
   type Key_Type (<>) is private;
   type Element_Type (<>) is private;
   Default_Element : Element_Type;

   with
     function Equivalent_Keys
       (Left : Key_Type; Right : Key_Type) return Boolean is "=";
   with function "=" (Left, Right : Element_Type) return Boolean is <>;
   with
     function Equivalent_Elements
       (Left : Element_Type; Right : Element_Type) return Boolean is "=";
   --  Function used to compare elements in Equivalent_Maps

   Enable_Handling_Of_Equivalence : Boolean := True;
   --  This constant should only be set to False when no particular handling
   --  of equivalence over keys is needed, that is, Equivalent_Keys defines a
   --  key uniquely.

   Use_Logical_Equality : Boolean := False;
   --  This constant should only be set to True when "=" is the logical
   --  equality on Element_Type.

   --  Ghost lemma to prove that "=" is the logical equality. It only matters
   --  if Use_Logical_Equality is True.

   with
     procedure Eq_Logical_Eq (X, Y : Element_Type) is null
     with Ghost => Static;

   --  Ghost lemmas used to prove that "=" is an equivalence relation

   with
     procedure Eq_Reflexive (X : Element_Type) is null
     with Ghost => Static;
   with
     procedure Eq_Symmetric (X, Y : Element_Type) is null
     with Ghost => Static;
   with
     procedure Eq_Transitive (X, Y, Z : Element_Type) is null
     with Ghost => Static;

   --  Ghost lemmas used to prove that Equivalent_Keys is an equivalence
   --  relation.

   with
     procedure Equivalent_Keys_Reflexive (X : Key_Type) is null
     with Ghost => Static;
   with
     procedure Equivalent_Keys_Symmetric (X, Y : Key_Type) is null
     with Ghost => Static;
   with
     procedure Equivalent_Keys_Transitive (X, Y, Z : Key_Type) is null
     with Ghost => Static;

   --  Ghost lemmas used to prove that Equivalent_Elements is an equivalence
   --  relation.

   with
     procedure Equivalent_Elements_Reflexive (X, Y : Element_Type) is null
     with Ghost => Static;
   with
     procedure Equivalent_Elements_Symmetric (X, Y : Element_Type) is null
     with Ghost => Static;
   with
     procedure Equivalent_Elements_Transitive (X, Y, Z : Element_Type) is null
     with Ghost => Static;

package SPARK.Containers.Functional.Total_Maps with
    SPARK_Mode,
    Always_Terminates
is

   --  Local package for renamings to avoid polluting the namespace in user
   --  code.

   package Renamings is

      function "=" (Left : Key_Type; Right : Key_Type) return Boolean
      is (Equivalent_Keys (Left, Right))
      with Annotate => (GNATprove, Inline_For_Proof);
      --  Predefined equality on keys is never used in this package. Rename
      --  Equivalent_Keys instead.

   end Renamings;

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
     Default_Initial_Condition => (SPARKlib_Full => All_Default (Map)),
     Iterable                  =>
       (First       => Iter_First,
        Next        => Iter_Next,
        Has_Element => Iter_Has_Element,
        Element     => Iter_Element),
     Aggregate                 =>
       (Empty => Default_Map, Add_Named => Aggr_Include),
     Annotate                  =>
       (GNATprove, Container_Aggregates, "Predefined_Maps");
   pragma
     Annotate
       (GNATcheck,
        Exempt_Off,
        "Restrictions:No_Specification_Of_Aspect => Iterable");
   --  All keys map to Default_Element when default initialized.
   --  "For in" quantification over maps should not be used.
   --  "For of" quantification over maps iterates over keys.
   --  Set works modulo equivalence on keys: all equivalent keys share the same
   --  element. As equivalence classes might be infinite, quantification over
   --  the keys of a map is infinite. Thus, quantified expressions cannot be
   --  executed and should only be used in disabled ghost code. This is
   --  enforced by using the SPARKlib_Full assertion level.

   -----------------------
   --  Basic operations --
   -----------------------

   --  Total maps are axiomatized using Get, encoding an accessor to
   --  elements associated with its keys.

   function Get (Container : Map; Key : Key_Type) return Element_Type
   with
     --  Return the element associated with Key in Container

     Global   => null,
     Annotate => (GNATprove, Container_Aggregates, "Get");

   procedure Lemma_Get_Equivalent (Container : Map; Key_1, Key_2 : Key_Type)
   with
     Ghost    => SPARKlib_Full,
     Global   => null,
     Annotate => (GNATprove, Automatic_Instantiation),
     Pre      =>
       Enable_Handling_Of_Equivalence and then Equivalent_Keys (Key_1, Key_2),
     Post     =>
       Element_Logic_Equal (Get (Container, Key_1), Get (Container, Key_2));
   --  Get returns the same result on all equivalent keys

   ------------------------
   -- Property Functions --
   ------------------------

   function "=" (Left : Map; Right : Map) return Boolean
   with
     --  Extensional equality over maps

     Global => null,
     Post   =>
       (Static =>
          "="'Result
          = (for all Key of Left => Get (Right, Key) = Get (Left, Key)));

   procedure Lemma_Eq_Extensional (Left : Map; Right : Map)
   with
     Ghost    => Static,
     Global   => null,
     Annotate => (GNATprove, Automatic_Instantiation),
     Pre      => Use_Logical_Equality,
     Post     => (Left = Right) = Logical_Eq (Left, Right);
   --  If Use_Logical_Equality is True, then "=" is the logical equality

   -----------------------------------------------------
   -- Properties handling elements modulo equivalence --
   -----------------------------------------------------

   function Equivalent_Maps (Left : Map; Right : Map) return Boolean
   with
     --  Equivalence over maps

     Global => null,
     Post   =>
       (Static =>
          Equivalent_Maps'Result
          = (for all Key of Left =>
               Equivalent_Elements (Get (Right, Key), Get (Left, Key))));

   ----------------------------
   -- Construction Functions --
   ----------------------------

   --  For better efficiency of both proofs and execution, avoid using
   --  construction functions in annotations and rather use property functions.

   function Default_Map return Map
   with
     --  Return a Map where all keys are mapped to the default element

     Global => null,
     Post   => (SPARKlib_Full => All_Default (Default_Map'Result));

   function Set
     (Container : Map; Key : Key_Type; New_Item : Element_Type) return Map
   with
     Global => null,
     Post   =>
       (SPARKlib_Full =>
          Element_Logic_Equal (Get (Set'Result, Key), Copy_Element (New_Item))
          and Elements_Equal_Except (Container, Set'Result, Key));
   --  Returns Container, where the element associated with the equivalence
   --  class of Key has been replaced by New_Item.

   -------------------------------------------------------------------------
   -- Ghost non-executable properties used only in internal specification --
   -------------------------------------------------------------------------

   --  Logical equality on elements cannot be safely executed on most element
   --  types. Thus, this package should only be instantiated with ghost code
   --  disabled. This is enforced by using the SPARKlib_Full assertion level.

   function Element_Logic_Equal (Left, Right : Element_Type) return Boolean
   with
     Ghost    => SPARKlib_Full,
     Global   => null,
     Annotate => (GNATprove, Logical_Equal);

   function All_Default (Container : Map) return Boolean
   with
     --  All keys in Container are mapped to Default_Element

     Ghost  => SPARKlib_Full,
     Global => null,
     Post   =>
       (Static =>
          All_Default'Result
          = (for all Key of Container =>
               Element_Logic_Equal
                 (Get (Container, Key), Copy_Element (Default_Element))));

   function Logical_Eq (Left, Right : Map) return Boolean
   with
     Ghost    => Static,
     Global   => null,
     Annotate => (GNATprove, Logical_Equal);
   --  Logical equality over maps

   function Elements_Equal_Except
     (Left : Map; Right : Map; New_Key : Key_Type) return Boolean
   with
     Ghost  => SPARKlib_Full,
     Global => null,
     Post   =>
       (Static =>
          Elements_Equal_Except'Result
          = (for all Key of Left =>
               (if not Equivalent_Keys (Key, New_Key)
                then
                  Element_Logic_Equal (Get (Left, Key), Get (Right, Key)))));
   --  Returns True if all the keys of Left are mapped to the same elements in
   --  Left and Right except the equivalence class of New_Key.

   function Elements_Equal_Except
     (Left : Map; Right : Map; X : Key_Type; Y : Key_Type) return Boolean
   with
     Ghost  => SPARKlib_Full,
     Global => null,
     Post   =>
       (Static =>
          Elements_Equal_Except'Result
          = (for all Key of Left =>
               (if not Equivalent_Keys (Key, X)
                  and not Equivalent_Keys (Key, Y)
                then
                  Element_Logic_Equal (Get (Left, Key), Get (Right, Key)))));
   --  Returns True if all the keys of Left are mapped to the same elements in
   --  Left and Right except the equivalence classes of X and Y.

   --------------------------
   -- Instantiation Checks --
   --------------------------

   --  Check that the actual parameters follow the appropriate assumptions.

   function Copy_Key (Key : Key_Type) return Key_Type
   is (Key);
   function Copy_Element (Item : Element_Type) return Element_Type
   is (Item)
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
       (T                    => Element_Type,
        Eq                   => "=",
        Param_Eq_Reflexive   => Eq_Reflexive,
        Param_Eq_Symmetric   => Eq_Symmetric,
        Param_Eq_Transitive  => Eq_Transitive,
        Use_Logical_Equality => Use_Logical_Equality,
        Param_Eq_Logical_Eq  => Eq_Logical_Eq);
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

   function Iter_First (Unused_Container : Map) return Private_Key
   with Ghost => Static, Global => null;

   function Iter_Has_Element
     (Unused_Container : Map; Unused_Key : Private_Key) return Boolean
   with Ghost => Static, Global => null;

   function Iter_Next
     (Unused_Container : Map; Unused_Key : Private_Key) return Private_Key
   with
     Ghost  => Static,
     Global => null,
     Pre    => Iter_Has_Element (Unused_Container, Unused_Key);

   function Iter_Element
     (Unused_Container : Map; Unused_Key : Private_Key) return Key_Type
   with
     Ghost  => Static,
     Global => null,
     Pre    => Iter_Has_Element (Unused_Container, Unused_Key);

   function Iter_Contains
     (Unused_Container : Map; Unused_Key : Key_Type) return Boolean
   is (True)
   with
     Ghost    => Static,
     Global   => null,
     Annotate => (GNATprove, Inline_For_Proof),
     Annotate => (GNATprove, Iterable_For_Proof, "Contains");

   ------------------------------------------
   -- Additional Primitives For Aggregates --
   ------------------------------------------

   function Aggr_Eq_Keys (Left, Right : Key_Type) return Boolean
   is (Equivalent_Keys (Left, Right))
   with
     Global   => null,
     Ghost    => Static,
     Annotate => (GNATprove, Inline_For_Proof),
     Annotate => (GNATprove, Container_Aggregates, "Equivalent_Keys");

   function Aggr_Default_Item return Element_Type
   is (Default_Element)
   with
     Global   => null,
     Ghost    => Static,
     Annotate => (GNATprove, Inline_For_Proof),
     Annotate => (GNATprove, Container_Aggregates, "Default_Item");

   procedure Aggr_Include
     (Container : in out Map; New_Key : Key_Type; New_Item : Element_Type)
   with
     Global => null,
     Post   =>
       (SPARKlib_Full =>
          Element_Logic_Equal
            (Get (Container, New_Key), Copy_Element (New_Item))
          and Elements_Equal_Except (Container'Old, Container, New_Key));

private

   pragma SPARK_Mode (Off); --  #BODYMODE

   package Maps is new
     SPARK.Containers.Functional.Maps
       (Key_Type                       => Key_Type,
        Element_Type                   => Element_Type,
        Equivalent_Keys                => Equivalent_Keys,
        "="                            => "=",
        Equivalent_Elements            => Equivalent_Elements,
        Enable_Handling_Of_Equivalence => Enable_Handling_Of_Equivalence,
        Eq_Reflexive                   => Eq_Reflexive,
        Eq_Symmetric                   => Eq_Symmetric,
        Eq_Transitive                  => Eq_Transitive,
        Equivalent_Keys_Reflexive      => Equivalent_Keys_Reflexive,
        Equivalent_Keys_Symmetric      => Equivalent_Keys_Symmetric,
        Equivalent_Keys_Transitive     => Equivalent_Keys_Transitive,
        Equivalent_Elements_Reflexive  => Equivalent_Elements_Reflexive,
        Equivalent_Elements_Symmetric  => Equivalent_Elements_Symmetric,
        Equivalent_Elements_Transitive => Equivalent_Elements_Transitive);

   type Map is record
      Content : Maps.Map;
   end record;

   function Get (Container : Map; Key : Key_Type) return Element_Type
   is (if Maps.Has_Key (Container.Content, Key)
       then Maps.Get (Container.Content, Key)
       else Default_Element);

   type Private_Key is null record;

end SPARK.Containers.Functional.Total_Maps;
