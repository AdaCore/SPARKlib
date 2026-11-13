--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This spec is derived from package Ada.Containers.Indefinite_Holders in the
--  Ada 2012 RM. The modifications are meant to facilitate formal proofs by
--  making it easier to express properties, and by making the specification of
--  this unit compatible with SPARK 2014. Note that the API of this unit may be
--  subject to incompatible changes as SPARK 2014 evolves.

--  A holder is a container that is either empty or holds exactly one element.
--  The element can be of an indefinite type, such as String or a class-wide
--  type. As for the other unbounded containers, assigning a holder copies its
--  element, and the memory of the element is reclaimed automatically through
--  finalization. Unlike in Ada.Containers.Indefinite_Holders, Empty_Holder is
--  a function, Constant_Reference and Reference return access values, and
--  there is no Query_Element or Update_Element.

--  The preconditions in this unit protect from Constraint_Error but not from
--  Storage_Error. They can be enabled at run time using SPARKlib_Defensive.
--  When they are disabled, Constraint_Error is raised instead. Postconditions
--  are intended for analysis only.

pragma Ada_2022;

with SPARK.Containers.Parameter_Checks;

private with SPARK.Containers.Formal.Holders;

generic
   type Element_Type (<>) is private;
   with function "=" (Left, Right : Element_Type) return Boolean is <>;

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

package SPARK.Containers.Formal.Unbounded_Holders with
    SPARK_Mode,
    Always_Terminates
