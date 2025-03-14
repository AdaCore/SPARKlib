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

private with SPARK.Containers.Formal.Hash_Tables;
private with Ada.Finalization;
private with SPARK.Containers.Formal.Holders;

generic
   type Element_Type (<>) is private;

   with function Hash (Element : Element_Type) return Hash_Type;

   with function Equivalent_Elements
     (Left  : Element_Type;
      Right : Element_Type) return Boolean is "=";

   with function "=" (Left, Right : Element_Type) return Boolean is <>;

   --  Ghost lemmas used to prove that "=" is an equivalence relation

   with procedure Eq_Reflexive (X : Element_Type) is null
     with Ghost;
   with procedure Eq_Symmetric (X, Y : Element_Type) is null
     with Ghost;
   with procedure Eq_Transitive (X, Y, Z : Element_Type) is null
     with Ghost;

   --  Ghost lemmas used to prove that Equivalent_Elements is an equivalence
   --  relation with respect to "=".

   with procedure Equivalent_Elements_Reflexive (X, Y : Element_Type) is null
     with Ghost;
   with procedure Equivalent_Elements_Symmetric (X, Y : Element_Type) is null
     with Ghost;
   with procedure Equivalent_Elements_Transitive
     (X, Y, Z : Element_Type) is null
     with Ghost;

   --  Ghost lemma used to prove that Hash returns the same value for all
   --  equivalent elements.

   with procedure Hash_Equivalent (X, Y : Element_Type) is null
     with Ghost;

