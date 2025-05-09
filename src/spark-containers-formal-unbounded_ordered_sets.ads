--
--  Copyright (C) 2022-2025, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with SPARK.Big_Integers;     use SPARK.Big_Integers;
with SPARK.Containers.Functional.Maps;
with SPARK.Containers.Functional.Sets;
with SPARK.Containers.Functional.Vectors;
with SPARK.Containers.Parameter_Checks;
with SPARK.Containers.Types; use SPARK.Containers.Types;

private with Ada.Containers.Red_Black_Trees;
private with Ada.Finalization;
private with SPARK.Containers.Formal.Holders;

generic
   type Element_Type (<>) is private;

   with function "<" (Left, Right : Element_Type) return Boolean is <>;
   with function "=" (Left, Right : Element_Type) return Boolean is <>;

   --  Ghost lemmas used to prove that "=" is an equivalence relation

   with procedure Eq_Reflexive (X : Element_Type) is null
     with Ghost;
   with procedure Eq_Symmetric (X, Y : Element_Type) is null
     with Ghost;
   with procedure Eq_Transitive (X, Y, Z : Element_Type) is null
     with Ghost;

   --  Ghost lemmas used to prove that "<" is a strict weak ordering
   --  relationship.

   with procedure Lt_Irreflexive (X, Y : Element_Type) is null
     with Ghost;
   with procedure Lt_Asymmetric (X, Y : Element_Type) is null
     with Ghost;
   with procedure Lt_Transitive (X, Y, Z : Element_Type) is null
     with Ghost;
   with procedure Lt_Order (X, Y, Z : Element_Type) is null
     with Ghost;

package SPARK.Containers.Formal.Unbounded_Ordered_Sets with
  SPARK_Mode,
  Always_Terminates