is
   pragma Annotate (CodePeer, Skip_Analysis);

   type Holder is private
   with Default_Initial_Condition => (SPARKlib_Full => Is_Empty (Holder));
   --  The default value of a holder is empty

   function Is_Empty (Container : Holder) return Boolean
   with Global => null;
   --  Return True if Container holds no element

   package Formal_Model
     with Ghost => SPARKlib_Logic
   is

      --------------------------
      -- Instantiation Checks --
      --------------------------

      package Eq_Checks is new
        SPARK.Containers.Parameter_Checks.Equivalence_Checks
          (T                   => Element_Type,
           Eq                  => "=",
           Param_Eq_Reflexive  => Eq_Reflexive,
           Param_Eq_Symmetric  => Eq_Symmetric,
           Param_Eq_Transitive => Eq_Transitive);
      --  Check that the actual parameter for "=" is an equivalence relation

      ------------------
      -- Formal Model --
      ------------------

      --  The model of a holder is given by Is_Empty and, for a holder which
      --  is not empty, by Element. The contracts of the other subprograms of
      --  this unit are expressed in terms of these two functions.

      function Element_Logic_Equal (Left, Right : Element_Type) return Boolean
      with
        Ghost    => SPARKlib_Full,
        Global   => null,
        Annotate => (GNATprove, Logical_Equal);
      --  Logical equality on elements

      function Copy_Element (Item : Element_Type) return Element_Type
      is (Item)
      with Annotate => (GNATprove, Inline_For_Proof);
      --  Elements of holders are copied by several primitives of this unit.
      --  This function causes GNATprove to verify that such a copy is valid
      --  (in particular, it does not break the ownership policy of SPARK,
      --  i.e. it does not contain pointers that could be used to alias
      --  mutable data).
      --  This function is also used to model the value of new elements.
      --  Indeed, a copy of an object might not be logically equal to the
      --  object, in particular in case of view conversions of tagged types.

   end Formal_Model;
   use Formal_Model;

   function Element (Container : Holder) return Element_Type
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => not Is_Empty (Container));
   --  Return a copy of the element held by Container

   function Empty_Holder return Holder
   with
     Global => null,
     Post   => (SPARKlib_Full => Is_Empty (Empty_Holder'Result));
   --  Return a holder which is empty

   function To_Holder (New_Item : Element_Type) return Holder
   with
     Global => null,
     Post   =>
       (SPARKlib_Full =>
          not Is_Empty (To_Holder'Result)
          and then
            Element_Logic_Equal
              (Element (To_Holder'Result), Copy_Element (New_Item)));
   --  Return a holder whose element is a copy of New_Item

   function "=" (Left, Right : Holder) return Boolean
   with
     Global => null,
     Post   =>
       (SPARKlib_Full =>
          "="'Result
          = (if Is_Empty (Left)
             then Is_Empty (Right)
             else
               not Is_Empty (Right)
               and then Element (Left) = Element (Right)));
   --  Return True if Left and Right are both empty, or if they both hold an
   --  element and these elements are equal according to the "=" parameter of
   --  the instance.

   function Copy (Source : Holder) return Holder
   with
     Global => null,
     Post   =>
       (SPARKlib_Full =>
          Is_Empty (Copy'Result) = Is_Empty (Source)
          and then
            (if not Is_Empty (Source)
             then
               Element_Logic_Equal (Element (Copy'Result), Element (Source))));
   --  Return a holder whose element, if any, is a copy of the element of
   --  Source. This is equivalent to an assignment.

   procedure Assign (Target : in out Holder; Source : Holder)
   with
     Global => null,
     Post   =>
       (SPARKlib_Full =>
          Is_Empty (Target) = Is_Empty (Source)
          and then
            (if not Is_Empty (Source)
             then Element_Logic_Equal (Element (Target), Element (Source))));
   --  Replace the content of Target by a copy of the content of Source. This
   --  is equivalent to an assignment.

   procedure Replace_Element
     (Container : in out Holder; New_Item : Element_Type)
   with
     Global => null,
     Post   =>
       (SPARKlib_Full =>
          not Is_Empty (Container)
          and then
            Element_Logic_Equal
              (Element (Container), Copy_Element (New_Item)));
   --  Replace the content of Container by a copy of New_Item

   procedure Clear (Container : in out Holder)
   with Global => null, Post => (SPARKlib_Full => Is_Empty (Container));
   --  Remove the element of Container, if any

   procedure Move (Target : in out Holder; Source : in out Holder)
   with
     Global => null,
     Post   =>
       (SPARKlib_Full =>
          Is_Empty (Source)
          and then Is_Empty (Target) = Is_Empty (Source'Old)
          and then
            (if not Is_Empty (Target)
             then
               Element_Logic_Equal (Element (Target), Element (Source'Old))));
   --  Move the content of Source to Target, without copying the element.
   --  Source is empty after the call.

   procedure Swap (Left, Right : in out Holder)
   with
     Global => null,
     Post   =>
       (SPARKlib_Full =>
          Is_Empty (Left) = Is_Empty (Right'Old)
          and then Is_Empty (Right) = Is_Empty (Left'Old)
          and then
            (if not Is_Empty (Left)
             then Element_Logic_Equal (Element (Left), Element (Right'Old)))
          and then
            (if not Is_Empty (Right)
             then Element_Logic_Equal (Element (Right), Element (Left'Old))));
   --  Exchange the contents of Left and Right, without copying the elements

   function At_End (E : Holder) return Holder
   is (E)
   with Ghost => SPARKlib_Full, Annotate => (GNATprove, At_End_Borrow);

   function At_End
     (E : access constant Element_Type) return access constant Element_Type
   is (E)
   with Ghost => SPARKlib_Full, Annotate => (GNATprove, At_End_Borrow);

   function Constant_Reference
     (Container : Holder) return not null access constant Element_Type
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => not Is_Empty (Container)),
     Post   =>
       (SPARKlib_Full =>
          Element_Logic_Equal
            (Constant_Reference'Result.all, Element (Container)));
   --  Return a read-only access to the element of Container. It can be used
   --  to read the element, or one of its parts, without copying it.

   function Reference (Container : Holder) return not null access Element_Type
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => not Is_Empty (Container)),
     Post   =>
       (SPARKlib_Full =>
          not Is_Empty (At_End (Container))

          --  Container will hold Result.all

          and then
            Element_Logic_Equal
              (At_End (Reference'Result).all, Element (At_End (Container))));
   --  Return a read-write access to the element of Container. It can be used
   --  to update the element, or one of its parts, in place. The constraints
   --  and the tag of the element cannot be changed this way.

private
   pragma SPARK_Mode (Off);

   pragma Inline (Is_Empty);
   pragma Inline (Element);

   package Element_Holder_Types is new
     SPARK.Containers.Formal.Holders (Element_Type);
   package EHT renames Element_Holder_Types;

   --  EHT.Holder_Type is a controlled type which copies its element on
   --  assignment and deallocates it on finalization.

   type Holder is record
      Content : EHT.Holder_Type;
   end record;

end SPARK.Containers.Formal.Unbounded_Holders;
