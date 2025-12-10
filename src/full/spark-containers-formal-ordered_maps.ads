--
--  Copyright (C) 2004-2025, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This spec is derived from package Ada.Containers.Bounded_Ordered_Maps in
--  the Ada 2012 RM. The modifications are meant to facilitate formal proofs by
--  making it easier to express properties, and by making the specification of
--  this unit compatible with SPARK. Note that the API of this unit may be
--  subject to incompatible changes as evolves.

--  Iteration over maps is done using the Iterable aspect, which is SPARK
--  compatible. "For of" iteration ranges over keys instead of elements.

pragma Ada_2022;

with SPARK.Big_Integers;     use SPARK.Big_Integers;
with SPARK.Containers.Functional.Vectors;
with SPARK.Containers.Functional.Maps;
with SPARK.Containers.Parameter_Checks;
with SPARK.Containers.Types; use SPARK.Containers.Types;

private with Ada.Containers.Red_Black_Trees;

generic
   type Key_Type is private;
   type Element_Type is private;

   with function "<" (Left, Right : Key_Type) return Boolean is <>;
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

   --  Ghost lemmas used to prove that "<" is a strict weak ordering
   --  relationship.

   with
     procedure Lt_Irreflexive (X : Key_Type) is null
     with Ghost => Static;
   with
     procedure Lt_Asymmetric (X, Y : Key_Type) is null
     with Ghost => Static;
   with
     procedure Lt_Transitive (X, Y, Z : Key_Type) is null
     with Ghost => Static;
   with
     procedure Lt_Order (X, Y, Z : Key_Type) is null
     with Ghost => Static;