package SPARK.Containers.Formal.Unbounded_Hashed_Sets with
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
      --  equivalence relation and that it is compatible with "=".

      package Hash_Checks is new
        SPARK.Containers.Parameter_Checks.Hash_Equivalence_Checks
          (T                     => Element_Type,
           "="                   => Equivalent_Elements,
           Hash                  => Hash,
           Param_Hash_Equivalent => Hash_Equivalent);
      --  Check that the actual parameter for Hash returns the same value for
      --  all equivalent elements.

      ------------------
      -- Formal Model --
      ------------------

      subtype Positive_Count_Type is Count_Type range 1 .. Count_Type'Last;

      package M is new SPARK.Containers.Functional.Sets
        (Element_Type                   => Element_Type,
         Equivalent_Elements            => Equivalent_Elements,
         Equivalent_Elements_Reflexive  => Eq_Elements_Checks.Eq_Reflexive,
         Equivalent_Elements_Symmetric  => Eq_Elements_Checks.Eq_Symmetric,
         Equivalent_Elements_Transitive => Eq_Elements_Checks.Eq_Transitive);

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

      function Find
        (Container : E.Sequence;
         Item      : Element_Type) return Count_Type
      --  Search for Item in Container

      with
        Global => null,
        Post =>
          (if Find'Result > 0 then
              Find'Result <= E.Last (Container)
                and Equivalent_Elements
                      (Item, E.Get (Container, Find'Result)));

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
                               (E.Get (Elements'Result,
                                       Find (Elements'Result, Item)),
                                Item)))

            --  It has no duplicate

            and (for all I in 1 .. Length (Container) =>
                  Find (Elements'Result, E.Get (Elements'Result, I)) = I)

            and (for all I in 1 .. Length (Container) =>
                  (for all J in 1 .. Length (Container) =>
                    (if Equivalent_Elements
                          (E.Get (Elements'Result, I),
                           E.Get (Elements'Result, J))
                     then I = J)));

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
                 (E.Get (Elements (Container),
                         P.Get (Positions (Container), I)),
                  Item)));

      function Contains
        (C : M.Set;
         K : Element_Type) return Boolean renames M.Contains;
      --  To improve readability of contracts, we rename the function used to
      --  search for an element in the model to Contains.

   end Formal_Model;
   use Formal_Model;

   function Empty_Set return Set with
     Global => null,
     Post   => Is_Empty (Empty_Set'Result);

   function "=" (Left, Right : Set) return Boolean with
     Global => null,
     Post   =>
         "="'Result =
           (Length (Left) = Length (Right)
             and E_Elements_Equal (Elements (Left), Elements (Right)))
       and
         "="'Result =
           (E_Elements_Equal (Elements (Left), Elements (Right))
             and E_Elements_Equal (Elements (Right), Elements (Left)));
   --  For each element in Left, set equality attempts to find the equal
   --  element in Right; if a search fails, then set equality immediately
   --  returns False. The search works by calling Hash to find the bucket in
   --  the Right set that corresponds to the Left element. If the bucket is
   --  non-empty, the search calls the generic formal element equality operator
   --  to compare the element (in Left) to the element of each node in the
   --  bucket (in Right); the search terminates when a matching node in the
   --  bucket is found, or the nodes in the bucket are exhausted. (Note that
   --  element equality is called here, not Equivalent_Elements. Set equality
   --  is the only operation in which element equality is used. Compare set
   --  equality to Equivalent_Sets, which does call Equivalent_Elements.)

   function Equivalent_Sets (Left, Right : Set) return Boolean with
     Global => null,
     Post   => Equivalent_Sets'Result = (Model (Left) = Model (Right));
   --  Similar to set equality, with the difference that the element in Left is
   --  compared to the elements in Right using the generic formal
   --  Equivalent_Elements operation instead of element equality.

   function To_Set (New_Item : Element_Type) return Set with
     Global => null,
     Post   =>
       M.Is_Singleton (Model (To_Set'Result), New_Item)
         and Length (To_Set'Result) = 1
         and Element_Logic_Equal
               (E.Get (Elements (To_Set'Result), 1),
                E.Copy_Element (New_Item));
   --  Constructs a singleton set comprising New_Element. To_Set calls Hash to
   --  determine the bucket for New_Item.

   function Is_Empty (Container : Set) return Boolean with
     Global => null,
     Post   =>
       Is_Empty'Result = M.Is_Empty (Model (Container))
         and Is_Empty'Result = (Length (Container) = 0);

   procedure Clear (Container : in out Set) with
     Global => null,
     Post   => Length (Container) = 0 and M.Is_Empty (Model (Container));
   --  Removes all of the items from the set. This will deallocate all memory
   --  associated with this set.

   procedure Assign (Target : in out Set; Source : Set) with
     Global => null,
     Post   =>
       Model (Target) = Model (Source)
         and Length (Target) = Length (Source)

         --  Actual elements are preserved

         and E_Elements_Included (Elements (Target), Elements (Source))
         and E_Elements_Included (Elements (Source), Elements (Target));
   --  If Target denotes the same object as Source, then the operation has no
   --  effect. If the Target capacity is less than the Source length, then
   --  Assign raises Capacity_Error.  Otherwise, Assign clears Target and then
   --  copies the (active) elements from Source to Target.

   function Copy (Source : Set) return Set
   with
     Global => null,
     Post   =>
       Model (Copy'Result) = Model (Source)
         and E.Equal (Elements (Copy'Result), Elements (Source))
         and Positions (Copy'Result) = Positions (Source);
   --  Constructs a new set object whose elements correspond to Source

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
                (Element (Container, Position),
                 E.Copy_Element (New_Item))

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
                 Position => Position);

   function Constant_Reference
     (Container : Set;
      Position  : Cursor) return not null access constant Element_Type
   with
     Global => null,
     Pre    => Has_Element (Container, Position),
     Post   =>
       Element_Logic_Equal
         (Constant_Reference'Result.all,
          E.Get (Elements (Container),
                 P.Get (Positions (Container), Position)));

   procedure Move (Target : in out Set; Source : in out Set) with
     Global => null,
     Post   =>
       Length (Source) = 0
         and Model (Target) = Model (Source)'Old
         and Length (Target) = Length (Source)'Old

         --  Actual elements are preserved

         and E_Elements_Included (Elements (Target), Elements (Source)'Old)
         and E_Elements_Included (Elements (Source)'Old, Elements (Target));
   --  Clears Target (if it's not empty), and then moves (not copies) the
   --  buckets array and nodes from Source to Target.

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
         and Equivalent_Elements (Element (Container, Position), New_Item),
     Contract_Cases =>

       --  If New_Item is already in Container, it is not modified and Inserted
       --  is set to False.

       (Contains (Container, New_Item) =>
          not Inserted
            and Model (Container) = Model (Container)'Old
            and E.Equal (Elements (Container), Elements (Container)'Old)
            and Positions (Container) = Positions (Container)'Old,

        --  Otherwise, New_Item is inserted in Container and Inserted is set to
        --  True.

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

            --  Mapping from cursors to elements is preserved

            and Mapping_Preserved
                  (E_Left  => Elements (Container)'Old,
                   E_Right => Elements (Container),
                   P_Left  => Positions (Container)'Old,
                   P_Right => Positions (Container))
            and P.Keys_Included_Except
                  (Positions (Container),
                   Positions (Container)'Old,
                   Position));
   --  Conditionally inserts New_Item into the set. If New_Item is already in
   --  the set, then Inserted returns False and Position designates the node
   --  containing the existing element (which is not modified). If New_Item is
   --  not already in the set, then Inserted returns True and Position
   --  designates the newly-inserted node containing New_Item. The search for
   --  an existing element works as follows. Hash is called to determine
   --  New_Item's bucket; if the bucket is non-empty, then Equivalent_Elements
   --  is called to compare New_Item to the element of each node in that
   --  bucket. If the bucket is empty, or there were no equivalent elements in
   --  the bucket, the search "fails" and the New_Item is inserted in the set
   --  (and Inserted returns True); otherwise, the search "succeeds" (and
   --  Inserted returns False).

   procedure Insert  (Container : in out Set; New_Item : Element_Type) with
     Global => null,
     Pre    => Length (Container) < Count_Type'Last
                 and then not Contains (Container, New_Item),
     Post   =>
       Length (Container) = Length (Container)'Old + 1
         and Contains (Container, New_Item)
         and Element_Logic_Equal
               (Element (Container, Find (Container, New_Item)),
                E.Copy_Element (New_Item))

         --  Other elements are preserved

         and Model (Container)'Old <= Model (Container)
         and M.Included_Except
               (Model (Container),
                Model (Container)'Old,
                New_Item)

         --  Mapping from cursors to elements is preserved

         and Mapping_Preserved
               (E_Left  => Elements (Container)'Old,
                E_Right => Elements (Container),
                P_Left  => Positions (Container)'Old,
                P_Right => Positions (Container))
         and P.Keys_Included_Except
               (Positions (Container),
                Positions (Container)'Old,
                Find (Container, New_Item));
   --  Attempts to insert New_Item into the set, performing the usual insertion
   --  search (which involves calling both Hash and Equivalent_Elements); if
   --  the search succeeds (New_Item is equivalent to an element already in the
   --  set, and so was not inserted), then this operation raises
   --  Constraint_Error. (This version of Insert is similar to Replace, but
   --  having the opposite exception behavior. It is intended for use when you
   --  want to assert that the item is not already in the set.)

   procedure Include (Container : in out Set; New_Item : Element_Type) with
     Global         => null,
     Pre            =>
       Length (Container) < Count_Type'Last
         or Contains (Container, New_Item),
     Post           =>
       Contains (Container, New_Item)
         and Element_Logic_Equal
               (Element (Container, Find (Container, New_Item)),
                E.Copy_Element (New_Item)),
     Contract_Cases =>

       --  If an element equivalent to New_Item is already in Container, it is
       --  replaced by New_Item.

       (Contains (Container, New_Item) =>

          --  Elements are preserved modulo equivalence

          Model (Container) = Model (Container)'Old

            --  Cursors are preserved

            and Positions (Container) = Positions (Container)'Old

            --  The actual value of other elements is preserved

            and E.Equal_Except
                  (Elements (Container)'Old,
                   Elements (Container),
                   P.Get (Positions (Container), Find (Container, New_Item))),

        --  Otherwise, New_Item is inserted in Container

        others =>
          Length (Container) = Length (Container)'Old + 1

            --  Other elements are preserved

            and Model (Container)'Old <= Model (Container)
            and M.Included_Except
                  (Model (Container),
                   Model (Container)'Old,
                   New_Item)

            --  Mapping from cursors to elements is preserved

            and Mapping_Preserved
                  (E_Left  => Elements (Container)'Old,
                   E_Right => Elements (Container),
                   P_Left  => Positions (Container)'Old,
                   P_Right => Positions (Container))
            and P.Keys_Included_Except
                  (Positions (Container),
                   Positions (Container)'Old,
                   Find (Container, New_Item)));
   --  Attempts to insert New_Item into the set. If an element equivalent to
   --  New_Item is already in the set (the insertion search succeeded, and
   --  hence New_Item was not inserted), then the value of New_Item is assigned
   --  to the existing element. (This insertion operation only raises an
   --  exception if cursor tampering occurs. It is intended for use when you
   --  want to insert the item in the set, and you don't care whether an
   --  equivalent element is already present.)

   procedure Replace (Container : in out Set; New_Item : Element_Type) with
     Global => null,
     Pre    => Contains (Container, New_Item),
     Post   =>

       --  Elements are preserved modulo equivalence

       Model (Container) = Model (Container)'Old
         and Contains (Container, New_Item)

         --  Cursors are preserved

         and Positions (Container) = Positions (Container)'Old

         --  The element equivalent to New_Item in Container is replaced by
         --  New_Item.

         and Element_Logic_Equal
               (Element (Container, Find (Container, New_Item)),
                E.Copy_Element (New_Item))
         and E.Equal_Except
               (Elements (Container)'Old,
                Elements (Container),
                P.Get (Positions (Container), Find (Container, New_Item)));
   --  Searches for New_Item in the set; if the search fails (because an
   --  equivalent element was not in the set), then it raises
   --  Constraint_Error. Otherwise, the existing element is assigned the value
   --  New_Item. (This is similar to Insert, but with the opposite exception
   --  behavior. It is intended for use when you want to assert that the item
   --  is already in the set.)

   procedure Exclude (Container : in out Set; Item : Element_Type) with
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

            --  Mapping from cursors to elements is preserved

            and Mapping_Preserved
                  (E_Left  => Elements (Container),
                   E_Right => Elements (Container)'Old,
                   P_Left  => Positions (Container),
                   P_Right => Positions (Container)'Old)
            and P.Keys_Included_Except
                  (Positions (Container)'Old,
                   Positions (Container),
                   Find (Container, Item)'Old));
   --  Searches for Item in the set, and if found, removes its node from the
   --  set and then deallocates it. The search works as follows. The operation
   --  calls Hash to determine the item's bucket; if the bucket is not empty,
   --  it calls Equivalent_Elements to compare Item to the element of each node
   --  in the bucket. (This is the deletion analog of Include. It is intended
   --  for use when you want to remove the item from the set, but don't care
   --  whether the item is already in the set.)

   procedure Delete  (Container : in out Set; Item : Element_Type) with
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

         --  Mapping from cursors to elements is preserved

         and Mapping_Preserved
               (E_Left  => Elements (Container),
                E_Right => Elements (Container)'Old,
                P_Left  => Positions (Container),
                P_Right => Positions (Container)'Old)
         and P.Keys_Included_Except
               (Positions (Container)'Old,
                Positions (Container),
                Find (Container, Item)'Old);
   --  Searches for Item in the set (which involves calling both Hash and
   --  Equivalent_Elements). If the search fails, then the operation raises
   --  Constraint_Error. Otherwise it removes the node from the set and then
   --  deallocates it. (This is the deletion analog of non-conditional
   --  Insert. It is intended for use when you want to assert that the item is
   --  already in the set.)

   procedure Delete (Container : in out Set; Position : in out Cursor) with
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

         --  Mapping from cursors to elements is preserved

         and Mapping_Preserved
               (E_Left  => Elements (Container),
                E_Right => Elements (Container)'Old,
                P_Left  => Positions (Container),
                P_Right => Positions (Container)'Old)
         and P.Keys_Included_Except
               (Positions (Container)'Old,
                Positions (Container),
                Position'Old);
   --  Removes the node designated by Position from the set, and then
   --  deallocates the node. The operation calls Hash to determine the bucket,
   --  and then compares Position to each node in the bucket until there's a
   --  match (it does not call Equivalent_Elements).

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

         and M.Included_In_Union
               (Model (Target), Model (Source), Model (Target)'Old)

         --  Actual value of elements come from either Left or Right

         and E_Elements_Included
               (Elements (Target),
                Model (Target)'Old,
                Elements (Target)'Old,
                Elements (Source))

         and E_Elements_Included
               (Elements (Target)'Old, Model (Target)'Old, Elements (Target))

         and E_Elements_Included
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
   --  Iterates over the Source set, and conditionally inserts each element
   --  into Target.

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

         and E_Elements_Included
               (Elements (Union'Result),
                Model (Left),
                Elements (Left),
                Elements (Right))

         and E_Elements_Included
               (Elements (Left), Model (Left), Elements (Union'Result))

         and E_Elements_Included
               (Elements (Right),
                Model (Left),
                Elements (Right),
                Elements (Union'Result));
   --  The operation first copies the Left set to the result, and then iterates
   --  over the Right set to conditionally insert each element into the result.

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

         and M.Includes_Intersection
               (Model (Target), Model (Source), Model (Target)'Old)

         --  Actual value of elements of Target is preserved

         and E_Elements_Included (Elements (Target), Elements (Target)'Old)
         and E_Elements_Included
               (Elements (Target)'Old, Model (Source), Elements (Target))

         --  Mapping from cursors of Target to elements is preserved

         and Mapping_Preserved
               (E_Left  => Elements (Target),
                E_Right => Elements (Target)'Old,
                P_Left  => Positions (Target),
                P_Right => Positions (Target)'Old);
   --  Iterates over the Target set (calling First and Next), calling Find to
   --  determine whether the element is in Source. If an equivalent element is
   --  not found in Source, the element is deleted from Target.

   function Intersection (Left, Right : Set) return Set with
     Global => null,
     Post   =>
       E.Big (Length (Intersection'Result)) =
         M.Num_Overlaps (Model (Left), Model (Right))

         --  Elements in the result of Intersection are in Left and Right

         and Model (Intersection'Result) <= Model (Left)
         and Model (Intersection'Result) <= Model (Right)

         --  Elements both in Left and Right are in the result of Intersection

         and M.Includes_Intersection
               (Model (Intersection'Result), Model (Left), Model (Right))

         --  Actual value of elements come from Left

         and E_Elements_Included
               (Elements (Intersection'Result), Elements (Left))

         and E_Elements_Included
               (Elements (Left), Model (Right),
                Elements (Intersection'Result));
   --  Iterates over the Left set, calling Find to determine whether the
   --  element is in Right. If an equivalent element is found, it is inserted
   --  into the result set.

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

         and M.Included_In_Union
               (Model (Target)'Old, Model (Target), Model (Source))

         --  Actual value of elements of Target is preserved

         and E_Elements_Included (Elements (Target), Elements (Target)'Old)
         and E_Elements_Included
               (Elements (Target)'Old, Model (Target), Elements (Target))

         --  Mapping from cursors of Target to elements is preserved

         and Mapping_Preserved
               (E_Left  => Elements (Target),
                E_Right => Elements (Target)'Old,
                P_Left  => Positions (Target),
                P_Right => Positions (Target)'Old);
   --  Iterates over the Source (calling First and Next), calling Find to
   --  determine whether the element is in Target. If an equivalent element is
   --  found, it is deleted from Target.

   function Difference (Left, Right : Set) return Set with
     Global => null,
     Post   =>
       E.Big (Length (Difference'Result)) = E.Big (Length (Left)) -
         M.Num_Overlaps (Model (Left), Model (Right))

         --  Elements of the result of Difference are in Left

         and Model (Difference'Result) <= Model (Left)

         --  Elements of the result of Difference are not in Right

         and M.No_Overlap (Model (Difference'Result), Model (Right))

         --  Elements in Left but not in Right are in the difference

         and M.Included_In_Union
               (Model (Left), Model (Difference'Result), Model (Right))

         --  Actual value of elements come from Left

         and E_Elements_Included
               (Elements (Difference'Result), Elements (Left))

         and E_Elements_Included
               (Elements (Left),
                Model (Difference'Result),
                Elements (Difference'Result));
   --  Iterates over the Left set, calling Find to determine whether the
   --  element is in the Right set. If an equivalent element is not found, the
   --  element is inserted into the result set.

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

         and M.Included_In_Union
               (Model (Target)'Old, Model (Target), Model (Source))

         --  Elements in Source but not in Target are in the difference

         and M.Included_In_Union
               (Model (Source), Model (Target), Model (Target)'Old)

         --  Actual value of elements come from either Left or Right

         and E_Elements_Included
               (Elements (Target),
                Model (Target)'Old,
                Elements (Target)'Old,
                Elements (Source))

         and E_Elements_Included
               (Elements (Target)'Old, Model (Target), Elements (Target))

         and E_Elements_Included
               (Elements (Source), Model (Target), Elements (Target));
   --  The operation iterates over the Source set, searching for the element
   --  in Target (calling Hash and Equivalent_Elements). If an equivalent
   --  element is found, it is removed from Target; otherwise it is inserted
   --  into Target.

   function Symmetric_Difference (Left, Right : Set) return Set with
     Global => null,
     Pre    => Length (Left) <= Count_Type'Last - Length (Right),
     Post   =>
       E.Big (Length (Symmetric_Difference'Result)) = E.Big (Length (Left)) -
         2 * M.Num_Overlaps (Model (Left), Model (Right)) +
         E.Big (Length (Right))

         --  Elements of the difference were not both in Left and Right

         and M.Not_In_Both
               (Model (Symmetric_Difference'Result),
                Model (Left),
                Model (Right))

         --  Elements in Left but not in Right are in the difference

         and M.Included_In_Union
               (Model (Left),
                Model (Symmetric_Difference'Result),
                Model (Right))

         --  Elements in Right but not in Left are in the difference

         and M.Included_In_Union
               (Model (Right),
                Model (Symmetric_Difference'Result),
                Model (Left))

         --  Actual value of elements come from either Left or Right

         and E_Elements_Included
               (Elements (Symmetric_Difference'Result),
                Model (Left),
                Elements (Left),
                Elements (Right))

         and E_Elements_Included
               (Elements (Left),
                Model (Symmetric_Difference'Result),
                Elements (Symmetric_Difference'Result))

         and E_Elements_Included
               (Elements (Right),
                Model (Symmetric_Difference'Result),
                Elements (Symmetric_Difference'Result));
   --  The operation first iterates over the Left set. It calls Find to
   --  determine whether the element is in the Right set. If no equivalent
   --  element is found, the element from Left is inserted into the result. The
   --  operation then iterates over the Right set, to determine whether the
   --  element is in the Left set. If no equivalent element is found, the Right
   --  element is inserted into the result.

   function "xor" (Left, Right : Set) return Set
     renames Symmetric_Difference;

   function Overlap (Left, Right : Set) return Boolean with
     Global => null,
     Post   =>
       Overlap'Result = not M.No_Overlap (Model (Left), Model (Right));
   --  Iterates over the Left set (calling First and Next), calling Find to
   --  determine whether the element is in the Right set. If an equivalent
   --  element is found, the operation immediately returns True. The operation
   --  returns False if the iteration over Left terminates without finding any
   --  equivalent element in Right.

   function Is_Subset (Subset : Set; Of_Set : Set) return Boolean with
     Global => null,
     Post   => Is_Subset'Result = (Model (Subset) <= Model (Of_Set));
   --  Iterates over Subset (calling First and Next), calling Find to determine
   --  whether the element is in Of_Set. If no equivalent element is found in
   --  Of_Set, the operation immediately returns False. The operation returns
   --  True if the iteration over Subset terminates without finding an element
   --  not in Of_Set (that is, every element in Subset is equivalent to an
   --  element in Of_Set).

   function First (Container : Set) return Cursor with
     Global         => null,
     Contract_Cases =>
       (Length (Container) = 0 =>
          First'Result = No_Element,

        others =>
          Has_Element (Container, First'Result)
            and P.Get (Positions (Container), First'Result) = 1);
   --  Returns a cursor that designates the first non-empty bucket, by
   --  searching from the beginning of the buckets array.

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
   --  Returns a cursor that designates the node that follows the current one
   --  designated by Position. If Position designates the last node in its
   --  bucket, the operation calls Hash to compute the index of this bucket,
   --  and searches the buckets array for the first non-empty bucket, starting
   --  from that index; otherwise, it simply follows the link to the next node
   --  in the same bucket.

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
   --  Equivalent to Position := Next (Position)

   function Find
     (Container : Set;
      Item      : Element_Type) return Cursor
   with
     Global         => null,
     Contract_Cases =>

       --  If Item is not contained in Container, Find returns No_Element

       (not Contains (Model (Container), Item) =>
          Find'Result = No_Element,

        --  Otherwise, Find returns a valid cursor in Container

        others =>
          P.Has_Key (Positions (Container), Find'Result)
            and P.Get (Positions (Container), Find'Result) =
                Find (Elements (Container), Item)

            --  The element designated by the result of Find is Item

            and Equivalent_Elements
                  (Element (Container, Find'Result), Item));
   --  Searches for Item in the set. Find calls Hash to determine the item's
   --  bucket; if the bucket is not empty, it calls Equivalent_Elements to
   --  compare Item to each element in the bucket. If the search succeeds, Find
   --  returns a cursor designating the node containing the equivalent element;
   --  otherwise, it returns No_Element.

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

      with function Hash (Key : Key_Type) return Hash_Type;

      with function Equivalent_Keys (Left, Right : Key_Type) return Boolean;

      --  Ghost lemma used to prove that Equivalent_Keys is compatible with
      --  Equivalent_Elements.

      with procedure Eq_Compatible (X, Y : Element_Type) is null
        with Ghost;

      --  Ghost lemma used to prove that Hash on keys is compatible with Hash
      --  on elements.

      with procedure Hash_Compatible (X : Element_Type) is null
        with Ghost;

   package Generic_Keys with SPARK_Mode, Always_Terminates is

      --  Contracts in this unit are meant for analysis only, not for run-time
      --  checking.

      pragma Assertion_Policy (Ignore);

      package Formal_Model with Ghost is

         --------------------------
         -- Instantiation Checks --
         --------------------------

         package Eq_Compatibility_Checks is new
           SPARK.Containers.Parameter_Checks.Op_Compatibility_Checks
             (T1                  => Element_Type,
              T2                  => Key_Type,
              Op1                 => Equivalent_Elements,
              Op2                 => Equivalent_Keys,
              F                   => Key,
              Param_Op_Compatible => Eq_Compatible);
         --  Check that Equivalent_Keys is compatible with Equivalent_Elements

         package Hash_Compatibility_Checks is new
           SPARK.Containers.Parameter_Checks.Hash_Compatibility_Checks
             (T1                    => Element_Type,
              T2                    => Key_Type,
              Hash1                 => Hash,
              Hash2                 => Hash,
              F                     => Key,
              Param_Hash_Compatible => Hash_Compatible);
         --  Check that Hash on keys is compatible with Hash on elements

         ------------------
         -- Formal Model --
         ------------------

         function M_Included_Except
           (Left  : M.Set;
            Right : M.Set;
            Key   : Key_Type) return Boolean
           with
             Global => null,
             Post   =>
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
                   (Element (Container, Key), E.Copy_Element (New_Item))

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
                    Position => Find (Container, Key))
             and Positions (Container) = Positions (Container)'Old;

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

               --  Mapping from cursors to elements is preserved

               and Mapping_Preserved
                     (E_Left  => Elements (Container),
                      E_Right => Elements (Container)'Old,
                      P_Left  => Positions (Container),
                      P_Right => Positions (Container)'Old)
               and P.Keys_Included_Except
                     (Positions (Container)'Old,
                      Positions (Container),
                      Find (Container, Key)'Old));

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

            --  Mapping from cursors to elements is preserved

            and Mapping_Preserved
                  (E_Left  => Elements (Container),
                   E_Right => Elements (Container)'Old,
                   P_Left  => Positions (Container),
                   P_Right => Positions (Container)'Old)
            and P.Keys_Included_Except
                  (Positions (Container)'Old,
                   Positions (Container),
                   Find (Container, Key)'Old);

      function Find (Container : Set; Key : Key_Type) return Cursor with
        Global         => null,
        Contract_Cases =>

          --  If Key is not contained in Container, Find returns No_Element

          ((for all E of Model (Container) =>
               not Equivalent_Keys (Key, Generic_Keys.Key (E))) =>
             Find'Result = No_Element,

           --  Otherwise, Find returns a valid cursor in Container

           others =>
             P.Has_Key (Positions (Container), Find'Result)

               --  The key designated by the result of Find is Key

               and Equivalent_Keys
                     (Generic_Keys.Key (Container, Find'Result), Key));

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

   --  Defines the Holder type

   package Element_Holder is new Holders (Element_Type);
   use Element_Holder;

   --  Defines the actual Set

   type Node_Type is
      record
         E_Holder    : Holder_Type;
         Next        : Count_Type;
         Has_Element : Boolean := False;
      end record;

   package HT_Types is new
     SPARK.Containers.Formal.Hash_Tables.Generic_Hash_Table_Types (Node_Type);

   type HT_Access is access all HT_Types.Hash_Table_Type;

   Empty_HT : aliased HT_Types.Hash_Table_Type (0, 0);

   type Set is new Ada.Finalization.Controlled
   with record
     Content : not null HT_Access := Empty_HT'Access;
   end record;

   overriding procedure Adjust (Source : in out Set);
   --  Makes a copy of Container in order to avoid sharing

   overriding procedure Finalize (Container : in out Set);
   --  Finalize the elment held by Container if necessary

   use HT_Types;
end SPARK.Containers.Formal.Unbounded_Hashed_Sets;