is
   --  Contracts in this unit are meant for analysis only, not for run-time
   --  checking.

   pragma Assertion_Policy (Ignore);
   pragma Annotate (CodePeer, Skip_Analysis);

   function Equivalent_Elements (Left, Right : Element_Type) return Boolean
   with
     Global => null,
     Post   =>
       Equivalent_Elements'Result =
         (not (Left < Right) and not (Right < Left));
   pragma Annotate (GNATprove, Inline_For_Proof, Equivalent_Elements);

   pragma Annotate (GNATcheck, Exempt_On,
                    "Restrictions:No_Specification_Of_Aspect => Iterable",
                    "The following usage of aspect Iterable has been reviewed"
                    & "for compliance with GNATprove assumption"
                    & " [SPARK_ITERABLE]");
   type Set is private with
     Iterable                  => (First       => First,
                                   Next        => Next,
                                   Has_Element => Has_Element,
                                   Element     => Element),
     Default_Initial_Condition => Is_Empty (Set),
     Aggregate                 => (Empty       => Empty_Set,
                                   Add_Unnamed => Insert),
     Annotate                  =>
       (GNATprove, Container_Aggregates, "From_Model");
   pragma Annotate (GNATcheck, Exempt_Off,
                    "Restrictions:No_Specification_Of_Aspect => Iterable");

   type Cursor is record
      Node : Count_Type;
   end record;

   No_Element : constant Cursor := (Node => 0);

   function Length (Container : Set) return Count_Type with
     Global => null;

   pragma Unevaluated_Use_Of_Old (Allow);

   package Formal_Model with Ghost is

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

      package Lift_Eq is new
        SPARK.Containers.Parameter_Checks.Lift_Eq_Reflexive
          (T                  => Element_Type,
           "="                => "=",
           Eq                 => "=",
           Param_Eq_Reflexive => Eq_Checks.Eq_Reflexive);

      package Lt_Checks is new
        SPARK.Containers.Parameter_Checks.Strict_Weak_Order_Checks_Eq
          (T                    => Element_Type,
           "<"                  => "<",
           "="                  => "=",
           Param_Eq_Reflexive   => Eq_Checks.Eq_Reflexive,
           Param_Eq_Symmetric   => Eq_Checks.Eq_Symmetric,
           Param_Lt_Irreflexive => Lt_Irreflexive,
           Param_Lt_Asymmetric  => Lt_Asymmetric,
           Param_Lt_Transitive  => Lt_Transitive,
           Param_Lt_Order       => Lt_Order);
      --  Check that "<" is a strict weak ordering relationship with respect
      --  to "=".

      ------------------
      -- Formal Model --
      ------------------

      subtype Positive_Count_Type is Count_Type range 1 .. Count_Type'Last;

      package M is new SPARK.Containers.Functional.Sets
        (Element_Type                   => Element_Type,
         Equivalent_Elements            => Equivalent_Elements,
         Equivalent_Elements_Reflexive  => Lt_Checks.Eq_Reflexive,
         Equivalent_Elements_Symmetric  => Lt_Checks.Eq_Symmetric,
         Equivalent_Elements_Transitive => Lt_Checks.Eq_Transitive);

      function "="
        (Left  : M.Set;
         Right : M.Set) return Boolean renames M."=";

      function "<="
        (Left  : M.Set;
         Right : M.Set) return Boolean renames M."<=";

      package E is new SPARK.Containers.Functional.Vectors
        (Element_Type                   => Element_Type,
         Index_Type                     => Positive_Count_Type,
         "="                            => "=",
         Eq_Reflexive                   => Eq_Checks.Eq_Reflexive,
         Eq_Symmetric                   => Eq_Checks.Eq_Symmetric,
         Eq_Transitive                  => Eq_Checks.Eq_Transitive,
         Equivalent_Elements            => "=",
         Equivalent_Elements_Reflexive  => Lift_Eq.Eq_Reflexive,
         Equivalent_Elements_Symmetric  => Eq_Checks.Eq_Symmetric,
         Equivalent_Elements_Transitive => Eq_Checks.Eq_Transitive);

      function Element_Logic_Equal
        (Left, Right : Element_Type) return Boolean
         renames E.Element_Logic_Equal;

      function "="
        (Left  : E.Sequence;
         Right : E.Sequence) return Boolean renames E."=";

      function "<"
        (Left  : E.Sequence;
         Right : E.Sequence) return Boolean renames E."<";

      function "<="
        (Left  : E.Sequence;
         Right : E.Sequence) return Boolean renames E."<=";

      function E_Bigger_Than_Range
        (Container : E.Sequence;
         Fst       : Positive_Count_Type;
         Lst       : Count_Type;
         Item      : Element_Type) return Boolean
      with
        Global => null,
        Pre    => Lst <= E.Last (Container),
        Post   =>
          E_Bigger_Than_Range'Result =
            (for all I in Fst .. Lst => E.Get (Container, I) < Item);
      pragma Annotate (GNATprove, Inline_For_Proof, E_Bigger_Than_Range);

      function E_Smaller_Than_Range
        (Container : E.Sequence;
         Fst       : Positive_Count_Type;
         Lst       : Count_Type;
         Item      : Element_Type) return Boolean
      with
        Global => null,
        Pre    => Lst <= E.Last (Container),
        Post   =>
          E_Smaller_Than_Range'Result =
            (for all I in Fst .. Lst => Item < E.Get (Container, I));
      pragma Annotate (GNATprove, Inline_For_Proof, E_Smaller_Than_Range);

      function E_Is_Find
        (Container : E.Sequence;
         Item      : Element_Type;
         Position  : Count_Type) return Boolean
      with
        Global => null,
        Pre    => Position - 1 <= E.Last (Container),
        Post   =>
          E_Is_Find'Result =

            ((if Position > 0 then
                E_Bigger_Than_Range (Container, 1, Position - 1, Item))

             and (if Position < E.Last (Container) then
                    E_Smaller_Than_Range
                      (Container,
                       Position + 1,
                       E.Last (Container),
                       Item)));
      pragma Annotate (GNATprove, Inline_For_Proof, E_Is_Find);

      function Find
        (Container : E.Sequence;
         Item      : Element_Type) return Count_Type
      --  Search for Item in Container

      with
        Global => null,
        Post =>
          (if Find'Result > 0 then
             Find'Result <= E.Last (Container)
               and Equivalent_Elements (Item, E.Get (Container, Find'Result)));

      function E_Elements_Equal
        (Left  : E.Sequence;
         Right : E.Sequence) return Boolean
      --  The elements of Left are "=" to the equivalent element in Right

      with
        Global => null,
        Post   =>
          E_Elements_Equal'Result =
            (for all I in 1 .. E.Last (Left) =>
              Find (Right, E.Get (Left, I)) > 0
                and then E.Get (Right, Find (Right, E.Get (Left, I))) =
                         E.Get (Left, I));
      pragma Annotate (GNATprove, Inline_For_Proof, E_Elements_Equal);

      function E_Elements_Included
        (Left  : E.Sequence;
         Right : E.Sequence) return Boolean
      --  The elements of Left are contained in Right

      with
        Global => null,
        Post   =>
          E_Elements_Included'Result =
            (for all I in 1 .. E.Last (Left) =>
               Find (Right, E.Get (Left, I)) > 0
                 and then Element_Logic_Equal
                    (E.Get (Right, Find (Right, E.Get (Left, I))),
                     E.Get (Left, I)));
      pragma Annotate (GNATprove, Inline_For_Proof, E_Elements_Included);

      function E_Elements_Included
        (Left  : E.Sequence;
         Model : M.Set;
         Right : E.Sequence) return Boolean
      --  The elements of Container contained in Model are in Right

      with
        Global => null,
        Post   =>
          E_Elements_Included'Result =
            (for all I in 1 .. E.Last (Left) =>
              (if M.Contains (Model, E.Get (Left, I)) then
                 Find (Right, E.Get (Left, I)) > 0
                   and then Element_Logic_Equal
                      (E.Get (Right, Find (Right, E.Get (Left, I))),
                       E.Get (Left, I))));
      pragma Annotate (GNATprove, Inline_For_Proof, E_Elements_Included);

      function E_Elements_Included
        (Container : E.Sequence;
         Model     : M.Set;
         Left      : E.Sequence;
         Right     : E.Sequence) return Boolean
      --  The elements of Container contained in Model are in Left and others
      --  are in Right.

      with
        Global => null,
        Post   =>
          E_Elements_Included'Result =
            (for all I in 1 .. E.Last (Container) =>
              (if M.Contains (Model, E.Get (Container, I)) then
                 Find (Left, E.Get (Container, I)) > 0
                   and then Element_Logic_Equal
                      (E.Get (Left, Find (Left, E.Get (Container, I))),
                       E.Get (Container, I))
               else
                 Find (Right, E.Get (Container, I)) > 0
                   and then Element_Logic_Equal
                      (E.Get (Right, Find (Right, E.Get (Container, I))),
                       E.Get (Container, I))));
      pragma Annotate (GNATprove, Inline_For_Proof, E_Elements_Included);

      package P is new SPARK.Containers.Functional.Maps
        (Key_Type                       => Cursor,
         Element_Type                   => Positive_Count_Type,
         Equivalent_Keys                => "=",
         Enable_Handling_Of_Equivalence => False);

      function "="
        (Left  : P.Map;
         Right : P.Map) return Boolean renames P."=";

      function "<="
        (Left  : P.Map;
         Right : P.Map) return Boolean renames P."<=";

      function P_Positions_Shifted
        (Small : P.Map;
         Big   : P.Map;
         Cut   : Positive_Count_Type;
         Count : Count_Type := 1) return Boolean
      with
        Global => null,
        Post   =>
          P_Positions_Shifted'Result =

            --  Big contains all cursors of Small

            (P.Keys_Included (Small, Big)

              --  Cursors located before Cut are not moved, cursors located
              --  after are shifted by Count.

              and (for all I of Small =>
                    (if P.Get (Small, I) < Cut then
                        P.Get (Big, I) = P.Get (Small, I)
                     else
                        P.Get (Big, I) - Count = P.Get (Small, I)))

              --  New cursors of Big (if any) are between Cut and Cut - 1 +
              --  Count.

              and (for all I of Big =>
                    P.Has_Key (Small, I)
                      or P.Get (Big, I) - Count in Cut - Count  .. Cut - 1));

      function Mapping_Preserved
        (E_Left  : E.Sequence;
         E_Right : E.Sequence;
         P_Left  : P.Map;
         P_Right : P.Map) return Boolean
      with
        Ghost,
        Global => null,
        Post   =>
          (if Mapping_Preserved'Result then

             --  Right contains all the cursors of Left

             P.Keys_Included (P_Left, P_Right)

               --  Right contains all the elements of Left

               and E_Elements_Included (E_Left, E_Right)

               --  Mappings from cursors to elements induced by E_Left, P_Left
               --  and E_Right, P_Right are the same.

               and (for all C of P_Left =>
                     Element_Logic_Equal
                       (E.Get (E_Left, P.Get (P_Left, C)),
                        E.Get (E_Right, P.Get (P_Right, C)))));

      function Mapping_Preserved_Except
        (E_Left   : E.Sequence;
         E_Right  : E.Sequence;
         P_Left   : P.Map;
         P_Right  : P.Map;
         Position : Cursor) return Boolean
      with
        Ghost,
        Global => null,
        Post   =>
          (if Mapping_Preserved_Except'Result then

             --  Right contains all the cursors of Left

             P.Keys_Included (P_Left, P_Right)

               --  Mappings from cursors to elements induced by E_Left, P_Left
               --  and E_Right, P_Right are the same except for Position.

               and (for all C of P_Left =>
                     (if C /= Position then
                        Element_Logic_Equal
                          (E.Get (E_Left, P.Get (P_Left, C)),
                           E.Get (E_Right, P.Get (P_Right, C))))));

      function Model (Container : Set) return M.Set with
      --  The high-level model of a set is a set of elements. Neither cursors
      --  nor order of elements are represented in this model. Elements are
      --  modeled up to equivalence.

        Ghost,
        Global => null,
        Post   => M.Length (Model'Result) = E.Big (Length (Container));

      function Elements (Container : Set) return E.Sequence with
      --  The Elements sequence represents the underlying list structure of
      --  sets that is used for iteration. It stores the actual values of
      --  elements in the set. It does not model cursors.

        Ghost,
        Global => null,
        Post   =>
          E.Last (Elements'Result) = Length (Container)

            --  It only contains keys contained in Model

            and (for all Item of Elements'Result =>
                   M.Contains (Model (Container), Item))

            --  It contains all the elements contained in Model

            and (for all Item of Model (Container) =>
                  (Find (Elements'Result, Item) > 0
                     and then Equivalent_Elements
                      (E.Get (Elements'Result, Find (Elements'Result, Item)),
                       Item)))

            --  It is sorted in increasing order

            and (for all I in 1 .. Length (Container) =>
                  Find (Elements'Result, E.Get (Elements'Result, I)) = I
                  and
                    E_Is_Find
                      (Elements'Result, E.Get (Elements'Result, I), I));

      function Positions (Container : Set) return P.Map with
      --  The Positions map is used to model cursors. It only contains valid
      --  cursors and maps them to their position in the container.

        Ghost,
        Global => null,
        Post   =>
          not P.Has_Key (Positions'Result, No_Element)

            --  Positions of cursors are smaller than the container's length

            and then
              (for all I of Positions'Result =>
                P.Get (Positions'Result, I) in 1 .. Length (Container)

            --  No two cursors have the same position. Note that we do not
            --  state that there is a cursor in the map for each position, as
            --  it is rarely needed.

            and then
              (for all J of Positions'Result =>
                (if P.Get (Positions'Result, I) = P.Get (Positions'Result, J)
                  then I = J)));

      procedure Lift_Abstraction_Level (Container : Set) with
        --  Lift_Abstraction_Level is a ghost procedure that does nothing but
        --  assume that we can access the same elements by iterating over
        --  positions or cursors.
        --  This information is not generally useful except when switching from
        --  a low-level, cursor-aware view of a container, to a high-level,
        --  position-based view.

        Ghost,
        Global => null,
        Post   =>
          (for all Item of Elements (Container) =>
            (for some I of Positions (Container) =>
               Element_Logic_Equal
                 (E.Get
                    (Elements (Container), P.Get (Positions (Container), I)),
                  Item)));

      function Contains
        (C : M.Set;
         K : Element_Type) return Boolean renames M.Contains;
      --  To improve readability of contracts, we rename the function used to
      --  search for an element in the model to Contains.

   end Formal_Model;
   use Formal_Model;

   function Empty_Set return Set with
   --  Build an empty set

   Global => null,
   Post   => Is_Empty (Empty_Set'Result);

   function "=" (Left, Right : Set) return Boolean with
     Global => null,
     Post   =>

       --  If two sets are equal, they contain the same elements in the same
       --  order.

       (if "="'Result
        then E.Equivalent_Sequences (Elements (Left), Elements (Right))

        --  If they are different, then they do not contain the same elements

        else
           not E_Elements_Equal (Elements (Left), Elements (Right))
              or not E_Elements_Equal (Elements (Right), Elements (Left)));

   function Equivalent_Sets (Left, Right : Set) return Boolean with
     Global => null,
     Post   => Equivalent_Sets'Result = (Model (Left) = Model (Right));

   function To_Set (New_Item : Element_Type) return Set with
     Global => null,
     Post   =>
       M.Is_Singleton (Model (To_Set'Result), New_Item)
         and Length (To_Set'Result) = 1
         and Element_Logic_Equal
              (E.Get (Elements (To_Set'Result), 1),
               E.Copy_Element (New_Item));

   function Is_Empty (Container : Set) return Boolean with
     Global => null,
     Post   =>
       Is_Empty'Result = M.Is_Empty (Model (Container))
         and Is_Empty'Result = (Length (Container) = 0);

   procedure Clear (Container : in out Set) with
     Global => null,
     Post   => Length (Container) = 0 and M.Is_Empty (Model (Container));

   procedure Assign (Target : in out Set; Source : Set) with
     Global => null,
     Post   =>
       Model (Target) = Model (Source)
         and E.Equal (Elements (Target), Elements (Source))
         and Length (Target) = Length (Source);

   function Copy (Source : Set) return Set with
     Global => null,
     Post   =>
       Model (Copy'Result) = Model (Source)
         and E.Equal (Elements (Copy'Result), Elements (Source))
         and Positions (Copy'Result) = Positions (Source);

   function Element
     (Container : Set;
      Position  : Cursor) return Element_Type
   with
     Global   => null,
     Pre      => Has_Element (Container, Position),
     Post     =>
       Element'Result =
         E.Get (Elements (Container), P.Get (Positions (Container), Position)),
     Annotate => (GNATprove, Inline_For_Proof);

   procedure Replace_Element
     (Container : in out Set;
      Position  : Cursor;
      New_Item  : Element_Type)
   with
     Global => null,
     Pre    => Has_Element (Container, Position),
     Post   =>
       Length (Container) = Length (Container)'Old

          --  Position now maps to New_Item

          and Element_Logic_Equal
                (Element (Container, Position), E.Copy_Element (New_Item))

          --  New_Item is contained in Container

          and Contains (Model (Container), New_Item)

          --  Other elements are preserved

          and M.Included_Except
                (Model (Container)'Old,
                 Model (Container),
                 Element (Container, Position)'Old)
          and M.Included_Except
                (Model (Container),
                 Model (Container)'Old,
                 New_Item)

          --  Mapping from cursors to elements is preserved

          and Mapping_Preserved_Except
                (E_Left   => Elements (Container)'Old,
                 E_Right  => Elements (Container),
                 P_Left   => Positions (Container)'Old,
                 P_Right  => Positions (Container),
                 Position => Position)
          and P.Keys_Included (Positions (Container),
                               Positions (Container)'Old);

   function Constant_Reference
     (Container : Set;
      Position  : Cursor) return not null access constant Element_Type
   with
     Global => null,
     Pre    => Has_Element (Container, Position),
     Post   =>
       Constant_Reference'Result.all =
         E.Get (Elements (Container), P.Get (Positions (Container), Position));

   procedure Move (Target : in out Set; Source : in out Set) with
     Global => null,
     Post   =>
       Model (Target) = Model (Source)'Old
         and E.Equal (Elements (Target), Elements (Source)'Old)
         and Length (Source)'Old = Length (Target)
         and Length (Source) = 0;

   procedure Insert
     (Container : in out Set;
      New_Item  : Element_Type;
      Position  : out Cursor;
      Inserted  : out Boolean)
   with
     Global         => null,
     Pre            =>
       Length (Container) < Count_Type'Last
         or Contains (Container, New_Item),
     Post           =>
       Contains (Container, New_Item)
         and Has_Element (Container, Position)
         and Equivalent_Elements (Element (Container, Position), New_Item)
         and E_Is_Find
               (Elements (Container),
                New_Item,
                P.Get (Positions (Container), Position)),
     Contract_Cases =>

       --  If New_Item is already in Container, it is not modified and Inserted
       --  is set to False.

       (Contains (Container, New_Item) =>
          not Inserted
            and Model (Container) = Model (Container)'Old
            and E.Equal (Elements (Container), Elements (Container)'Old)
            and Positions (Container) = Positions (Container)'Old,

        --  Otherwise, New_Item is inserted in Container and Inserted is set to
        --  True

        others =>
          Inserted
            and Length (Container) = Length (Container)'Old + 1

            --  Position now maps to New_Item

            and Element_Logic_Equal
                 (Element (Container, Position), E.Copy_Element (New_Item))

            --  Other elements are preserved

            and Model (Container)'Old <= Model (Container)
            and M.Included_Except
                  (Model (Container),
                   Model (Container)'Old,
                   New_Item)

            --  The elements of Container located before Position are preserved

            and E.Range_Equal
                  (Left  => Elements (Container)'Old,
                   Right => Elements (Container),
                   Fst   => 1,
                   Lst   => P.Get (Positions (Container), Position) - 1)

            --  Other elements are shifted by 1

            and E.Range_Shifted
                  (Left   => Elements (Container)'Old,
                   Right  => Elements (Container),
                   Fst    => P.Get (Positions (Container), Position),
                   Lst    => Length (Container)'Old,
                   Offset => 1)

            --  A new cursor has been inserted at position Position in
            --  Container.

            and P_Positions_Shifted
                  (Positions (Container)'Old,
                   Positions (Container),
                   Cut => P.Get (Positions (Container), Position)));

   procedure Insert
     (Container : in out Set;
      New_Item  : Element_Type)
   with
     Global => null,
     Pre    =>
       Length (Container) < Count_Type'Last
         and then not Contains (Container, New_Item),
     Post   =>
       Length (Container) = Length (Container)'Old + 1
         and Contains (Container, New_Item)

         --  New_Item is inserted in the set

         and Element_Logic_Equal
               (E.Get (Elements (Container),
                       Find (Elements (Container), New_Item)),
                E.Copy_Element (New_Item))

         --  Other mappings are preserved

         and Model (Container)'Old <= Model (Container)
         and M.Included_Except
               (Model (Container),
                Model (Container)'Old,
                New_Item)

         --  The elements of Container located before New_Item are preserved

         and E.Range_Equal
               (Left  => Elements (Container)'Old,
                Right => Elements (Container),
                Fst   => 1,
                Lst   => Find (Elements (Container), New_Item) - 1)

         --  Other elements are shifted by 1

         and E.Range_Shifted
               (Left   => Elements (Container)'Old,
                Right  => Elements (Container),
                Fst    => Find (Elements (Container), New_Item),
                Lst    => Length (Container)'Old,
                Offset => 1)

         --  A new cursor has been inserted in Container

         and P_Positions_Shifted
               (Positions (Container)'Old,
                Positions (Container),
                Cut => Find (Elements (Container), New_Item));

   procedure Include
     (Container : in out Set;
      New_Item  : Element_Type)
   with
     Global         => null,
     Pre            =>
       Length (Container) < Count_Type'Last
         or Contains (Container, New_Item),
     Post           => Contains (Container, New_Item),
     Contract_Cases =>

       --  If New_Item is already in Container

       (Contains (Container, New_Item) =>

          --  Elements are preserved

          Model (Container)'Old = Model (Container)

            --  Cursors are preserved

            and Positions (Container) = Positions (Container)'Old

            --  The element equivalent to New_Item in Container is replaced by
            --  New_Item.

            and Element_Logic_Equal
                  (E.Get (Elements (Container),
                          Find (Elements (Container), New_Item)),
                   E.Copy_Element (New_Item))

            and E.Equal_Except
                  (Elements (Container)'Old,
                   Elements (Container),
                   Find (Elements (Container), New_Item)),

        --  Otherwise, New_Item is inserted in Container

        others =>
          Length (Container) = Length (Container)'Old + 1

            --  Other elements are preserved

            and Model (Container)'Old <= Model (Container)
            and M.Included_Except
                  (Model (Container),
                   Model (Container)'Old,
                   New_Item)

            --  New_Item is inserted in Container

            and Element_Logic_Equal
                  (E.Get (Elements (Container),
                          Find (Elements (Container), New_Item)),
                   E.Copy_Element (New_Item))

            --  The Elements of Container located before New_Item are preserved

            and E.Range_Equal
                  (Left  => Elements (Container)'Old,
                   Right => Elements (Container),
                   Fst   => 1,
                   Lst   => Find (Elements (Container), New_Item) - 1)

            --  Other Elements are shifted by 1

            and E.Range_Shifted
                  (Left   => Elements (Container)'Old,
                   Right  => Elements (Container),
                   Fst    => Find (Elements (Container), New_Item),
                   Lst    => Length (Container)'Old,
                   Offset => 1)

            --  A new cursor has been inserted in Container

            and P_Positions_Shifted
                  (Positions (Container)'Old,
                   Positions (Container),
                   Cut => Find (Elements (Container), New_Item)));

   procedure Replace
     (Container : in out Set;
      New_Item  : Element_Type)
   with
     Global => null,
     Pre    => Contains (Container, New_Item),
     Post   =>

       --  Elements are preserved

       Model (Container)'Old = Model (Container)

         --  Cursors are preserved

         and Positions (Container) = Positions (Container)'Old

         --  The element equivalent to New_Item in Container is replaced by
         --  New_Item.

         and Element_Logic_Equal
              (E.Get (Elements (Container),
                      Find (Elements (Container), New_Item)),
               E.Copy_Element (New_Item))

         and E.Equal_Except
              (Elements (Container)'Old,
               Elements (Container),
               Find (Elements (Container), New_Item));

   procedure Exclude
     (Container : in out Set;
      Item      : Element_Type)
   with
     Global         => null,
     Post           => not Contains (Container, Item),
     Contract_Cases =>

       --  If Item is not in Container, nothing is changed

       (not Contains (Container, Item) =>
          Model (Container) = Model (Container)'Old
            and E.Equal (Elements (Container), Elements (Container)'Old)
            and Positions (Container) = Positions (Container)'Old,

        --  Otherwise, Item is removed from Container

        others =>
          Length (Container) = Length (Container)'Old - 1

            --  Other elements are preserved

            and Model (Container) <= Model (Container)'Old
            and M.Included_Except
                  (Model (Container)'Old,
                   Model (Container),
                   Item)

            --  The elements of Container located before Item are preserved

            and E.Range_Equal
                  (Left  => Elements (Container)'Old,
                   Right => Elements (Container),
                   Fst   => 1,
                   Lst   => Find (Elements (Container), Item)'Old - 1)

            --  The elements located after Item are shifted by 1

            and E.Range_Shifted
                  (Left   => Elements (Container),
                   Right  => Elements (Container)'Old,
                   Fst    => Find (Elements (Container), Item)'Old,
                   Lst    => Length (Container),
                   Offset => 1)

            --  A cursor has been removed from Container

            and P_Positions_Shifted
                  (Positions (Container),
                   Positions (Container)'Old,
                   Cut   => Find (Elements (Container), Item)'Old));

   procedure Delete
     (Container : in out Set;
      Item      : Element_Type)
   with
     Global => null,
     Pre    => Contains (Container, Item),
     Post   =>
       Length (Container) = Length (Container)'Old - 1

         --  Item is no longer in Container

         and not Contains (Container, Item)

         --  Other elements are preserved

         and Model (Container) <= Model (Container)'Old
         and M.Included_Except
               (Model (Container)'Old,
                Model (Container),
                Item)

         --  The elements of Container located before Item are preserved

         and E.Range_Equal
               (Left  => Elements (Container)'Old,
                Right => Elements (Container),
                Fst   => 1,
                Lst   => Find (Elements (Container), Item)'Old - 1)

         --  The elements located after Item are shifted by 1

         and E.Range_Shifted
               (Left   => Elements (Container),
                Right  => Elements (Container)'Old,
                Fst    => Find (Elements (Container), Item)'Old,
                Lst    => Length (Container),
                Offset => 1)

         --  A cursor has been removed from Container

         and P_Positions_Shifted
               (Positions (Container),
                Positions (Container)'Old,
                Cut   => Find (Elements (Container), Item)'Old);

   procedure Delete
     (Container : in out Set;
      Position  : in out Cursor)
   with
     Global  => null,
     Depends => (Container =>+ Position, Position => null),
     Pre     => Has_Element (Container, Position),
     Post    =>
       Position = No_Element
         and Length (Container) = Length (Container)'Old - 1

         --  The element at position Position is no longer in Container

         and not Contains (Container, Element (Container, Position)'Old)
         and not P.Has_Key (Positions (Container), Position'Old)

         --  Other elements are preserved

         and Model (Container) <= Model (Container)'Old
         and M.Included_Except
               (Model (Container)'Old,
                Model (Container),
                Element (Container, Position)'Old)

         --  The elements of Container located before Position are preserved.

         and E.Range_Equal
               (Left  => Elements (Container)'Old,
                Right => Elements (Container),
                Fst   => 1,
                Lst   => P.Get (Positions (Container)'Old, Position'Old) - 1)

         --  The elements located after Position are shifted by 1

         and E.Range_Shifted
               (Left   => Elements (Container),
                Right  => Elements (Container)'Old,
                Fst    => P.Get (Positions (Container)'Old, Position'Old),
                Lst    => Length (Container),
                Offset => 1)

         --  Position has been removed from Container

         and P_Positions_Shifted
               (Positions (Container),
                Positions (Container)'Old,
                Cut   => P.Get (Positions (Container)'Old, Position'Old));

   procedure Delete_First (Container : in out Set) with
     Global         => null,
     Contract_Cases =>
       (Length (Container) = 0 => Length (Container) = 0,
        others =>
          Length (Container) = Length (Container)'Old - 1

            --  The first element has been removed from Container

            and not Contains (Container, First_Element (Container)'Old)

            --  Other elements are preserved

            and Model (Container) <= Model (Container)'Old
            and M.Included_Except
                  (Model (Container)'Old,
                   Model (Container),
                   First_Element (Container)'Old)

            --  Other elements are shifted by 1

            and E.Range_Shifted
                  (Left   => Elements (Container),
                   Right  => Elements (Container)'Old,
                   Fst    => 1,
                   Lst    => Length (Container),
                   Offset => 1)

            --  First has been removed from Container

            and P_Positions_Shifted
                  (Positions (Container),
                   Positions (Container)'Old,
                   Cut   => 1));

   procedure Delete_Last (Container : in out Set) with
     Global         => null,
     Contract_Cases =>
       (Length (Container) = 0 => Length (Container) = 0,
        others =>
          Length (Container) = Length (Container)'Old - 1

            --  The last element has been removed from Container

            and not Contains (Container, Last_Element (Container)'Old)

            --  Other elements are preserved

            and Model (Container) <= Model (Container)'Old
            and M.Included_Except
                  (Model (Container)'Old,
                   Model (Container),
                   Last_Element (Container)'Old)

            --  Others elements of Container are preserved

            and E.Range_Equal
                  (Left  => Elements (Container)'Old,
                   Right => Elements (Container),
                   Fst   => 1,
                   Lst   => Length (Container))

            --  Last cursor has been removed from Container

            and Positions (Container) <= Positions (Container)'Old);

   procedure Union (Target : in out Set; Source : Set) with
     Global => null,
     Pre    =>
       Length (Source) - Length (Target and Source) <=
         Count_Type'Last - Length (Target),
     Post   =>
       E.Big (Length (Target)) = E.Big (Length (Target)'Old)
         - M.Num_Overlaps (Model (Target)'Old, Model (Source))
         + E.Big (Length (Source))

         --  Elements already in Target are still in Target

         and Model (Target)'Old <= Model (Target)

         --  Elements of Source are included in Target

         and Model (Source) <= Model (Target)

         --  Elements of Target come from either Source or Target

         and
           M.Included_In_Union
             (Model (Target), Model (Source), Model (Target)'Old)

         --  Actual value of elements come from either Left or Right

         and
           E_Elements_Included
             (Elements (Target),
              Model (Target)'Old,
              Elements (Target)'Old,
              Elements (Source))
         and
           E_Elements_Included
             (Elements (Target)'Old, Model (Target)'Old, Elements (Target))
         and
           E_Elements_Included
             (Elements (Source),
              Model (Target)'Old,
              Elements (Source),
              Elements (Target))

         --  Mapping from cursors of Target to elements is preserved

         and Mapping_Preserved
               (E_Left  => Elements (Target)'Old,
                E_Right => Elements (Target),
                P_Left  => Positions (Target)'Old,
                P_Right => Positions (Target));

   function Union (Left, Right : Set) return Set with
     Global => null,
     Pre    => Length (Left) <= Count_Type'Last - Length (Right),
     Post   =>
       E.Big (Length (Union'Result)) = E.Big (Length (Left))
         - M.Num_Overlaps (Model (Left), Model (Right))
         + E.Big (Length (Right))

         --  Elements of Left and Right are in the result of Union

         and Model (Left) <= Model (Union'Result)
         and Model (Right) <= Model (Union'Result)

         --  Elements of the result of union come from either Left or Right

         and
           M.Included_In_Union
             (Model (Union'Result), Model (Left), Model (Right))

         --  Actual value of elements come from either Left or Right

         and
           E_Elements_Included
             (Elements (Union'Result),
              Model (Left),
              Elements (Left),
              Elements (Right))
         and
           E_Elements_Included
             (Elements (Left), Model (Left), Elements (Union'Result))
         and
           E_Elements_Included
             (Elements (Right),
              Model (Left),
              Elements (Right),
              Elements (Union'Result));

   function "or" (Left, Right : Set) return Set renames Union;

   procedure Intersection (Target : in out Set; Source : Set) with
     Global => null,
     Post   =>
       E.Big (Length (Target)) =
         M.Num_Overlaps (Model (Target)'Old, Model (Source))

         --  Elements of Target were already in Target

         and Model (Target) <= Model (Target)'Old

         --  Elements of Target are in Source

         and Model (Target) <= Model (Source)

         --  Elements both in Source and Target are in the intersection

         and
           M.Includes_Intersection
             (Model (Target), Model (Source), Model (Target)'Old)

         --  Actual value of elements of Target is preserved

         and E_Elements_Included (Elements (Target), Elements (Target)'Old)
         and
           E_Elements_Included
             (Elements (Target)'Old, Model (Source), Elements (Target))

         --  Mapping from cursors of Target to elements is preserved

         and Mapping_Preserved
               (E_Left  => Elements (Target),
                E_Right => Elements (Target)'Old,
                P_Left  => Positions (Target),
                P_Right => Positions (Target)'Old);

   function Intersection (Left, Right : Set) return Set with
     Global => null,
     Post   =>
       E.Big (Length (Intersection'Result)) =
         M.Num_Overlaps (Model (Left), Model (Right))

         --  Elements in the result of Intersection are in Left and Right

         and Model (Intersection'Result) <= Model (Left)
         and Model (Intersection'Result) <= Model (Right)

         --  Elements both in Left and Right are in the result of Intersection

         and
           M.Includes_Intersection
             (Model (Intersection'Result), Model (Left), Model (Right))

         --  Actual value of elements come from Left

         and
           E_Elements_Included
             (Elements (Intersection'Result), Elements (Left))
         and
           E_Elements_Included
             (Elements (Left), Model (Right), Elements (Intersection'Result));

   function "and" (Left, Right : Set) return Set renames Intersection;

   procedure Difference (Target : in out Set; Source : Set) with
     Global => null,
     Post   =>
       E.Big (Length (Target)) = E.Big (Length (Target)'Old) -
         M.Num_Overlaps (Model (Target)'Old, Model (Source))

         --  Elements of Target were already in Target

         and Model (Target) <= Model (Target)'Old

         --  Elements of Target are not in Source

         and M.No_Overlap (Model (Target), Model (Source))

         --  Elements in Target but not in Source are in the difference

         and
           M.Included_In_Union
             (Model (Target)'Old, Model (Target), Model (Source))

         --  Actual value of elements of Target is preserved

         and E_Elements_Included (Elements (Target), Elements (Target)'Old)
         and
           E_Elements_Included
             (Elements (Target)'Old, Model (Target), Elements (Target))

         --  Mapping from cursors of Target to elements is preserved

         and Mapping_Preserved
               (E_Left  => Elements (Target),
                E_Right => Elements (Target)'Old,
                P_Left  => Positions (Target),
                P_Right => Positions (Target)'Old);

   function Difference (Left, Right : Set) return Set with
     Global => null,
     Post   =>
       E.Big (Length (Difference'Result)) = E.Big (Length (Left)) -
         M.Num_Overlaps (Model (Left), Model (Right))

         --  Elements of the result of Difference are in Left

         and Model (Difference'Result) <= Model (Left)

         --  Elements of the result of Difference are in Right

         and M.No_Overlap (Model (Difference'Result), Model (Right))

         --  Elements in Left but not in Right are in the difference

         and
           M.Included_In_Union
             (Model (Left), Model (Difference'Result), Model (Right))

         --  Actual value of elements come from Left

         and
           E_Elements_Included (Elements (Difference'Result), Elements (Left))
         and
           E_Elements_Included
             (Elements (Left),
              Model (Difference'Result),
              Elements (Difference'Result));

   function "-" (Left, Right : Set) return Set renames Difference;

   procedure Symmetric_Difference (Target : in out Set; Source : Set) with
     Global => null,
     Pre    =>
       Length (Source) - Length (Target and Source) <=
         Count_Type'Last - Length (Target) + Length (Target and Source),
     Post   =>
       E.Big (Length (Target)) = E.Big (Length (Target)'Old) -
         2 * M.Num_Overlaps (Model (Target)'Old, Model (Source)) +
         E.Big (Length (Source))

         --  Elements of the difference were not both in Source and in Target

         and M.Not_In_Both (Model (Target), Model (Target)'Old, Model (Source))

         --  Elements in Target but not in Source are in the difference

         and
           M.Included_In_Union
             (Model (Target)'Old, Model (Target), Model (Source))

         --  Elements in Source but not in Target are in the difference

         and
           M.Included_In_Union
             (Model (Source), Model (Target), Model (Target)'Old)

         --  Actual value of elements come from either Left or Right

         and
           E_Elements_Included
             (Elements (Target),
              Model (Target)'Old,
              Elements (Target)'Old,
              Elements (Source))
         and
           E_Elements_Included
             (Elements (Target)'Old, Model (Target), Elements (Target))
         and
           E_Elements_Included
             (Elements (Source), Model (Target), Elements (Target));

   function Symmetric_Difference (Left, Right : Set) return Set with
     Global => null,
     Pre    => Length (Left) <= Count_Type'Last - Length (Right),
     Post   =>
       E.Big (Length (Symmetric_Difference'Result)) = E.Big (Length (Left)) -
         2 * M.Num_Overlaps (Model (Left), Model (Right)) +
         E.Big (Length (Right))

         --  Elements of the difference were not both in Left and Right

         and
           M.Not_In_Both
             (Model (Symmetric_Difference'Result), Model (Left), Model (Right))

         --  Elements in Left but not in Right are in the difference

         and
           M.Included_In_Union
             (Model (Left), Model (Symmetric_Difference'Result), Model (Right))

         --  Elements in Right but not in Left are in the difference

         and
           M.Included_In_Union
             (Model (Right), Model (Symmetric_Difference'Result), Model (Left))

         --  Actual value of elements come from either Left or Right

         and
           E_Elements_Included
             (Elements (Symmetric_Difference'Result),
              Model (Left),
              Elements (Left),
              Elements (Right))
         and
           E_Elements_Included
             (Elements (Left),
              Model (Symmetric_Difference'Result),
              Elements (Symmetric_Difference'Result))
         and
           E_Elements_Included
             (Elements (Right),
              Model (Symmetric_Difference'Result),
              Elements (Symmetric_Difference'Result));

   function "xor" (Left, Right : Set) return Set
     renames Symmetric_Difference;

   function Overlap (Left, Right : Set) return Boolean with
     Global => null,
     Post   =>
       Overlap'Result = not M.No_Overlap (Model (Left), Model (Right));

   function Is_Subset (Subset : Set; Of_Set : Set) return Boolean with
     Global => null,
     Post   => Is_Subset'Result = (Model (Subset) <= Model (Of_Set));

   function First (Container : Set) return Cursor with
     Global         => null,
     Contract_Cases =>
       (Length (Container) = 0 =>
          First'Result = No_Element,

        others =>
          Has_Element (Container, First'Result)
            and P.Get (Positions (Container), First'Result) = 1);

   function First_Element (Container : Set) return Element_Type with
     Global => null,
     Pre    => not Is_Empty (Container),
     Post   =>
       Element_Logic_Equal
         (First_Element'Result, E.Get (Elements (Container), 1))
         and E_Smaller_Than_Range
               (Elements (Container),
                2,
                Length (Container),
                First_Element'Result);

   function Last (Container : Set) return Cursor with
     Global         => null,
     Contract_Cases =>
       (Length (Container) = 0 =>
          Last'Result = No_Element,

        others =>
          Has_Element (Container, Last'Result)
            and P.Get (Positions (Container), Last'Result) =
                  Length (Container));

   function Last_Element (Container : Set) return Element_Type with
     Global => null,
     Pre    => not Is_Empty (Container),
     Post   =>
       Element_Logic_Equal
         (Last_Element'Result,
          E.Get (Elements (Container), Length (Container)))
         and E_Bigger_Than_Range
               (Elements (Container),
                1,
                Length (Container) - 1,
                Last_Element'Result);

   function Next (Container : Set; Position : Cursor) return Cursor with
     Global         => null,
     Pre            =>
       Has_Element (Container, Position) or else Position = No_Element,
     Contract_Cases =>
       (Position = No_Element
          or else P.Get (Positions (Container), Position) = Length (Container)
        =>
          Next'Result = No_Element,

        others =>
          Has_Element (Container, Next'Result)
            and then P.Get (Positions (Container), Next'Result) =
                     P.Get (Positions (Container), Position) + 1);

   procedure Next (Container : Set; Position : in out Cursor) with
     Global         => null,
     Pre            =>
       Has_Element (Container, Position) or else Position = No_Element,
     Contract_Cases =>
       (Position = No_Element
          or else P.Get (Positions (Container), Position) = Length (Container)
        =>
          Position = No_Element,

        others =>
          Has_Element (Container, Position)
            and then P.Get (Positions (Container), Position) =
                     P.Get (Positions (Container), Position'Old) + 1);

   function Previous (Container : Set; Position : Cursor) return Cursor with
     Global         => null,
     Pre            =>
       Has_Element (Container, Position) or else Position = No_Element,
     Contract_Cases =>
       (Position = No_Element
          or else P.Get (Positions (Container), Position) = 1
        =>
          Previous'Result = No_Element,

        others =>
          Has_Element (Container, Previous'Result)
            and then P.Get (Positions (Container), Previous'Result) =
                     P.Get (Positions (Container), Position) - 1);

   procedure Previous (Container : Set; Position : in out Cursor) with
     Global         => null,
     Pre            =>
       Has_Element (Container, Position) or else Position = No_Element,
     Contract_Cases =>
       (Position = No_Element
          or else P.Get (Positions (Container), Position) = 1
         =>
          Position = No_Element,

        others =>
          Has_Element (Container, Position)
            and then P.Get (Positions (Container), Position) =
                     P.Get (Positions (Container), Position'Old) - 1);

   function Find (Container : Set; Item : Element_Type) return Cursor with
     Global         => null,
     Contract_Cases =>

       --  If Item is not contained in Container, Find returns No_Element

       (not Contains (Model (Container), Item) =>
          not P.Has_Key (Positions (Container), Find'Result)
            and Find'Result = No_Element,

        --  Otherwise, Find returns a valid cursor in Container

        others =>
          P.Has_Key (Positions (Container), Find'Result)
            and P.Get (Positions (Container), Find'Result) =
                Find (Elements (Container), Item)

            --  The element designated by the result of Find is Item

            and Equivalent_Elements
                  (Element (Container, Find'Result), Item));

   function Floor (Container : Set; Item : Element_Type) return Cursor with
     Global         => null,
     Contract_Cases =>
       (Length (Container) = 0 or else Item < First_Element (Container) =>
          Floor'Result = No_Element,
        others =>
          Has_Element (Container, Floor'Result)
            and
              not (Item < E.Get (Elements (Container),
                                 P.Get (Positions (Container), Floor'Result)))
            and E_Is_Find
                  (Elements (Container),
                   Item,
                   P.Get (Positions (Container), Floor'Result)));

   function Ceiling (Container : Set; Item : Element_Type) return Cursor with
     Global         => null,
     Contract_Cases =>
       (Length (Container) = 0 or else Last_Element (Container) < Item =>
          Ceiling'Result = No_Element,
        others =>
          Has_Element (Container, Ceiling'Result)
            and
              not (E.Get (Elements (Container),
                          P.Get (Positions (Container), Ceiling'Result)) <
                   Item)
            and E_Is_Find
                  (Elements (Container),
                   Item,
                   P.Get (Positions (Container), Ceiling'Result)));

   function Contains (Container : Set; Item : Element_Type) return Boolean with
     Global => null,
     Post   => Contains'Result = Contains (Model (Container), Item);
   pragma Annotate (GNATprove, Inline_For_Proof, Contains);

   function Has_Element (Container : Set; Position : Cursor) return Boolean
   with
     Global => null,
     Post   =>
       Has_Element'Result = P.Has_Key (Positions (Container), Position);
   pragma Annotate (GNATprove, Inline_For_Proof, Has_Element);

   generic
      type Key_Type (<>) is private;

      with function Key (Element : Element_Type) return Key_Type;

      with function "<" (Left, Right : Key_Type) return Boolean is <>;

      --  Ghost lemma used to prove that "<" on keys is compatible with "<" on
      --  elements.

      with procedure Lt_Compatible (X, Y : Element_Type) is null
        with Ghost;

   package Generic_Keys with SPARK_Mode, Always_Terminates is

      --  Contracts in this unit are meant for analysis only, not for run-time
      --  checking.

      pragma Assertion_Policy (Ignore);

      function Equivalent_Keys (Left, Right : Key_Type) return Boolean with
        Global => null,
        Post   =>
          Equivalent_Keys'Result = (not (Left < Right) and not (Right < Left));
      pragma Annotate (GNATprove, Inline_For_Proof, Equivalent_Keys);

      package Formal_Model with Ghost is

         --------------------------
         -- Instantiation Checks --
         --------------------------

         package Lt_Compatibility_Checks is new
           SPARK.Containers.Parameter_Checks.Op_Compatibility_Checks
             (T1                  => Element_Type,
              T2                  => Key_Type,
              Op1                 => "<",
              Op2                 => "<",
              F                   => Key,
              Param_Op_Compatible => Lt_Compatible);
         --  Check that "<" on keys is compatible with "<" on elements

         ------------------
         -- Formal Model --
         ------------------

         function E_Bigger_Than_Range
           (Container : E.Sequence;
            Fst       : Positive_Count_Type;
            Lst       : Count_Type;
            Key       : Key_Type) return Boolean
         with
           Global => null,
           Pre    => Lst <= E.Last (Container),
           Post   =>
             E_Bigger_Than_Range'Result =
               (for all I in Fst .. Lst =>
                  Generic_Keys.Key (E.Get (Container, I)) < Key);
         pragma Annotate (GNATprove, Inline_For_Proof, E_Bigger_Than_Range);

         function E_Smaller_Than_Range
           (Container : E.Sequence;
            Fst       : Positive_Count_Type;
            Lst       : Count_Type;
            Key       : Key_Type) return Boolean
         with
           Global => null,
           Pre    => Lst <= E.Last (Container),
           Post   =>
             E_Smaller_Than_Range'Result =
               (for all I in Fst .. Lst =>
                  Key < Generic_Keys.Key (E.Get (Container, I)));
         pragma Annotate (GNATprove, Inline_For_Proof, E_Smaller_Than_Range);

         function E_Is_Find
           (Container : E.Sequence;
            Key       : Key_Type;
            Position  : Count_Type) return Boolean
         with
           Global => null,
           Pre    => Position - 1 <= E.Last (Container),
           Post   =>
             E_Is_Find'Result =

               ((if Position > 0 then
                   E_Bigger_Than_Range (Container, 1, Position - 1, Key))

                     and (if Position < E.Last (Container) then
                        E_Smaller_Than_Range
                          (Container,
                           Position + 1,
                           E.Last (Container),
                           Key)));
         pragma Annotate (GNATprove, Inline_For_Proof, E_Is_Find);

         function Find
           (Container : E.Sequence;
            Key       : Key_Type) return Count_Type
         --  Search for Key in Container

           with
             Global                  => null,
             Post                    =>
               (if Find'Result > 0 then
                  Find'Result <= E.Last (Container)
                    and Equivalent_Keys
                      (Key, Generic_Keys.Key (E.Get (Container, Find'Result)))
                    and E_Is_Find (Container, Key, Find'Result));

         function M_Included_Except
           (Left  : M.Set;
            Right : M.Set;
            Key   : Key_Type) return Boolean
           with
             Global                  => null,
             Post                    =>
               M_Included_Except'Result =
                 (for all E of Left =>
                    Contains (Right, E)
                      or Equivalent_Keys (Generic_Keys.Key (E), Key));
      end Formal_Model;
      use Formal_Model;

      function Key (Container : Set; Position : Cursor) return Key_Type with
        Global => null,
        Pre    => Has_Element (Container, Position),
        Post   => Key'Result = Key (Element (Container, Position));
      pragma Annotate (GNATprove, Inline_For_Proof, Key);

      function Element (Container : Set; Key : Key_Type) return Element_Type
      with
        Global => null,
        Pre    => Contains (Container, Key),
        Post   =>
          Element'Result = Element (Container, Find (Container, Key));
      pragma Annotate (GNATprove, Inline_For_Proof, Element);

      procedure Replace
        (Container : in out Set;
         Key       : Key_Type;
         New_Item  : Element_Type)
      with
        Global => null,
        Pre    => Contains (Container, Key),
        Post   =>
          Length (Container) = Length (Container)'Old

             --  Key now maps to New_Item

             and Element_Logic_Equal
                   (Element (Container, Find (Container, Key)'Old),
                    E.Copy_Element (New_Item))

             --  New_Item is contained in Container

             and Contains (Model (Container), New_Item)

             --  Other elements are preserved

             and M_Included_Except
                   (Model (Container)'Old,
                    Model (Container),
                    Key)
             and M.Included_Except
                   (Model (Container),
                    Model (Container)'Old,
                    New_Item)

             --  Mapping from cursors to elements is preserved

             and Mapping_Preserved_Except
                   (E_Left   => Elements (Container)'Old,
                    E_Right  => Elements (Container),
                    P_Left   => Positions (Container)'Old,
                    P_Right  => Positions (Container),
                    Position => Find (Container, Key)'Old)
             and P.Keys_Included (Positions (Container),
                                  Positions (Container)'Old);

      procedure Exclude (Container : in out Set; Key : Key_Type) with
        Global         => null,
        Post           => not Contains (Container, Key),
        Contract_Cases =>

          --  If Key is not in Container, nothing is changed

          (not Contains (Container, Key) =>
             Model (Container) = Model (Container)'Old
               and E.Equal (Elements (Container), Elements (Container)'Old)
               and Positions (Container) = Positions (Container)'Old,

           --  Otherwise, Key is removed from Container

           others =>
             Length (Container) = Length (Container)'Old - 1

               --  Other elements are preserved

               and Model (Container) <= Model (Container)'Old
               and M_Included_Except
                     (Model (Container)'Old,
                      Model (Container),
                      Key)

               --  The elements of Container located before Key are preserved

               and E.Range_Equal
                     (Left  => Elements (Container)'Old,
                      Right => Elements (Container),
                      Fst   => 1,
                      Lst   => Find (Elements (Container), Key)'Old - 1)

               --  The elements located after Key are shifted by 1

               and E.Range_Shifted
                     (Left   => Elements (Container),
                      Right  => Elements (Container)'Old,
                      Fst    => Find (Elements (Container), Key)'Old,
                      Lst    => Length (Container),
                      Offset => 1)

               --  A cursor has been removed from Container

               and P_Positions_Shifted
                     (Positions (Container),
                      Positions (Container)'Old,
                      Cut   => Find (Elements (Container), Key)'Old));

      procedure Delete (Container : in out Set; Key : Key_Type) with
        Global => null,
        Pre    => Contains (Container, Key),
        Post   =>
          Length (Container) = Length (Container)'Old - 1

            --  Key is no longer in Container

            and not Contains (Container, Key)

            --  Other elements are preserved

            and Model (Container) <= Model (Container)'Old
            and M_Included_Except
                  (Model (Container)'Old,
                   Model (Container),
                   Key)

            --  The elements of Container located before Key are preserved

            and E.Range_Equal
                  (Left  => Elements (Container)'Old,
                   Right => Elements (Container),
                   Fst   => 1,
                   Lst   => Find (Elements (Container), Key)'Old - 1)

            --  The elements located after Key are shifted by 1

            and E.Range_Shifted
                  (Left   => Elements (Container),
                   Right  => Elements (Container)'Old,
                   Fst    => Find (Elements (Container), Key)'Old,
                   Lst    => Length (Container),
                   Offset => 1)

            --  A cursor has been removed from Container

            and P_Positions_Shifted
                  (Positions (Container),
                   Positions (Container)'Old,
                   Cut   => Find (Elements (Container), Key)'Old);

      function Find (Container : Set; Key : Key_Type) return Cursor with
        Global         => null,
        Contract_Cases =>

          --  If Key is not contained in Container, Find returns No_Element

          ((for all E of Model (Container) =>
               not Equivalent_Keys (Key, Generic_Keys.Key (E))) =>
             not P.Has_Key (Positions (Container), Find'Result)
               and Find'Result = No_Element,

           --  Otherwise, Find returns a valid cursor in Container

           others =>
             P.Has_Key (Positions (Container), Find'Result)
               and P.Get (Positions (Container), Find'Result) =
                   Find (Elements (Container), Key)

               --  The element designated by the result of Find is Key

               and Equivalent_Keys
                  (Generic_Keys.Key (Element (Container, Find'Result)), Key));

      function Floor (Container : Set; Key : Key_Type) return Cursor with
        Global         => null,
        Contract_Cases =>
          (Length (Container) = 0
             or else Key < Generic_Keys.Key (First_Element (Container)) =>
             Floor'Result = No_Element,
           others =>
              Has_Element (Container, Floor'Result)
               and
                 not (Key <
                      Generic_Keys.Key
                       (E.Get (Elements (Container),
                               P.Get (Positions (Container), Floor'Result))))
               and E_Is_Find
                     (Elements (Container),
                      Key,
                      P.Get (Positions (Container), Floor'Result)));

      function Ceiling (Container : Set; Key : Key_Type) return Cursor with
        Global         => null,
        Contract_Cases =>
          (Length (Container) = 0
             or else Generic_Keys.Key (Last_Element (Container)) < Key =>
             Ceiling'Result = No_Element,
           others =>
             Has_Element (Container, Ceiling'Result)
               and
                 not (Generic_Keys.Key
                       (E.Get (Elements (Container),
                               P.Get (Positions (Container), Ceiling'Result)))
                      < Key)
               and E_Is_Find
                     (Elements (Container),
                      Key,
                      P.Get (Positions (Container), Ceiling'Result)));

      function Contains (Container : Set; Key : Key_Type) return Boolean with
        Global => null,
        Post   =>
          Contains'Result =
            (for some E of Model (Container) =>
                Equivalent_Keys (Key, Generic_Keys.Key (E)));

   end Generic_Keys;

   ------------------------------------------------------------------
   -- Additional Expression Functions For Iteration and Aggregates --
   ------------------------------------------------------------------

   function Aggr_Capacity return Count_Type is
      (Count_Type'Last)
   with
     Ghost,
     Global   => null,
     Annotate => (GNATprove, Inline_For_Proof),
     Annotate => (GNATprove, Container_Aggregates, "Capacity");

   function Aggr_Model (Container : Set) return M.Set is
      (Model (Container))
   with
     Ghost,
     Global   => null,
     Annotate => (GNATprove, Inline_For_Proof),
     Annotate => (GNATprove, Container_Aggregates, "Model");

   function Iter_Model (Container : Set) return E.Sequence is
      (Elements (Container))
   with
     Ghost,
     Global   => null,
     Annotate => (GNATprove, Inline_For_Proof),
     Annotate => (GNATprove, Iterable_For_Proof, "Model");

private
   pragma SPARK_Mode (Off);

   pragma Inline (Next);
   pragma Inline (Previous);

   type Element_Access is access Element_Type;

   --  Define Holders

   package Element_Holder is new Holders (Element_Type);
   use Element_Holder;

   --  Define the node type and tree

   type Node_Type is record
      Has_Element : Boolean := False;
      Parent      : Count_Type := 0;
      Left        : Count_Type := 0;
      Right       : Count_Type := 0;
      Color       : Red_Black_Trees.Color_Type;
      E_Holder    : Holder_Type;
   end record;

   package Tree_Types is
     new Red_Black_Trees.Generic_Bounded_Tree_Types (Node_Type);

   type Tree_Access is access all Tree_Types.Tree_Type;

   Empty_Tree : aliased Tree_Types.Tree_Type (0);

   type Set is new Ada.Finalization.Controlled
   with record
     Content : not null Tree_Access := Empty_Tree'Access;
   end record;

   use Red_Black_Trees;

   overriding procedure Adjust (S : in out Set);
   --  Makes a proper copy of the set to avoid sharing

   overriding procedure Finalize (S : in out Set);
   --  Safly deallocate the content
end SPARK.Containers.Formal.Unbounded_Ordered_Sets;
