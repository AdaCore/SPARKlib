--
--  Copyright (C) 2022-2025, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Iteration over maps is done using the Iterable aspect, which is SPARK
--  compatible. "For of" iteration ranges over keys instead of elements.

pragma Ada_2022;

with SPARK.Big_Integers;     use SPARK.Big_Integers;
with SPARK.Containers.Functional.Vectors;
with SPARK.Containers.Functional.Maps;
with SPARK.Containers.Parameter_Checks;
with SPARK.Containers.Types; use SPARK.Containers.Types;

private with SPARK.Containers.Formal.Holders;
private with SPARK.Containers.Formal.Hash_Tables;
private with Ada.Finalization;

generic
   type Key_Type (<>) is private;
   type Element_Type (<>) is private;

   with function Hash (Key : Key_Type) return Hash_Type;
   with function Equivalent_Keys
     (Left  : Key_Type;
      Right : Key_Type) return Boolean is "=";
   with function "=" (Left, Right : Element_Type) return Boolean is <>;

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

   --  Ghost lemma used to prove that Hash returns the same value for all
   --  equivalent keys.

   with procedure Hash_Equivalent (X, Y : Key_Type) is null
     with Ghost;

package SPARK.Containers.Formal.Unbounded_Hashed_Maps with
  SPARK_Mode,
  Always_Terminates