package SPARK.Containers.Formal.Ordered_Maps with SPARK_Mode, Always_Terminates
is
   pragma Annotate (CodePeer, Skip_Analysis);

   function Equivalent_Keys (Left, Right : Key_Type) return Boolean
   with
     Global => null,
     Post   =>
       (SPARKlib_Full =>
          Equivalent_Keys'Result
          = (not (Left < Right) and not (Right < Left)));
   pragma Annotate (GNATprove, Inline_For_Proof, Entity => Equivalent_Keys);

   pragma
     Annotate
       (GNATcheck,
        Exempt_On,
        "Restrictions:No_Specification_Of_Aspect => Iterable",
        "The following usage of aspect Iterable has been reviewed"
          & "for compliance with GNATprove assumption"
          & " [SPARK_ITERABLE]");
   type Map (Capacity : Count_Type) is private
   with
     Iterable                  =>
       (First       => First,
        Next        => Next,
        Has_Element => Has_Element,
        Element     => Key),
     Default_Initial_Condition => (SPARKlib_Full => Is_Empty (Map)),
     Aggregate                 => (Empty => Empty_Map, Add_Named => Insert),
     Annotate                  =>
       (GNATprove, Container_Aggregates, "From_Model");
   pragma
     Annotate
       (GNATcheck,
        Exempt_Off,
        "Restrictions:No_Specification_Of_Aspect => Iterable");

   function Empty_Map (Capacity : Count_Type := 10) return Map
   with
     Post =>
       (SPARKlib_Full =>
          Is_Empty (Empty_Map'Result)
          and then Empty_Map'Result.Capacity = Capacity);

   type Cursor is record
      Node : Count_Type;
   end record;

   No_Element : constant Cursor := (Node => 0);

   function Length (Container : Map) return Count_Type
   with
     Global => null,
     Post   => (SPARKlib_Full => Length'Result <= Container.Capacity);

   pragma Unevaluated_Use_Of_Old (Allow);

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

      package Lift_Eq is new
        SPARK.Containers.Parameter_Checks.Lift_Eq_Reflexive
          (T                  => Element_Type,
           "="                => "=",
           Eq                 => "=",
           Param_Eq_Reflexive => Eq_Checks.Eq_Reflexive);

      package Lt_Checks is new
        SPARK.Containers.Parameter_Checks.Strict_Weak_Order_Checks
          (T                    => Key_Type,
           "<"                  => "<",
           Param_Lt_Irreflexive => Lt_Irreflexive,
           Param_Lt_Asymmetric  => Lt_Asymmetric,
           Param_Lt_Transitive  => Lt_Transitive,
           Param_Lt_Order       => Lt_Order);
      --  Check that "<" is a strict weak ordering relationship

      package Lift_Equivalent_Keys is new
        SPARK.Containers.Parameter_Checks.Lift_Eq_Reflexive
          (T                  => Key_Type,
           "="                => Equivalent_Keys,
           Eq                 => Equivalent_Keys,
           Param_Eq_Reflexive => Lt_Checks.Eq_Reflexive);

      ------------------
      -- Formal Model --
      ------------------

      subtype Positive_Count_Type is Count_Type range 1 .. Count_Type'Last;

      package M is new
        SPARK.Containers.Functional.Maps
          (Element_Type                   => Element_Type,
           Key_Type                       => Key_Type,
           Equivalent_Keys                => Equivalent_Keys,
           "="                            => "=",
           Eq_Reflexive                   => Eq_Checks.Eq_Reflexive,
           Eq_Symmetric                   => Eq_Checks.Eq_Symmetric,
           Eq_Transitive                  => Eq_Checks.Eq_Transitive,
           Equivalent_Elements            => "=",
           Equivalent_Elements_Reflexive  => Lift_Eq.Eq_Reflexive,
           Equivalent_Elements_Symmetric  => Eq_Checks.Eq_Symmetric,
           Equivalent_Elements_Transitive => Eq_Checks.Eq_Transitive,
           Equivalent_Keys_Reflexive      => Lt_Checks.Eq_Reflexive,
           Equivalent_Keys_Symmetric      => Lt_Checks.Eq_Symmetric,
           Equivalent_Keys_Transitive     => Lt_Checks.Eq_Transitive);

      function Element_Logic_Equal (Left, Right : Element_Type) return Boolean
      renames M.Element_Logic_Equal;

      function "=" (Left : M.Map; Right : M.Map) return Boolean renames M."=";

      function "<=" (Left : M.Map; Right : M.Map) return Boolean
      renames M."<=";

      package K is new
        SPARK.Containers.Functional.Vectors
          (Element_Type                   => Key_Type,
           Index_Type                     => Positive_Count_Type,
           "="                            => Equivalent_Keys,
           Eq_Reflexive                   => Lt_Checks.Eq_Reflexive,
           Eq_Symmetric                   => Lt_Checks.Eq_Symmetric,
           Eq_Transitive                  => Lt_Checks.Eq_Transitive,
           Equivalent_Elements            => Equivalent_Keys,
           Equivalent_Elements_Reflexive  => Lift_Equivalent_Keys.Eq_Reflexive,
           Equivalent_Elements_Symmetric  => Lt_Checks.Eq_Symmetric,
           Equivalent_Elements_Transitive => Lt_Checks.Eq_Transitive);

      function Key_Logic_Equal (Left, Right : Key_Type) return Boolean
      renames K.Element_Logic_Equal;

      function "=" (Left : K.Sequence; Right : K.Sequence) return Boolean
      renames K."=";

      function "<" (Left : K.Sequence; Right : K.Sequence) return Boolean
      renames K."<";

      function "<=" (Left : K.Sequence; Right : K.Sequence) return Boolean
      renames K."<=";

      function K_Bigger_Than_Range
        (Container : K.Sequence;
         Fst       : Positive_Count_Type;
         Lst       : Count_Type;
         Key       : Key_Type) return Boolean
      with
        Global => null,
        Pre    => (SPARKlib_Defensive => Lst <= K.Last (Container)),
        Post   =>
          (SPARKlib_Full =>
             K_Bigger_Than_Range'Result
             = (for all I in Fst .. Lst => K.Get (Container, I) < Key));
      pragma
        Annotate (GNATprove, Inline_For_Proof, Entity => K_Bigger_Than_Range);

      function K_Smaller_Than_Range
        (Container : K.Sequence;
         Fst       : Positive_Count_Type;
         Lst       : Count_Type;
         Key       : Key_Type) return Boolean
      with
        Global => null,
        Pre    => (SPARKlib_Defensive => Lst <= K.Last (Container)),
        Post   =>
          (SPARKlib_Full =>
             K_Smaller_Than_Range'Result
             = (for all I in Fst .. Lst => Key < K.Get (Container, I)));
      pragma
        Annotate (GNATprove, Inline_For_Proof, Entity => K_Smaller_Than_Range);

      function K_Is_Find
        (Container : K.Sequence; Key : Key_Type; Position : Count_Type)
         return Boolean
      with
        Global => null,
        Pre    => (SPARKlib_Defensive => Position - 1 <= K.Last (Container)),
        Post   =>
          (SPARKlib_Full =>
             K_Is_Find'Result
             = ((if Position > 0
                 then K_Bigger_Than_Range (Container, 1, Position - 1, Key))

                and
                  (if Position < K.Last (Container)
                   then
                     K_Smaller_Than_Range
                       (Container, Position + 1, K.Last (Container), Key))));
      pragma Annotate (GNATprove, Inline_For_Proof, Entity => K_Is_Find);

      function Find (Container : K.Sequence; Key : Key_Type) return Count_Type
      with
        Global => null,
        Post   =>
          (SPARKlib_Full =>
             (if Find'Result > 0
              then
                Find'Result <= K.Last (Container)
                and Equivalent_Keys (Key, K.Get (Container, Find'Result))));
      --  Search for Key in Container

      package P is new
        SPARK.Containers.Functional.Maps
          (Key_Type                       => Cursor,
           Element_Type                   => Positive_Count_Type,
           Equivalent_Keys                => "=",
           Enable_Handling_Of_Equivalence => False);

      function "=" (Left : P.Map; Right : P.Map) return Boolean renames P."=";

      function "<=" (Left : P.Map; Right : P.Map) return Boolean
      renames P."<=";

      function P_Positions_Shifted
        (Small : P.Map;
         Big   : P.Map;
         Cut   : Positive_Count_Type;
         Count : Count_Type := 1) return Boolean
      with
        Global => null,
        Post   =>
          (SPARKlib_Full =>
             P_Positions_Shifted'Result
             =

             --  Big contains all cursors of Small

             (P.Keys_Included (Small, Big)

              --  Cursors located before Cut are not moved, cursors located
              --  after are shifted by Count.

              and
                (for all I of Small =>
                   (if P.Get (Small, I) < Cut
                    then P.Get (Big, I) = P.Get (Small, I)
                    else P.Get (Big, I) - Count = P.Get (Small, I)))

              --  New cursors of Big (if any) are between Cut and Cut - 1 +
              --  Count.

              and
                (for all I of Big =>
                   P.Has_Key (Small, I)
                   or P.Get (Big, I) - Count in Cut - Count .. Cut - 1)));

      function Model (Container : Map) return M.Map
      with
        Global => null,
        Post   =>
          (SPARKlib_Full =>
             M.Length (Model'Result) = K.Big (Length (Container)));
      --  The high-level model of a map is a map from keys to elements. Neither
      --  cursors nor order of elements are represented in this model. Keys are
      --  modeled up to equivalence.

      function Keys (Container : Map) return K.Sequence
      with
        --  The Keys sequence represents the underlying list structure of maps
        --  that is used for iteration. It stores the actual values of keys in
        --  the map. It does not model cursors nor elements.

        Global => null,
        Post   =>
          (SPARKlib_Full =>
             K.Last (Keys'Result) = Length (Container)

             --  It only contains keys contained in Model

             and
               (for all Key of Keys'Result =>
                  M.Has_Key (Model (Container), Key))

             --  It contains all the keys contained in Model

             and
               (for all Key of Model (Container) =>
                  (Find (Keys'Result, Key) > 0
                   and
                     Equivalent_Keys
                       (K.Get (Keys'Result, Find (Keys'Result, Key)), Key)))

             --  It is sorted in increasing order

             and
               (for all I in 1 .. Length (Container) =>
                  Find (Keys'Result, K.Get (Keys'Result, I)) = I
                  and K_Is_Find (Keys'Result, K.Get (Keys'Result, I), I)));

      function Positions (Container : Map) return P.Map
      with
        --  The Positions map is used to model cursors. It only contains valid
        --  cursors and maps them to their position in the container.

        Global => null,
        Post   =>
          (SPARKlib_Full =>
             not P.Has_Key (Positions'Result, No_Element)
             and then
               (for all I of Positions'Result =>
                  P.Get (Positions'Result, I) in 1 .. Length (Container)
                  and then
                    (for all J of Positions'Result =>
                       (if P.Get (Positions'Result, I)
                          = P.Get (Positions'Result, J)
                        then I = J))));
      --  Positions of cursors are smaller than the container's length
      --  No two cursors have the same position. Note that we do not
      --  state that there is a cursor in the map for each position,
      --  as it is rarely needed.

      procedure Lift_Abstraction_Level (Container : Map)
      with
        --  Lift_Abstraction_Level is a ghost procedure that does nothing but
        --  assume that we can access the same elements by iterating over
        --  positions or cursors.
        --  This information is not generally useful except when switching from
        --  a low-level, cursor-aware view of a container, to a high-level,
        --  position-based view.

        Ghost  => SPARKlib_Full,
        Global => null,
        Post   =>
          (for all Key of Keys (Container) =>
             (for some I of Positions (Container) =>
                Key_Logic_Equal
                  (K.Get (Keys (Container), P.Get (Positions (Container), I)),
                   Key)));

      function Contains (C : M.Map; K : Key_Type) return Boolean
      renames M.Has_Key;
      --  To improve readability of contracts, we rename the function used to
      --  search for a key in the model to Contains.

      function Element (C : M.Map; K : Key_Type) return Element_Type
      renames M.Get;
      --  To improve readability of contracts, we rename the function used to
      --  access an element in the model to Element.
   end Formal_Model;
   use Formal_Model;

   function "=" (Left, Right : Map) return Boolean
   with
     Global => null,
     Post   =>
       (SPARKlib_Full =>
          "="'Result = (M.Equivalent_Maps (Model (Left), Model (Right))));

   function Is_Empty (Container : Map) return Boolean
   with
     Global => null,
     Post   =>
       (SPARKlib_Full =>
          Is_Empty'Result = M.Is_Empty (Model (Container))
          and Is_Empty'Result = (Length (Container) = 0));

   procedure Clear (Container : in out Map)
   with
     Global => null,
     Post   =>
       (SPARKlib_Full =>
          Length (Container) = 0 and M.Is_Empty (Model (Container)));

   procedure Assign (Target : in out Map; Source : Map)
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => Target.Capacity >= Length (Source)),
     Post   =>
       (SPARKlib_Full =>
          M.Equal (Model (Target), Model (Source))
          and K.Equal (Keys (Target), Keys (Source))
          and Length (Source) = Length (Target));

   function Copy (Source : Map; Capacity : Count_Type := 0) return Map
   with
     Global => null,
     Pre    =>
       (SPARKlib_Defensive =>
          Capacity = 0 or else Capacity >= Source.Capacity),
     Post   =>
       (SPARKlib_Full =>
          M.Equal (Model (Copy'Result), Model (Source))
          and K.Equal (Keys (Copy'Result), Keys (Source))
          and Positions (Copy'Result) = Positions (Source)
          and
            (if Capacity = 0
             then Copy'Result.Capacity = Source.Capacity
             else Copy'Result.Capacity = Capacity));

   function Key (Container : Map; Position : Cursor) return Key_Type
   with
     Global   => null,
     Pre      => (SPARKlib_Defensive => Has_Element (Container, Position)),
     Post     =>
       (SPARKlib_Full =>
          Key'Result
          = K.Get (Keys (Container), P.Get (Positions (Container), Position))),
     Annotate => (GNATprove, Inline_For_Proof);

   function Element (Container : Map; Position : Cursor) return Element_Type
   with
     Global   => null,
     Pre      => (SPARKlib_Defensive => Has_Element (Container, Position)),
     Post     =>
       (SPARKlib_Full =>
          Element'Result
          = Element (Model (Container), Key (Container, Position))),
     Annotate => (GNATprove, Inline_For_Proof);

   procedure Replace_Element
     (Container : in out Map; Position : Cursor; New_Item : Element_Type)
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => Has_Element (Container, Position)),
     Post   =>
       (SPARKlib_Full =>
          K.Equal (Keys (Container), Keys (Container)'Old)
          and Positions (Container) = Positions (Container)'Old
          and
            Element_Logic_Equal
              (Element (Container, Position), M.Copy_Element (New_Item))
          and M.Same_Keys (Model (Container), Model (Container)'Old)
          and
            M.Elements_Equal_Except
              (Model (Container),
               Model (Container)'Old,
               Key (Container, Position)));
   --  Order of keys and cursors is preserved
   --  New_Item is now associated with the key at position Position in
   --  Container.
   --  Elements associated with other keys are preserved

   function At_End (E : Map) return Map
   is (E)
   with Ghost => SPARKlib_Full, Annotate => (GNATprove, At_End_Borrow);

   function At_End
     (E : access constant Element_Type) return access constant Element_Type
   is (E)
   with Ghost => SPARKlib_Full, Annotate => (GNATprove, At_End_Borrow);

   function Constant_Reference
     (Container : aliased Map; Position : Cursor)
      return not null access constant Element_Type
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => Has_Element (Container, Position)),
     Post   =>
       (SPARKlib_Full =>
          Element_Logic_Equal
            (Constant_Reference'Result.all,
             Element (Model (Container), Key (Container, Position))));

   function Reference
     (Container : aliased in out Map; Position : Cursor)
      return not null access Element_Type
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => Has_Element (Container, Position)),
     Post   =>
       (SPARKlib_Full =>

          --  Order of keys and cursors is preserved

          K.Equal (Keys (At_End (Container)), Keys (Container))
          and Positions (At_End (Container)) = Positions (Container)

          --  The value designated by the result of Reference is now
          --  associated with the key at position Position in Container.

          and
            Element_Logic_Equal
              (Element (At_End (Container), Position),
               At_End (Reference'Result).all)

          --  Elements associated with other keys are preserved

          and M.Same_Keys (Model (At_End (Container)), Model (Container))
          and
            M.Elements_Equal_Except
              (Model (At_End (Container)),
               Model (Container),
               Key (At_End (Container), Position)));

   function Constant_Reference
     (Container : aliased Map; Key : Key_Type)
      return not null access constant Element_Type
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => Contains (Container, Key)),
     Post   =>
       (SPARKlib_Full =>
          Element_Logic_Equal
            (Constant_Reference'Result.all, Element (Model (Container), Key)));

   function Reference
     (Container : aliased in out Map; Key : Key_Type)
      return not null access Element_Type
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => Contains (Container, Key)),
     Post   =>
       (SPARKlib_Full =>

          --  Order of keys and cursors is preserved

          K.Equal (Keys (At_End (Container)), Keys (Container))
          and Positions (At_End (Container)) = Positions (Container)

          --  The value designated by the result of Reference is now
          --  associated with Key in Container.

          and
            Element_Logic_Equal
              (Element (Model (At_End (Container)), Key),
               At_End (Reference'Result).all)

          --  Elements associated with other keys are preserved

          and M.Same_Keys (Model (At_End (Container)), Model (Container))
          and
            M.Elements_Equal_Except
              (Model (At_End (Container)), Model (Container), Key));

   procedure Move (Target : in out Map; Source : in out Map)
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => Target.Capacity >= Length (Source)),
     Post   =>
       (SPARKlib_Full =>
          M.Equal (Model (Target), Model (Source)'Old)
          and K.Equal (Keys (Target), Keys (Source)'Old)
          and Length (Source)'Old = Length (Target)
          and Length (Source) = 0);

   procedure Insert
     (Container : in out Map;
      Key       : Key_Type;
      New_Item  : Element_Type;
      Position  : out Cursor;
      Inserted  : out Boolean)
   with
     Global         => null,
     Pre            =>
       (SPARKlib_Defensive =>
          Length (Container) < Container.Capacity
          or Contains (Container, Key)),
     Post           =>
       (SPARKlib_Full =>
          Contains (Container, Key)
          and Has_Element (Container, Position)
          and Equivalent_Keys (Ordered_Maps.Key (Container, Position), Key)
          and
            K_Is_Find
              (Keys (Container),
               Key,
               P.Get (Positions (Container), Position))),
     Contract_Cases =>
       (SPARKlib_Full =>

          --  If Key is already in Container, it is not modified and Inserted
          --  is set to False.

          (Contains (Container, Key) =>
             not Inserted
             and M.Equal (Model (Container), Model (Container)'Old)
             and K.Equal (Keys (Container), Keys (Container)'Old)
             and Positions (Container) = Positions (Container)'Old,

           --  Otherwise, Key is inserted in Container and Inserted is set to
           --  True.

           others                    =>
             Inserted
             and Length (Container) = Length (Container)'Old + 1

             --  Key now maps to New_Item

             and
               Key_Logic_Equal
                 (Ordered_Maps.Key (Container, Position), K.Copy_Element (Key))
             and
               Element_Logic_Equal
                 (Element (Model (Container), Key), M.Copy_Element (New_Item))

             --  Other mappings are preserved

             and M.Elements_Equal (Model (Container)'Old, Model (Container))
             and
               M.Keys_Included_Except
                 (Model (Container), Model (Container)'Old, Key)

             --  The keys of Container located before Position are preserved

             and
               K.Range_Equal
                 (Left  => Keys (Container)'Old,
                  Right => Keys (Container),
                  Fst   => 1,
                  Lst   => P.Get (Positions (Container), Position) - 1)

             --  Other keys are shifted by 1

             and
               K.Range_Shifted
                 (Left   => Keys (Container)'Old,
                  Right  => Keys (Container),
                  Fst    => P.Get (Positions (Container), Position),
                  Lst    => Length (Container)'Old,
                  Offset => 1)

             --  A new cursor has been inserted at position Position in
             --  Container.

             and
               P_Positions_Shifted
                 (Positions (Container)'Old,
                  Positions (Container),
                  Cut => P.Get (Positions (Container), Position))));

   procedure Insert
     (Container : in out Map; Key : Key_Type; New_Item : Element_Type)
   with
     Global => null,
     Pre    =>
       (SPARKlib_Defensive =>
          Length (Container) < Container.Capacity
          and then not Contains (Container, Key)),
     Post   =>
       (SPARKlib_Full =>
          Length (Container) = Length (Container)'Old + 1
          and Contains (Container, Key)

          --  Key now maps to New_Item

          and
            Key_Logic_Equal
              (K.Get (Keys (Container), Find (Keys (Container), Key)),
               K.Copy_Element (Key))
          and
            Element_Logic_Equal
              (Element (Model (Container), Key), M.Copy_Element (New_Item))

          --  Other mappings are preserved

          and M.Elements_Equal (Model (Container)'Old, Model (Container))
          and
            M.Keys_Included_Except
              (Model (Container), Model (Container)'Old, Key)

          --  The keys of Container located before Key are preserved

          and
            K.Range_Equal
              (Left  => Keys (Container)'Old,
               Right => Keys (Container),
               Fst   => 1,
               Lst   => Find (Keys (Container), Key) - 1)

          --  Other keys are shifted by 1

          and
            K.Range_Shifted
              (Left   => Keys (Container)'Old,
               Right  => Keys (Container),
               Fst    => Find (Keys (Container), Key),
               Lst    => Length (Container)'Old,
               Offset => 1)

          --  A new cursor has been inserted in Container

          and
            P_Positions_Shifted
              (Positions (Container)'Old,
               Positions (Container),
               Cut => Find (Keys (Container), Key)));

   procedure Include
     (Container : in out Map; Key : Key_Type; New_Item : Element_Type)
   with
     Global         => null,
     Pre            =>
       (SPARKlib_Defensive =>
          Length (Container) < Container.Capacity
          or Contains (Container, Key)),
     Post           =>
       (SPARKlib_Full =>
          Contains (Container, Key)
          and
            Element_Logic_Equal
              (Element (Container, Key), M.Copy_Element (New_Item))),
     Contract_Cases =>
       (SPARKlib_Full =>

          --  If Key is already in Container, Key is mapped to New_Item

          (Contains (Container, Key) =>

             --  Cursors are preserved

             Positions (Container)
             = Positions (Container)'Old

               --  The key equivalent to Key in Container is replaced by Key

             and
               Key_Logic_Equal
                 (K.Get (Keys (Container), Find (Keys (Container), Key)),
                  K.Copy_Element (Key))

             and
               K.Equal_Except
                 (Keys (Container)'Old,
                  Keys (Container),
                  Find (Keys (Container), Key))

             --  Elements associated with other keys are preserved

             and M.Same_Keys (Model (Container), Model (Container)'Old)
             and
               M.Elements_Equal_Except
                 (Model (Container), Model (Container)'Old, Key),

           --  Otherwise, Key is inserted in Container

           others                    =>
             Length (Container) = Length (Container)'Old + 1

             --  Other mappings are preserved

             and M.Elements_Equal (Model (Container)'Old, Model (Container))
             and
               M.Keys_Included_Except
                 (Model (Container), Model (Container)'Old, Key)

             --  Key is inserted in Container

             and
               Key_Logic_Equal
                 (K.Get (Keys (Container), Find (Keys (Container), Key)),
                  K.Copy_Element (Key))

             --  The keys of Container located before Key are preserved

             and
               K.Range_Equal
                 (Left  => Keys (Container)'Old,
                  Right => Keys (Container),
                  Fst   => 1,
                  Lst   => Find (Keys (Container), Key) - 1)

             --  Other keys are shifted by 1

             and
               K.Range_Shifted
                 (Left   => Keys (Container)'Old,
                  Right  => Keys (Container),
                  Fst    => Find (Keys (Container), Key),
                  Lst    => Length (Container)'Old,
                  Offset => 1)

             --  A new cursor has been inserted in Container

             and
               P_Positions_Shifted
                 (Positions (Container)'Old,
                  Positions (Container),
                  Cut => Find (Keys (Container), Key))));

   procedure Replace
     (Container : in out Map; Key : Key_Type; New_Item : Element_Type)
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => Contains (Container, Key)),
     Post   =>
       (SPARKlib_Full =>

          --  Cursors are preserved

          Positions (Container)
          = Positions (Container)'Old

            --  The key equivalent to Key in Container is replaced by Key

          and
            Key_Logic_Equal
              (K.Get (Keys (Container), Find (Keys (Container), Key)),
               K.Copy_Element (Key))
          and
            K.Equal_Except
              (Keys (Container)'Old,
               Keys (Container),
               Find (Keys (Container), Key))

          --  New_Item is now associated with the Key in Container

          and
            Element_Logic_Equal
              (Element (Model (Container), Key), M.Copy_Element (New_Item))

          --  Elements associated with other keys are preserved

          and M.Same_Keys (Model (Container), Model (Container)'Old)
          and
            M.Elements_Equal_Except
              (Model (Container), Model (Container)'Old, Key));

   procedure Exclude (Container : in out Map; Key : Key_Type)
   with
     Global         => null,
     Post           => (SPARKlib_Defensive => not Contains (Container, Key)),
     Contract_Cases =>
       (SPARKlib_Full =>

          --  If Key is not in Container, nothing is changed

          (not Contains (Container, Key) =>
             M.Equal (Model (Container), Model (Container)'Old)
             and K.Equal (Keys (Container), Keys (Container)'Old)
             and Positions (Container) = Positions (Container)'Old,

           --  Otherwise, Key is removed from Container

           others                        =>
             Length (Container) = Length (Container)'Old - 1

             --  Other mappings are preserved

             and M.Elements_Equal (Model (Container), Model (Container)'Old)
             and
               M.Keys_Included_Except
                 (Model (Container)'Old, Model (Container), Key)

             --  The keys of Container located before Key are preserved

             and
               K.Range_Equal
                 (Left  => Keys (Container)'Old,
                  Right => Keys (Container),
                  Fst   => 1,
                  Lst   => Find (Keys (Container), Key)'Old - 1)

             --  The keys located after Key are shifted by 1

             and
               K.Range_Shifted
                 (Left   => Keys (Container),
                  Right  => Keys (Container)'Old,
                  Fst    => Find (Keys (Container), Key)'Old,
                  Lst    => Length (Container),
                  Offset => 1)

             --  A cursor has been removed from Container

             and
               P_Positions_Shifted
                 (Positions (Container),
                  Positions (Container)'Old,
                  Cut => Find (Keys (Container), Key)'Old)));

   procedure Delete (Container : in out Map; Key : Key_Type)
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => Contains (Container, Key)),
     Post   =>
       (SPARKlib_Full =>
          Length (Container) = Length (Container)'Old - 1

          --  Key is no longer in Container

          and not Contains (Container, Key)

          --  Other mappings are preserved

          and M.Elements_Equal (Model (Container), Model (Container)'Old)
          and
            M.Keys_Included_Except
              (Model (Container)'Old, Model (Container), Key)

          --  The keys of Container located before Key are preserved

          and
            K.Range_Equal
              (Left  => Keys (Container)'Old,
               Right => Keys (Container),
               Fst   => 1,
               Lst   => Find (Keys (Container), Key)'Old - 1)

          --  The keys located after Key are shifted by 1

          and
            K.Range_Shifted
              (Left   => Keys (Container),
               Right  => Keys (Container)'Old,
               Fst    => Find (Keys (Container), Key)'Old,
               Lst    => Length (Container),
               Offset => 1)

          --  A cursor has been removed from Container

          and
            P_Positions_Shifted
              (Positions (Container),
               Positions (Container)'Old,
               Cut => Find (Keys (Container), Key)'Old));

   procedure Delete (Container : in out Map; Position : in out Cursor)
   with
     Global  => null,
     -- incorrect formatting of "+" eng/ide/gnatformat#221
     --!format off
     Depends => (Container =>+ Position, Position => null),
     --!format on
     Pre     => (SPARKlib_Defensive => Has_Element (Container, Position)),
     Post    =>
       (SPARKlib_Full =>
          Position = No_Element
          and Length (Container) = Length (Container)'Old - 1

          --  The key at position Position is no longer in Container

          and not Contains (Container, Key (Container, Position)'Old)
          and not P.Has_Key (Positions (Container), Position'Old)

          --  Other mappings are preserved

          and M.Elements_Equal (Model (Container), Model (Container)'Old)
          and
            M.Keys_Included_Except
              (Model (Container)'Old,
               Model (Container),
               Key (Container, Position)'Old)

          --  The keys of Container located before Position are preserved.

          and
            K.Range_Equal
              (Left  => Keys (Container)'Old,
               Right => Keys (Container),
               Fst   => 1,
               Lst   => P.Get (Positions (Container)'Old, Position'Old) - 1)

          --  The keys located after Position are shifted by 1

          and
            K.Range_Shifted
              (Left   => Keys (Container),
               Right  => Keys (Container)'Old,
               Fst    => P.Get (Positions (Container)'Old, Position'Old),
               Lst    => Length (Container),
               Offset => 1)

          --  Position has been removed from Container

          and
            P_Positions_Shifted
              (Positions (Container),
               Positions (Container)'Old,
               Cut => P.Get (Positions (Container)'Old, Position'Old)));

   procedure Delete_First (Container : in out Map)
   with
     Global         => null,
     Contract_Cases =>
       (SPARKlib_Full =>
          (Length (Container) = 0 => Length (Container) = 0,
           others                 =>
             Length (Container) = Length (Container)'Old - 1

             --  The first key has been removed from Container

             and not Contains (Container, First_Key (Container)'Old)

             --  Other mappings are preserved

             and M.Elements_Equal (Model (Container), Model (Container)'Old)
             and
               M.Keys_Included_Except
                 (Model (Container)'Old,
                  Model (Container),
                  First_Key (Container)'Old)

             --  Other keys are shifted by 1

             and
               K.Range_Shifted
                 (Left   => Keys (Container),
                  Right  => Keys (Container)'Old,
                  Fst    => 1,
                  Lst    => Length (Container),
                  Offset => 1)

             --  First has been removed from Container

             and
               P_Positions_Shifted
                 (Positions (Container),
                  Positions (Container)'Old,
                  Cut => 1)));

   procedure Delete_Last (Container : in out Map)
   with
     Global         => null,
     Contract_Cases =>
       (SPARKlib_Full =>
          (Length (Container) = 0 => Length (Container) = 0,
           others                 =>
             Length (Container) = Length (Container)'Old - 1

             --  The last key has been removed from Container

             and not Contains (Container, Last_Key (Container)'Old)

             --  Other mappings are preserved

             and M.Elements_Equal (Model (Container), Model (Container)'Old)
             and
               M.Keys_Included_Except
                 (Model (Container)'Old,
                  Model (Container),
                  Last_Key (Container)'Old)

             --  Others keys of Container are preserved

             and
               K.Range_Equal
                 (Left  => Keys (Container)'Old,
                  Right => Keys (Container),
                  Fst   => 1,
                  Lst   => Length (Container))

             --  Last cursor has been removed from Container

             and
               P_Positions_Shifted
                 (Positions (Container),
                  Positions (Container)'Old,
                  Cut => Length (Container)'Old)));

   function First (Container : Map) return Cursor
   with
     Global         => null,
     Contract_Cases =>
       (SPARKlib_Full =>
          (Length (Container) = 0 => First'Result = No_Element,

           others                 =>
             Has_Element (Container, First'Result)
             and P.Get (Positions (Container), First'Result) = 1));

   function First_Element (Container : Map) return Element_Type
   with
     Global   => null,
     Pre      => (SPARKlib_Defensive => not Is_Empty (Container)),
     Post     =>
       (SPARKlib_Full =>
          First_Element'Result
          = Element (Model (Container), First_Key (Container))),
     Annotate => (GNATprove, Inline_For_Proof);

   function First_Key (Container : Map) return Key_Type
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => not Is_Empty (Container)),
     Post   =>
       (SPARKlib_Full =>
          K.Element_Logic_Equal (First_Key'Result, K.Get (Keys (Container), 1))
          and
            K_Smaller_Than_Range
              (Keys (Container), 2, Length (Container), First_Key'Result));

   function Last (Container : Map) return Cursor
   with
     Global         => null,
     Contract_Cases =>
       (SPARKlib_Full =>
          (Length (Container) = 0 => Last'Result = No_Element,

           others                 =>
             Has_Element (Container, Last'Result)
             and
               P.Get (Positions (Container), Last'Result)
               = Length (Container)));

   function Last_Element (Container : Map) return Element_Type
   with
     Global   => null,
     Pre      => (SPARKlib_Defensive => not Is_Empty (Container)),
     Post     =>
       (SPARKlib_Full =>
          Last_Element'Result
          = Element (Model (Container), Last_Key (Container))),
     Annotate => (GNATprove, Inline_For_Proof);

   function Last_Key (Container : Map) return Key_Type
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => not Is_Empty (Container)),
     Post   =>
       (SPARKlib_Full =>
          K.Element_Logic_Equal
            (Last_Key'Result, K.Get (Keys (Container), Length (Container)))
          and
            K_Bigger_Than_Range
              (Keys (Container), 1, Length (Container) - 1, Last_Key'Result));

   function Next (Container : Map; Position : Cursor) return Cursor
   with
     Global         => null,
     Pre            =>
       (SPARKlib_Defensive =>
          Has_Element (Container, Position) or else Position = No_Element),
     Contract_Cases =>
       (SPARKlib_Full =>
          (Position = No_Element
           or else P.Get (Positions (Container), Position) = Length (Container)
           => Next'Result = No_Element,

           others
           =>
             Has_Element (Container, Next'Result)
             and then
               P.Get (Positions (Container), Next'Result)
               = P.Get (Positions (Container), Position) + 1));

   procedure Next (Container : Map; Position : in out Cursor)
   with
     Global         => null,
     Pre            =>
       (SPARKlib_Defensive =>
          Has_Element (Container, Position) or else Position = No_Element),
     Contract_Cases =>
       (SPARKlib_Full =>
          (Position = No_Element
           or else P.Get (Positions (Container), Position) = Length (Container)
           => Position = No_Element,

           others
           =>
             Has_Element (Container, Position)
             and then
               P.Get (Positions (Container), Position)
               = P.Get (Positions (Container), Position'Old) + 1));

   function Previous (Container : Map; Position : Cursor) return Cursor
   with
     Global         => null,
     Pre            =>
       (SPARKlib_Defensive =>
          Has_Element (Container, Position) or else Position = No_Element),
     Contract_Cases =>
       (SPARKlib_Full =>
          (Position = No_Element
           or else P.Get (Positions (Container), Position) = 1 =>
             Previous'Result = No_Element,

           others                                              =>
             Has_Element (Container, Previous'Result)
             and then
               P.Get (Positions (Container), Previous'Result)
               = P.Get (Positions (Container), Position) - 1));

   procedure Previous (Container : Map; Position : in out Cursor)
   with
     Global         => null,
     Pre            =>
       (SPARKlib_Defensive =>
          Has_Element (Container, Position) or else Position = No_Element),
     Contract_Cases =>
       (SPARKlib_Full =>
          (Position = No_Element
           or else P.Get (Positions (Container), Position) = 1 =>
             Position = No_Element,

           others                                              =>
             Has_Element (Container, Position)
             and then
               P.Get (Positions (Container), Position)
               = P.Get (Positions (Container), Position'Old) - 1));

   function Find (Container : Map; Key : Key_Type) return Cursor
   with
     Global         => null,
     Contract_Cases =>
       (SPARKlib_Full =>

          --  If Key is not contained in Container, Find returns No_Element

          (not Contains (Model (Container), Key) =>
             not P.Has_Key (Positions (Container), Find'Result)
             and Find'Result = No_Element,

           --  Otherwise, Find returns a valid cursor in Container

           others                                =>
             P.Has_Key (Positions (Container), Find'Result)
             and
               P.Get (Positions (Container), Find'Result)
               = Find (Keys (Container), Key)

             --  The key designated by the result of Find is Key

             and
               Equivalent_Keys
                 (Ordered_Maps.Key (Container, Find'Result), Key)));

   function Element (Container : Map; Key : Key_Type) return Element_Type
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => Contains (Container, Key)),
     Post   =>
       (SPARKlib_Full => Element'Result = Element (Model (Container), Key));
   pragma Annotate (GNATprove, Inline_For_Proof, Entity => Element);

   function Floor (Container : Map; Key : Key_Type) return Cursor
   with
     Global         => null,
     Contract_Cases =>
       (SPARKlib_Full =>
          (Length (Container) = 0 or else Key < First_Key (Container) =>
             Floor'Result = No_Element,

           others                                                     =>
             Has_Element (Container, Floor'Result)
             and
               not (Key
                    < K.Get
                        (Keys (Container),
                         P.Get (Positions (Container), Floor'Result)))
             and
               K_Is_Find
                 (Keys (Container),
                  Key,
                  P.Get (Positions (Container), Floor'Result))));

   function Ceiling (Container : Map; Key : Key_Type) return Cursor
   with
     Global         => null,
     Contract_Cases =>
       (SPARKlib_Full =>
          (Length (Container) = 0 or else Last_Key (Container) < Key =>
             Ceiling'Result = No_Element,
           others                                                    =>
             Has_Element (Container, Ceiling'Result)
             and
               not (K.Get
                      (Keys (Container),
                       P.Get (Positions (Container), Ceiling'Result))
                    < Key)
             and
               K_Is_Find
                 (Keys (Container),
                  Key,
                  P.Get (Positions (Container), Ceiling'Result))));

   function Contains (Container : Map; Key : Key_Type) return Boolean
   with
     Global   => null,
     Post     =>
       (SPARKlib_Full => Contains'Result = Contains (Model (Container), Key)),
     Annotate => (GNATprove, Inline_For_Proof);

   function Has_Element (Container : Map; Position : Cursor) return Boolean
   with
     Global   => null,
     Post     =>
       (SPARKlib_Full =>
          Has_Element'Result = P.Has_Key (Positions (Container), Position)),
     Annotate => (GNATprove, Inline_For_Proof);

   ------------------------------------------------------------------
   -- Additional Expression Functions For Iteration and Aggregates --
   ------------------------------------------------------------------

   function Aggr_Capacity (Container : Map) return Count_Type
   is (Container.Capacity)
   with
     Ghost    => Static,
     Global   => null,
     Annotate => (GNATprove, Inline_For_Proof),
     Annotate => (GNATprove, Container_Aggregates, "Capacity");

   function Aggr_Model (Container : Map) return M.Map
   is (Model (Container))
   with
     Ghost    => Static,
     Global   => null,
     Annotate => (GNATprove, Inline_For_Proof),
     Annotate => (GNATprove, Container_Aggregates, "Model");

   function Iter_Model (Container : Map) return K.Sequence
   is (Keys (Container))
   with
     Ghost    => Static,
     Global   => null,
     Annotate => (GNATprove, Inline_For_Proof),
     Annotate => (GNATprove, Iterable_For_Proof, "Model");

private
   pragma SPARK_Mode (Off);

   pragma Inline (Next);
   pragma Inline (Previous);

   subtype Node_Access is Count_Type;

   use Red_Black_Trees;

   type Node_Type is record
      Has_Element : Boolean := False;
      Parent      : Node_Access := 0;
      Left        : Node_Access := 0;
      Right       : Node_Access := 0;
      Color       : Red_Black_Trees.Color_Type := Red;
      Key         : Key_Type;
      Element     : aliased Element_Type;
   end record;

   package Tree_Types is new
     Ada.Containers.Red_Black_Trees.Generic_Bounded_Tree_Types (Node_Type);

   type Map (Capacity : Count_Type) is record
      Content : Tree_Types.Tree_Type (Capacity);
   end record;

end SPARK.Containers.Formal.Ordered_Maps;
