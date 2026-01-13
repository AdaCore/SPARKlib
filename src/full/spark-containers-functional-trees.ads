--
--  Copyright (C) 2025, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with SPARK.Big_Integers; use SPARK.Big_Integers;
with SPARK.Containers.Types;
with SPARK.Containers.Parameter_Checks;

private with Ada.Finalization;
private with SPARK.Containers.Functional.Holder;

generic
   type Way_Type is (<>);
   type Element_Type (<>) is private;

   with function "=" (Left, Right : Element_Type) return Boolean is <>;

   Use_Logical_Equality : Boolean := False;

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

package SPARK.Containers.Functional.Trees with SPARK_Mode, Always_Terminates
is

   type Tree is private
   with Default_Initial_Condition => (SPARKlib_Full => Is_Empty (Tree));
   --  No quantification is provided for the elements of a tree. Instead, it is
   --  possible to create a recursive function that returns a functional set
   --  containing all the elements of the tree.

   -----------------------
   --  Basic operations --
   -----------------------

   --  Trees are axiomatized using Empty_Tree, which is the unique tree with
   --  no element, get, which returns the value stored at the root of a
   --  non-empty tree, and Child, which returns the child tree associated with
   --  a given direction in a non-empty tree.

   function Empty_Tree return Tree
   with Global => null;

   function Is_Empty (Container : Tree) return Boolean
   with
     Global   => null,
     Post     =>
       (Static => Is_Empty'Result = Tree_Logic_Equal (Container, Empty_Tree)),
     Annotate => (GNATprove, Inline_For_Proof);

   function Get (Container : Tree) return Element_Type
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => not Is_Empty (Container));

   function Child (Container : Tree; W : Way_Type) return Tree
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => not Is_Empty (Container));

   ------------------------
   -- Property Functions --
   ------------------------

   function "=" (Left, Right : Tree) return Boolean
   with
     Global => null,
     Post   =>
       (SPARKlib_Full =>
          "="'Result
          = (Is_Empty (Left) = Is_Empty (Right)
             and then
               (if not Is_Empty (Left)
                then
                  Get (Left) = Get (Right)
                  and then
                    (for all W in Way_Type =>
                       Child (Left, W) = Child (Right, W)))));

   procedure Lemma_Eq_Reflexive (X : Tree)
   with
     Ghost    => SPARKlib_Full,
     Global   => null,
     Pre      => not Use_Logical_Equality,
     Post     => X = X,
     Annotate => (GNATprove, Automatic_Instantiation);

   procedure Lemma_Eq_Symmetric (X, Y : Tree)
   with
     Ghost    => SPARKlib_Full,
     Global   => null,
     Pre      => not Use_Logical_Equality,
     Post     => (X = Y) = (Y = X),
     Annotate => (GNATprove, Automatic_Instantiation);

   procedure Lemma_Eq_Transtive (X, Y, Z : Tree)
   with
     Ghost    => SPARKlib_Full,
     Global   => null,
     Pre      => not Use_Logical_Equality,
     Post     => (if X = Y and Y = Z then X = Z),
     Annotate => (GNATprove, Automatic_Instantiation);

   procedure Lemma_Eq_Extensional (X, Y : Tree)
   with
     Ghost    => SPARKlib_Full,
     Global   => null,
     Pre      => Use_Logical_Equality,
     Post     => (X = Y) = Tree_Logic_Equal (X, Y),
     Annotate => (GNATprove, Automatic_Instantiation);

   function Height (Container : Tree) return Big_Natural
   with
     Global => null,
     Post   =>
       (SPARKlib_Full =>
          (Height'Result = 0) = Is_Empty (Container)
          and then
            (if not Is_Empty (Container)
             then
               (for all W in Way_Type =>
                  Height'Result > Height (Child (Container, W)))
               and
                 (for some W in Way_Type =>
                    Height'Result = Height (Child (Container, W)) + 1)));

   function Count (Container : Tree) return Big_Natural
   with
     Global => null,
     Post   =>
       (SPARKlib_Full =>
          (Count'Result = 0) = Is_Empty (Container)
          and then
            (if not Is_Empty (Container)
             then
               Count'Result = 1 + Count_Children (Container, Way_Type'First)));

   ----------------------------
   -- Construction Functions --
   ----------------------------

   --  For better efficiency of both proofs and execution, avoid using
   --  construction functions in annotations and rather use property functions.

   type Tree_Array is array (Way_Type range <>) of Tree;

   function Create (Item : Element_Type) return Tree
   with
     Global => null,
     Post   =>
       (SPARKlib_Full =>
          not Is_Empty (Create'Result)
          and then
            Element_Logic_Equal (Get (Create'Result), Copy_Element (Item))
          and then
            (for all W in Way_Type => Is_Empty (Child (Create'Result, W))));

   function Create (Item : Element_Type; Children : Tree_Array) return Tree
   with
     Global => null,
     Post   =>
       (SPARKlib_Full =>
          not Is_Empty (Create'Result)
          and then
            Element_Logic_Equal (Get (Create'Result), Copy_Element (Item))
          and then
            (for all W in Way_Type =>
               (if W in Children'Range
                then Tree_Logic_Equal (Child (Create'Result, W), Children (W))
                else Is_Empty (Child (Create'Result, W)))));

   function Set_Child
     (Container : Tree; Way : Way_Type; New_Child : Tree) return Tree
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => not Is_Empty (Container)),
     Post   =>
       (SPARKlib_Full =>
          not Is_Empty (Set_Child'Result)
          and then
            Element_Logic_Equal (Get (Set_Child'Result), Get (Container))
          and then Tree_Logic_Equal (Child (Set_Child'Result, Way), New_Child)
          and then
            (for all W in Way_Type =>
               (if Way /= W
                then
                  Tree_Logic_Equal
                    (Child (Set_Child'Result, W), Child (Container, W)))));

   function Set_Root (Container : Tree; Item : Element_Type) return Tree
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => not Is_Empty (Container)),
     Post   =>
       (SPARKlib_Full =>
          not Is_Empty (Set_Root'Result)
          and then
            Element_Logic_Equal (Get (Set_Root'Result), Copy_Element (Item))
          and then
            (for all W in Way_Type =>
               Tree_Logic_Equal
                 (Child (Set_Root'Result, W), Child (Container, W))));

   -------------------------------------------------------------------------
   -- Ghost non-executable properties used only in internal specification --
   -------------------------------------------------------------------------

   function Tree_Logic_Equal (Left, Right : Tree) return Boolean
   with
     Ghost    => SPARKlib_Full,
     Global   => null,
     Annotate => (GNATprove, Logical_Equal);

   function Element_Logic_Equal (Left, Right : Element_Type) return Boolean
   with
     Ghost    => SPARKlib_Full,
     Global   => null,
     Annotate => (GNATprove, Logical_Equal);

   function Count_Children
     (Container : Tree; Way : Way_Type) return Big_Natural
   with
     --  Helper function for Count. Sum the number of elements in children of T
     --  in a recursive way, starting at Way.

     Ghost  => SPARKlib_Full,
     Global => null,
     Pre    => not Is_Empty (Container),
     Post   =>
       Count_Children'Result
       = Count (Child (Container, Way))
         + (if Way = Way_Type'Last
            then 0
            else Count_Children (Container, Way_Type'Succ (Way)));

   procedure Lemma_Count_Children_Tail (Container : Tree; Way : Way_Type)
   with
     --  Automatically instantiated lemma:
     --  If T has only empty children starting from Way, then Count_Children
     --  (Container, Way) returns 0.

     Ghost    => SPARKlib_Full,
     Global   => null,
     Pre      =>
       not Is_Empty (Container)
       and then
         (for all W in Way .. Way_Type'Last =>
            Is_Empty (Child (Container, W))),
     Post     => Count_Children (Container, Way) = 0,
     Annotate => (GNATprove, Automatic_Instantiation);

   --------------------------
   -- Instantiation Checks --
   --------------------------

   --  Check that the actual parameters follow the appropriate assumptions.

   function Copy_Element (Item : Element_Type) return Element_Type
   is (Item);
   --  Elements of containers are copied by numerous primitives in this
   --  package. This function causes GNATprove to verify that such a copy is
   --  valid (in particular, it does not break the ownership policy of SPARK,
   --  i.e. it does not contain pointers that could be used to alias mutable
   --  data).

   package Eq_Checks is new
     SPARK.Containers.Parameter_Checks.Equivalence_Checks
       (T                   => Element_Type,
        Eq                  => "=",
        Param_Eq_Reflexive  => Eq_Reflexive,
        Param_Eq_Symmetric  => Eq_Symmetric,
        Param_Eq_Transitive => Eq_Transitive);
   --  Check that the actual parameter for "=" is an equivalence relation

private
   pragma SPARK_Mode (Off);

   use SPARK.Containers.Types;

   subtype Positive_Count_Type is Count_Type range 1 .. Count_Type'Last;

   type Reference_Count_Type is new Natural;

   package Element_Holders is new
     SPARK.Containers.Functional.Holder (Element_Type);
   use Element_Holders;

   --  Use a ref counted type to encode the tree structure. Children are
   --  stored in a linked ref counted data-structure, along with elements of
   --  the Way_type type.

   type Tree_Base;

   type Tree_Base_Access is access Tree_Base;

   type Controlled_Tree is new Ada.Finalization.Controlled with record
      T_Access : Tree_Base_Access;
   end record;

   function Create (Container : Tree_Base_Access) return Controlled_Tree
   is (Ada.Finalization.Controlled with T_Access => Container);

   procedure Adjust (Container : in out Controlled_Tree);

   procedure Finalize (Container : in out Controlled_Tree);

   type List_Cell;

   type List_Cell_Access is access List_Cell;

   type Controlled_List is new Ada.Finalization.Controlled with record
      L_Access : List_Cell_Access;
   end record;

   function Create (Container : List_Cell_Access) return Controlled_List
   is (Ada.Finalization.Controlled with L_Access => Container);

   procedure Adjust (Container : in out Controlled_List);

   procedure Finalize (Container : in out Controlled_List);

   --  Use Big_Integer instead of Big_Positive to avoid a finalization error

   type Tree_Base is record
      Reference_Count : Reference_Count_Type;
      Value           : Element_Holder;
      Children        : Controlled_List;
      Count           : Big_Integer := 1;
      Height          : Positive_Count_Type := 1;
   end record;

   type List_Cell is record
      Reference_Count : Reference_Count_Type;
      Way             : Way_Type;
      Tree            : Controlled_Tree;
      Next_Sibling    : Controlled_List;
   end record;

   --  Tree is not directly a controlled type, so reclamation does not risk
   --  failing even if the user adds a predicate on a subtype of Tree.

   type Tree is record
      Base : Controlled_Tree;
   end record;

end SPARK.Containers.Functional.Trees;