is
   --  Contracts in this unit are meant for analysis only, not for run-time
   --  checking.

   pragma Assertion_Policy (Ignore);
   pragma Annotate (CodePeer, Skip_Analysis);

   pragma Annotate (GNATcheck, Exempt_On,
                    "Restrictions:No_Specification_Of_Aspect => Iterable",
                    "The following usage of aspect Iterable has been reviewed"
                    & "for compliance with GNATprove assumption"
                    & " [SPARK_ITERABLE]");

   type Map is private with
     Iterable                  => (First       => First,
                                   Next        => Next,
                                   Has_Element => Has_Element,
                                   Element     => Key),
     Default_Initial_Condition => Is_Empty (Map),
     Aggregate                 => (Empty     => Empty_Map,
                                   Add_Named => Insert),
     Annotate                  =>
       (GNATprove, Container_Aggregates, "From_Model");
   pragma Annotate (GNATcheck, Exempt_Off,
                    "Restrictions:No_Specification_Of_Aspect => Iterable");

   function Empty_Map return Map with
     Global => null,
     Post   => Is_Empty (Empty_Map'Result);

   type Cursor is record
      Node : Count_Type;
   end record;

   No_Element : constant Cursor := (Node => 0);

   function Length (Container : Map) return Count_Type with
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

      package Eq_Keys_Checks is new
        SPARK.Containers.Parameter_Checks.Equivalence_Checks
          (T                   => Key_Type,
           Eq                  => Equivalent_Keys,
           Param_Eq_Reflexive  => Equivalent_Keys_Reflexive,
           Param_Eq_Symmetric  => Equivalent_Keys_Symmetric,
           Param_Eq_Transitive => Equivalent_Keys_Transitive);
      --  Check that the actual parameter for Equivalent_Keys is an equivalence
      --  relation.

      package Lift_Equivalent_Keys is new
        SPARK.Containers.Parameter_Checks.Lift_Eq_Reflexive
          (T                  => Key_Type,
           "="                => Equivalent_Keys,
           Eq                 => Equivalent_Keys,
           Param_Eq_Reflexive => Eq_Keys_Checks.Eq_Reflexive);

      package Hash_Checks is new
        SPARK.Containers.Parameter_Checks.Hash_Equivalence_Checks
          (T                     => Key_Type,
           "="                   => Equivalent_Keys,
           Hash                  => Hash,
           Param_Hash_Equivalent => Hash_Equivalent);
      --  Check that the actual parameter for Hash returns the same value for
      --  all equivalent keys.

      ------------------
      -- Formal Model --
      ------------------

      subtype Positive_Count_Type is Count_Type range 1 .. Count_Type'Last;

      package M is new SPARK.Containers.Functional.Maps
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
         Equivalent_Keys_Reflexive      => Eq_Keys_Checks.Eq_Reflexive,
         Equivalent_Keys_Symmetric      => Eq_Keys_Checks.Eq_Symmetric,
         Equivalent_Keys_Transitive     => Eq_Keys_Checks.Eq_Transitive);

      function Element_Logic_Equal
        (Left, Right : Element_Type) return Boolean
         renames M.Element_Logic_Equal;

      function "="
        (Left  : M.Map;
         Right : M.Map) return Boolean renames M."=";

      function "<="
        (Left  : M.Map;
         Right : M.Map) return Boolean renames M."<=";

      package K is new SPARK.Containers.Functional.Vectors
        (Element_Type                   => Key_Type,
         Index_Type                     => Positive_Count_Type,
         "="                            => Equivalent_Keys,
         Eq_Reflexive                   => Eq_Keys_Checks.Eq_Reflexive,
         Eq_Symmetric                   => Eq_Keys_Checks.Eq_Symmetric,
         Eq_Transitive                  => Eq_Keys_Checks.Eq_Transitive,
         Equivalent_Elements            => Equivalent_Keys,
         Equivalent_Elements_Reflexive  => Lift_Equivalent_Keys.Eq_Reflexive,
         Equivalent_Elements_Symmetric  => Eq_Keys_Checks.Eq_Symmetric,
         Equivalent_Elements_Transitive => Eq_Keys_Checks.Eq_Transitive);

      function Key_Logic_Equal
        (Left, Right : Key_Type) return Boolean
         renames K.Element_Logic_Equal;

      function "="
        (Left  : K.Sequence;
         Right : K.Sequence) return Boolean renames K."=";

      function "<"
        (Left  : K.Sequence;
         Right : K.Sequence) return Boolean renames K."<";

      function "<="
        (Left  : K.Sequence;
         Right : K.Sequence) return Boolean renames K."<=";

      function Find (Container : K.Sequence; Key : Key_Type) return Count_Type
      --  Search for Key in Container

      with
        Global => null,
        Post =>
          (if Find'Result > 0 then
              Find'Result <= K.Last (Container)
                and Equivalent_Keys (Key, K.Get (Container, Find'Result)));

      function K_Keys_Included
        (Left  : K.Sequence;
         Right : K.Sequence) return Boolean
      --  Return True if Right contains all the keys of Left

      with
        Global => null,
        Post   =>
          K_Keys_Included'Result =
            (for all I in 1 .. K.Last (Left) =>
              Find (Right, K.Get (Left, I)) > 0
                and then Key_Logic_Equal
                    (K.Get (Right, Find (Right, K.Get (Left, I))),
                     K.Get (Left, I)));

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

      function Mapping_Preserved
        (K_Left  : K.Sequence;
         K_Right : K.Sequence;
         P_Left  : P.Map;
         P_Right : P.Map) return Boolean
      with
        Global => null,
        Post   =>
          (if Mapping_Preserved'Result then

             --  Right contains all the cursors of Left

             P.Keys_Included (P_Left, P_Right)

               --  Right contains all the keys of Left

               and K_Keys_Included (K_Left, K_Right)

               --  Mappings from cursors to elements induced by K_Left, P_Left
               --  and K_Right, P_Right are the same.

               and (for all C of P_Left =>
                     Key_Logic_Equal
                         (K.Get (K_Left, P.Get (P_Left, C)),
                          K.Get (K_Right, P.Get (P_Right, C)))));

      function Model (Container : Map) return M.Map with
      --  The high-level model of a map is a map from keys to elements. Neither
      --  cursors nor order of elements are represented in this model. Keys are
      --  modeled up to equivalence.

        Ghost,
        Global => null,
        Post   => M.Length (Model'Result) = K.Big (Length (Container));

      function Keys (Container : Map) return K.Sequence with
      --  The Keys sequence represents the underlying list structure of maps
      --  that is used for iteration. It stores the actual values of keys in
      --  the map. It does not model cursors nor elements.

        Ghost,
        Global => null,
        Post   =>
          K.Last (Keys'Result) = Length (Container)

            --  It only contains keys contained in Model

            and (for all Key of Keys'Result =>
                  M.Has_Key (Model (Container), Key))

            --  It contains all the keys contained in Model

            and (for all Key of Model (Container) =>
                  (Find (Keys'Result, Key) > 0
                    and then Equivalent_Keys
                               (K.Get (Keys'Result, Find (Keys'Result, Key)),
                                Key)))

            --  It has no duplicate

            and (for all I in 1 .. Length (Container) =>
                  Find (Keys'Result, K.Get (Keys'Result, I)) = I)

            and (for all I in 1 .. Length (Container) =>
                  (for all J in 1 .. Length (Container) =>
                    (if Equivalent_Keys
                          (K.Get (Keys'Result, I), K.Get (Keys'Result, J))
                     then
                        I = J)));

      function Positions (Container : Map) return P.Map with
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

      procedure Lift_Abstraction_Level (Container : Map) with
        --  Lift_Abstraction_Level is a ghost procedure that does nothing but
        --  assume that we can access the same elements by iterating over
        --  positions or cursors.
        --  This information is not generally useful except when switching from
        --  a low-level, cursor-aware view of a container, to a high-level,
        --  position-based view.

        Ghost,
        Global => null,
        Post   =>
          (for all Key of Keys (Container) =>
            (for some I of Positions (Container) =>
              Key_Logic_Equal
                (K.Get (Keys (Container), P.Get (Positions (Container), I)),
                 Key)));

      function Contains
        (C : M.Map;
         K : Key_Type) return Boolean renames M.Has_Key;
      --  To improve readability of contracts, we rename the function used to
      --  search for a key in the model to Contains.

      function Element
        (C : M.Map;
         K : Key_Type) return Element_Type renames M.Get;
      --  To improve readability of contracts, we rename the function used to
      --  access an element in the model to Element.

   end Formal_Model;
   use Formal_Model;

   function "=" (Left, Right : Map) return Boolean with
     Global => null,
     Post   => "="'Result = (M.Equivalent_Maps (Model (Left), Model (Right)));

   function Is_Empty (Container : Map) return Boolean with
     Global => null,
     Post   =>
       Is_Empty'Result = M.Is_Empty (Model (Container))
         and Is_Empty'Result = (Length (Container) = 0);

   procedure Clear (Container : in out Map) with
     Global => null,
     Post   => Length (Container) = 0 and M.Is_Empty (Model (Container));

   procedure Assign (Target : in out Map; Source : Map) with
     Global => null,
     Post   =>
       M.Equal (Model (Target), Model (Source))
         and Length (Source) = Length (Target)

         --  Actual keys are preserved

         and K_Keys_Included (Keys (Target), Keys (Source))
         and K_Keys_Included (Keys (Source), Keys (Target));

   function Copy
     (Source : Map) return Map
   with
     Global => null,
     Post   =>
       M.Equal (Model (Copy'Result), Model (Source))
         and K.Equal (Keys (Copy'Result), Keys (Source))
         and Positions (Copy'Result) = Positions (Source);
   --  Copy returns a container stricty equal to Source. It must have the same
   --  cursors associated with each element.

   function Key (Container : Map; Position : Cursor) return Key_Type with
     Global   => null,
     Pre      => Has_Element (Container, Position),
     Post     =>
       Key'Result =
         K.Get (Keys (Container), P.Get (Positions (Container), Position)),
     Annotate => (GNATprove, Inline_For_Proof);

   function Element
     (Container : Map;
      Position  : Cursor) return Element_Type
   with
     Global   => null,
     Pre      => Has_Element (Container, Position),
     Post     =>
       Element'Result = Element (Model (Container), Key (Container, Position)),
     Annotate => (GNATprove, Inline_For_Proof);

   procedure Replace_Element
     (Container : in out Map;
      Position  : Cursor;
      New_Item  : Element_Type)
   with
     Global => null,
     Pre    => Has_Element (Container, Position),
     Post   =>

       --  Order of keys and cursors is preserved

       K.Equal (Keys (Container), Keys (Container)'Old)
         and Positions (Container) = Positions (Container)'Old

         --  New_Item is now associated with the key at position Position in
         --  Container.

         and Element_Logic_Equal
               (Element (Container, Position), M.Copy_Element (New_Item))

         --  Elements associated with other keys are preserved

         and M.Same_Keys (Model (Container), Model (Container)'Old)
         and M.Elements_Equal_Except
               (Model (Container),
                Model (Container)'Old,
                Key (Container, Position));

   function At_End (E : Map) return Map is (E)
   with Ghost,
     Annotate => (GNATprove, At_End_Borrow);

   function At_End
     (E : access constant Element_Type) return access constant Element_Type
   is (E)
   with Ghost,
     Annotate => (GNATprove, At_End_Borrow);

   function Constant_Reference
     (Container : Map;
      Position  : Cursor) return not null access constant Element_Type
   with
     Global => null,
     Pre    => Has_Element (Container, Position),
     Post   =>
       Element_Logic_Equal
          (Constant_Reference'Result.all,
           Element (Model (Container), Key (Container, Position)));

   function Reference
     (Container : Map;
      Position  : Cursor) return not null access Element_Type
   with
     Global => null,
     Pre    => Has_Element (Container, Position),
     Post   =>

       --  Order of keys and cursors is preserved

       K.Equal (Keys (At_End (Container)), Keys (Container))
         and Positions (At_End (Container)) = Positions (Container)

         --  The value designated by the result of Reference is now associated
         --  with the key at position Position in Container.

         and Element_Logic_Equal
               (Element (At_End (Container), Position),
                At_End (Reference'Result).all)

         --  Elements associated with other keys are preserved

         and M.Same_Keys
               (Model (At_End (Container)),
                Model (Container))
         and M.Elements_Equal_Except
               (Model (At_End (Container)),
                Model (Container),
                Key (At_End (Container), Position));

   function Constant_Reference
     (Container : Map;
      Key       : Key_Type) return not null access constant Element_Type
   with
     Global => null,
     Pre    => Contains (Container, Key),
     Post   =>
       Element_Logic_Equal
          (Constant_Reference'Result.all, Element (Model (Container), Key));

   function Reference
     (Container : Map;
      Key       : Key_Type) return not null access Element_Type
   with
     Global => null,
     Pre    => Contains (Container, Key),
     Post   =>

       --  Order of keys and cursors is preserved

       K.Equal (Keys (At_End (Container)), Keys (Container))
         and Positions (At_End (Container)) = Positions (Container)

         --  The value designated by the result of Reference is now associated
         --  with Key in Container.

         and Element_Logic_Equal
               (Element (Model (At_End (Container)), Key),
                At_End (Reference'Result).all)

         --  Elements associated with other keys are preserved

         and M.Same_Keys
               (Model (At_End (Container)),
                Model (Container))
         and M.Elements_Equal_Except
               (Model (At_End (Container)),
                Model (Container),
                Key);

   procedure Move (Target : in out Map; Source : in out Map) with
     Global => null,
     Post   =>
       M.Equal (Model (Target), Model (Source)'Old)
         and Length (Source)'Old = Length (Target)
         and Length (Source) = 0

         --  Actual keys are preserved

         and K_Keys_Included (Keys (Target), Keys (Source)'Old)
         and K_Keys_Included (Keys (Source)'Old, Keys (Target));

   procedure Insert
     (Container : in out Map;
      Key       : Key_Type;
      New_Item  : Element_Type;
      Position  : out Cursor;
      Inserted  : out Boolean)
   with
     Global         => null,
     Pre            =>
       Length (Container) < Count_Type'Last or Contains (Container, Key),
     Post           =>
       Contains (Container, Key)
         and Has_Element (Container, Position)
         and Equivalent_Keys
               (Unbounded_Hashed_Maps.Key
                  (Container, Position), Key),
     Contract_Cases =>

       --  If Key is already in Container, it is not modified and Inserted is
       --  set to False.

       (Contains (Container, Key) =>
          not Inserted
            and M.Equal (Model (Container), Model (Container)'Old)
            and K.Equal (Keys (Container), Keys (Container)'Old)
            and Positions (Container) = Positions (Container)'Old,

        --  Otherwise, Key is inserted in Container and Inserted is set to True

        others =>
          Inserted
            and Length (Container) = Length (Container)'Old + 1

            --  Key now maps to New_Item

            and Key_Logic_Equal
                  (Unbounded_Hashed_Maps.Key (Container, Position),
                   K.Copy_Element (Key))
            and Element_Logic_Equal
                  (Element (Model (Container), Key), M.Copy_Element (New_Item))

            --  Other keys are preserved

            and M.Elements_Equal (Model (Container)'Old, Model (Container))
            and M.Keys_Included_Except
                  (Model (Container),
                   Model (Container)'Old,
                   Key)

            --  Mapping from cursors to keys is preserved

            and Mapping_Preserved
                  (K_Left  => Keys (Container)'Old,
                   K_Right => Keys (Container),
                   P_Left  => Positions (Container)'Old,
                   P_Right => Positions (Container))
            and P.Keys_Included_Except
                  (Positions (Container),
                   Positions (Container)'Old,
                   Position));

   procedure Insert
     (Container : in out Map;
      Key       : Key_Type;
      New_Item  : Element_Type)
   with
     Global => null,
     Pre    =>
       Length (Container) < Count_Type'Last
        and then not Contains (Container, Key),
     Post   =>
       Length (Container) = Length (Container)'Old + 1
         and Contains (Container, Key)

         --  Key now maps to New_Item

         and Key_Logic_Equal
               (Unbounded_Hashed_Maps.Key (Container, Find (Container, Key)),
                K.Copy_Element (Key))
         and Element_Logic_Equal
               (Element (Model (Container), Key), M.Copy_Element (New_Item))

         --  Other keys are preserved

         and M.Elements_Equal (Model (Container)'Old, Model (Container))
         and M.Keys_Included_Except
               (Model (Container),
                Model (Container)'Old,
                Key)

         --  Mapping from cursors to keys is preserved

         and Mapping_Preserved
               (K_Left  => Keys (Container)'Old,
                K_Right => Keys (Container),
                P_Left  => Positions (Container)'Old,
                P_Right => Positions (Container))
         and P.Keys_Included_Except
               (Positions (Container),
                Positions (Container)'Old,
                Find (Container, Key));

   procedure Include
     (Container : in out Map;
      Key       : Key_Type;
      New_Item  : Element_Type)
   with
     Global         => null,
     Pre            =>
       Length (Container) < Count_Type'Last or Contains (Container, Key),
     Post           =>
       Contains (Container, Key)
         and Element_Logic_Equal
           (Element (Container, Key), M.Copy_Element (New_Item)),
     Contract_Cases =>

       --  If Key is already in Container, Key is mapped to New_Item

       (Contains (Container, Key) =>

          --  Cursors are preserved

          Positions (Container) = Positions (Container)'Old

            --  The key equivalent to Key in Container is replaced by Key

            and Key_Logic_Equal
                  (K.Get
                     (Keys (Container),
                      P.Get (Positions (Container), Find (Container, Key))),
                   K.Copy_Element (Key))
            and K.Equal_Except
                  (Keys (Container)'Old,
                   Keys (Container),
                   P.Get (Positions (Container), Find (Container, Key)))

            --  Elements associated with other keys are preserved

            and M.Same_Keys (Model (Container), Model (Container)'Old)
            and M.Elements_Equal_Except
                  (Model (Container),
                   Model (Container)'Old,
                   Key),

        --  Otherwise, Key is inserted in Container

        others =>
          Length (Container) = Length (Container)'Old + 1

            --  Other keys are preserved

            and M.Elements_Equal (Model (Container)'Old, Model (Container))
            and M.Keys_Included_Except
                  (Model (Container),
                   Model (Container)'Old,
                   Key)

            --  Key is inserted in Container

            and Key_Logic_Equal
                  (K.Get
                     (Keys (Container),
                      P.Get (Positions (Container), Find (Container, Key))),
                   K.Copy_Element (Key))

            --  Mapping from cursors to keys is preserved

            and Mapping_Preserved
                  (K_Left  => Keys (Container)'Old,
                   K_Right => Keys (Container),
                   P_Left  => Positions (Container)'Old,
                   P_Right => Positions (Container))
            and P.Keys_Included_Except
                  (Positions (Container),
                   Positions (Container)'Old,
                   Find (Container, Key)));

   procedure Replace
     (Container : in out Map;
      Key       : Key_Type;
      New_Item  : Element_Type)
   with
     Global => null,
     Pre    => Contains (Container, Key),
     Post   =>

       --  Cursors are preserved

       Positions (Container) = Positions (Container)'Old

         --  The key equivalent to Key in Container is replaced by Key

         and Key_Logic_Equal
               (K.Get
                  (Keys (Container),
                   P.Get (Positions (Container), Find (Container, Key))),
                K.Copy_Element (Key))
         and K.Equal_Except
               (Keys (Container)'Old,
                Keys (Container),
                P.Get (Positions (Container), Find (Container, Key)))

         --  New_Item is now associated with the Key in Container

         and Element_Logic_Equal
               (Element (Model (Container), Key), M.Copy_Element (New_Item))

         --  Elements associated with other keys are preserved

         and M.Same_Keys (Model (Container), Model (Container)'Old)
         and M.Elements_Equal_Except
               (Model (Container),
                Model (Container)'Old,
                Key);

   procedure Exclude (Container : in out Map; Key : Key_Type) with
     Global         => null,
     Post           => not Contains (Container, Key),
     Contract_Cases =>

       --  If Key is not in Container, nothing is changed

       (not Contains (Container, Key) =>
          M.Equal (Model (Container), Model (Container)'Old)
            and K.Equal (Keys (Container), Keys (Container)'Old)
            and Positions (Container) = Positions (Container)'Old,

        --  Otherwise, Key is removed from Container

        others =>
          Length (Container) = Length (Container)'Old - 1

            --  Other keys are preserved

            and M.Elements_Equal (Model (Container), Model (Container)'Old)
            and M.Keys_Included_Except
                  (Model (Container)'Old,
                   Model (Container),
                   Key)

            --  Mapping from cursors to keys is preserved

            and Mapping_Preserved
                  (K_Left  => Keys (Container),
                   K_Right => Keys (Container)'Old,
                   P_Left  => Positions (Container),
                   P_Right => Positions (Container)'Old)
            and P.Keys_Included_Except
                  (Positions (Container)'Old,
                   Positions (Container),
                   Find (Container, Key)'Old));

   procedure Delete (Container : in out Map; Key : Key_Type) with
     Global => null,
     Pre    => Contains (Container, Key),
     Post   =>
       Length (Container) = Length (Container)'Old - 1

         --  Key is no longer in Container

         and not Contains (Container, Key)

         --  Other keys are preserved

         and M.Elements_Equal (Model (Container), Model (Container)'Old)
         and M.Keys_Included_Except
               (Model (Container)'Old,
                Model (Container),
                Key)

         --  Mapping from cursors to keys is preserved

         and Mapping_Preserved
               (K_Left  => Keys (Container),
                K_Right => Keys (Container)'Old,
                P_Left  => Positions (Container),
                P_Right => Positions (Container)'Old)
         and P.Keys_Included_Except
               (Positions (Container)'Old,
                Positions (Container),
                Find (Container, Key)'Old);

   procedure Delete (Container : in out Map; Position : in out Cursor) with
     Global  => null,
     Depends => (Container =>+ Position, Position => null),
     Pre     => Has_Element (Container, Position),
     Post    =>
       Position = No_Element
         and Length (Container) = Length (Container)'Old - 1

         --  The key at position Position is no longer in Container

         and not Contains (Container, Key (Container, Position)'Old)
         and not P.Has_Key (Positions (Container), Position'Old)

         --  Other keys are preserved

         and M.Elements_Equal (Model (Container), Model (Container)'Old)
         and M.Keys_Included_Except
               (Model (Container)'Old,
                Model (Container),
                Key (Container, Position)'Old)

         --  Mapping from cursors to keys is preserved

         and Mapping_Preserved
               (K_Left  => Keys (Container),
                K_Right => Keys (Container)'Old,
                P_Left  => Positions (Container),
                P_Right => Positions (Container)'Old)
         and P.Keys_Included_Except
               (Positions (Container)'Old,
                Positions (Container),
                Position'Old);

   function First (Container : Map) return Cursor with
     Global         => null,
     Contract_Cases =>
       (Length (Container) = 0 =>
          First'Result = No_Element,

        others =>
          Has_Element (Container, First'Result)
            and P.Get (Positions (Container), First'Result) = 1);

   function Next (Container : Map; Position : Cursor) return Cursor with
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

   procedure Next (Container : Map; Position : in out Cursor) with
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

   function Find (Container : Map; Key : Key_Type) return Cursor with
     Global         => null,
     Contract_Cases =>

       --  If Key is not contained in Container, Find returns No_Element

       (not Contains (Model (Container), Key) =>
          Find'Result = No_Element,

        --  Otherwise, Find returns a valid cursor in Container

        others =>
          P.Has_Key (Positions (Container), Find'Result)
            and P.Get (Positions (Container), Find'Result) =
                Find (Keys (Container), Key)

            --  The key designated by the result of Find is Key

            and Equivalent_Keys
                  (Unbounded_Hashed_Maps.Key
                     (Container, Find'Result), Key));

   function Contains (Container : Map; Key : Key_Type) return Boolean with
     Global   => null,
     Post     => Contains'Result = Contains (Model (Container), Key),
     Annotate => (GNATprove, Inline_For_Proof);

   function Element (Container : Map; Key : Key_Type) return Element_Type with
     Global   => null,
     Pre      => Contains (Container, Key),
     Post     => Element'Result = Element (Model (Container), Key),
     Annotate => (GNATprove, Inline_For_Proof);

   function Has_Element (Container : Map; Position : Cursor) return Boolean
   with
     Global   => null,
     Post     =>
       Has_Element'Result = P.Has_Key (Positions (Container), Position),
     Annotate => (GNATprove, Inline_For_Proof);

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

   function Aggr_Model (Container : Map) return M.Map is
      (Model (Container))
   with
     Ghost,
     Global   => null,
     Annotate => (GNATprove, Inline_For_Proof),
     Annotate => (GNATprove, Container_Aggregates, "Model");

   function Iter_Model (Container : Map) return K.Sequence is
      (Keys (Container))
   with
     Ghost,
     Global   => null,
     Annotate => (GNATprove, Inline_For_Proof),
     Annotate => (GNATprove, Iterable_For_Proof, "Model");

private
   pragma SPARK_Mode (Off);

   pragma Inline (Length);
   pragma Inline (Is_Empty);
   pragma Inline (Clear);
   pragma Inline (Key);
   pragma Inline (Element);
   pragma Inline (Contains);
   pragma Inline (Has_Element);
   pragma Inline (Equivalent_Keys);
   pragma Inline (Next);

   --  Define the Holder

   package Element_Holder_Types is new Holders (Element_Type);
   package EHT renames Element_Holder_Types;

   package Key_Holder_Types is new Holders (Key_Type);
   package KHT renames Key_Holder_Types;

   --  Defines the Hashed Map

   type Node_Type is record
      K_Holder    : KHT.Holder_Type;
      E_Holder    : EHT.Holder_Type;
      Next        : Count_Type;
      Has_Element : Boolean := False;
   end record;

   package HT_Types is new
     SPARK.Containers.Formal.Hash_Tables.Generic_Hash_Table_Types (Node_Type);

   type HT_Access is access all HT_Types.Hash_Table_Type;

   Empty_HT : aliased HT_Types.Hash_Table_Type (0, 0);

   type Map is new Ada.Finalization.Controlled
   with record
     Content : not null HT_Access := Empty_HT'Access;
   end record;

   overriding procedure Adjust (Container : in out Map);
   --  Makes a copy of Container in order to avoid sharing

   overriding procedure Finalize (Container : in out Map);
   --  Finalize the elment held by Container if necessary

end SPARK.Containers.Formal.Unbounded_Hashed_Maps;
