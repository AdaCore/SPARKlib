--
--  Copyright (C) 2004-2025, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with SPARK.Containers.Functional.Vectors;
with SPARK.Containers.Functional.Maps;
with SPARK.Containers.Parameter_Checks;
with SPARK.Containers.Types;       use SPARK.Containers.Types;
with SPARK.Big_Integers;           use SPARK.Big_Integers;

generic
   type Element_Type is private;
   with function "=" (Left, Right : Element_Type) return Boolean is <>;

   --  Ghost lemmas used to prove that "=" is an equivalence relation

   with procedure Eq_Reflexive (X : Element_Type) is null
     with Ghost;
   with procedure Eq_Symmetric (X, Y : Element_Type) is null
     with Ghost;
   with procedure Eq_Transitive (X, Y, Z : Element_Type) is null
     with Ghost;

package SPARK.Containers.Formal.Doubly_Linked_Lists with
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
   type List (Capacity : Count_Type) is private with
     Iterable                  => (First       => First,
                                   Next        => Next,
                                   Has_Element => Has_Element,
                                   Element     => Element),
     Default_Initial_Condition => Is_Empty (List),
     Aggregate                 => (Empty       => Empty_List,
                                   Add_Unnamed => Append),
     Annotate                  =>
       (GNATprove, Container_Aggregates, "From_Model");
   pragma Annotate (GNATcheck, Exempt_Off,
                    "Restrictions:No_Specification_Of_Aspect => Iterable");

   type Cursor is record
      Node : Count_Type := 0;
   end record;

   No_Element : constant Cursor := Cursor'(Node => 0);

   function Empty_List (Capacity : Count_Type := 10) return List with
     Post => Is_Empty (Empty_List'Result)
       and then Empty_List'Result.Capacity = Capacity;

   function Length (Container : List) return Count_Type with
     Global => null,
     Post   => Length'Result <= Container.Capacity;

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

      ------------------
      -- Formal Model --
      ------------------

      subtype Positive_Count_Type is Count_Type range 1 .. Count_Type'Last;

      package M is new SPARK.Containers.Functional.Vectors
        (Index_Type                     => Positive_Count_Type,
         Element_Type                   => Element_Type,
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
         renames M.Element_Logic_Equal;

      function "="
        (Left  : M.Sequence;
         Right : M.Sequence) return Boolean renames M."=";

      function "<"
        (Left  : M.Sequence;
         Right : M.Sequence) return Boolean renames M."<";

      function "<="
        (Left  : M.Sequence;
         Right : M.Sequence) return Boolean renames M."<=";

      function M_Elements_In_Union
        (Container : M.Sequence;
         Left      : M.Sequence;
         Right     : M.Sequence) return Boolean
      --  The elements of Container are contained in either Left or Right
      with
        Global => null,
        Post   =>
          M_Elements_In_Union'Result =
            (for all I in 1 .. M.Last (Container) =>
              (for some J in 1 .. M.Last (Left) =>
                 Element_Logic_Equal
                   (Element (Container, I), Element (Left, J)))
              or (for some J in 1 .. M.Last (Right) =>
                    Element_Logic_Equal
                      (Element (Container, I), Element (Right, J))));
      pragma Annotate (GNATprove, Inline_For_Proof, M_Elements_In_Union);

      function M_Elements_Included
        (Left  : M.Sequence;
         L_Fst : Positive_Count_Type := 1;
         L_Lst : Count_Type;
         Right : M.Sequence;
         R_Fst : Positive_Count_Type := 1;
         R_Lst : Count_Type) return Boolean
      --  The elements of the slice from L_Fst to L_Lst in Left are contained
      --  in the slide from R_Fst to R_Lst in Right.
      with
        Global => null,
        Pre    => L_Lst <= M.Last (Left) and R_Lst <= M.Last (Right),
        Post   =>
          M_Elements_Included'Result =
            (for all I in L_Fst .. L_Lst =>
              (for some J in R_Fst .. R_Lst =>
                Element_Logic_Equal (Element (Left, I), Element (Right, J))));
      pragma Annotate (GNATprove, Inline_For_Proof, M_Elements_Included);

      function M_Elements_Reversed
        (Left  : M.Sequence;
         Right : M.Sequence) return Boolean
      --  Right is Left in reverse order
      with
        Global => null,
        Post   =>
          M_Elements_Reversed'Result =
            (M.Last (Left) = M.Last (Right)
              and (for all I in 1 .. M.Last (Left) =>
                     Element_Logic_Equal
                       (Element (Left, I),
                        Element (Right, M.Last (Left) - I + 1)))
              and (for all I in 1 .. M.Last (Left) =>
                     Element_Logic_Equal
                       (Element (Right, I),
                        Element (Left, M.Last (Left) - I + 1))));
      pragma Annotate (GNATprove, Inline_For_Proof, M_Elements_Reversed);

      function M_Elements_Swapped
        (Left  : M.Sequence;
         Right : M.Sequence;
         X     : Positive_Count_Type;
         Y     : Positive_Count_Type) return Boolean
      --  Elements stored at X and Y are reversed in Left and Right
      with
        Global => null,
        Pre    => X <= M.Last (Left) and Y <= M.Last (Left),
        Post   =>
          M_Elements_Swapped'Result =
            (M.Last (Left) = M.Last (Right)
              and Element_Logic_Equal (Element (Left, X), Element (Right, Y))
              and Element_Logic_Equal (Element (Left, Y), Element (Right, X))
              and M.Equal_Except (Left, Right, X, Y));
      pragma Annotate (GNATprove, Inline_For_Proof, M_Elements_Swapped);

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

      function P_Positions_Swapped
        (Left  : P.Map;
         Right : P.Map;
         X     : Cursor;
         Y     : Cursor) return Boolean
      --  Left and Right contain the same cursors, but the positions of X and Y
      --  are reversed.
      with
        Ghost,
        Global => null,
        Post   =>
          P_Positions_Swapped'Result =
            (P.Same_Keys (Left, Right)
              and P.Elements_Equal_Except (Left, Right, X, Y)
              and P.Has_Key (Left, X)
              and P.Has_Key (Left, Y)
              and P.Get (Left, X) = P.Get (Right, Y)
              and P.Get (Left, Y) = P.Get (Right, X));

      function P_Positions_Truncated
        (Small : P.Map;
         Big   : P.Map;
         Cut   : Positive_Count_Type;
         Count : Count_Type := 1) return Boolean
      with
        Ghost,
        Global => null,
        Post   =>
          P_Positions_Truncated'Result =

            --  Big contains all cursors of Small at the same position

            (Small <= Big

              --  New cursors of Big (if any) are between Cut and Cut - 1 +
              --  Count.

              and (for all I of Big =>
                    P.Has_Key (Small, I)
                      or P.Get (Big, I) - Count in Cut - Count .. Cut - 1));

      function Mapping_Preserved
        (M_Left  : M.Sequence;
         M_Right : M.Sequence;
         P_Left  : P.Map;
         P_Right : P.Map) return Boolean
      with
        Ghost,
        Global => null,
        Post   =>
          (if Mapping_Preserved'Result then

             --  Left and Right contain the same cursors

             P.Same_Keys (P_Left, P_Right)

               --  Mappings from cursors to elements induced by M_Left, P_Left
               --  and M_Right, P_Right are the same.

               and (for all C of P_Left =>
                     Element_Logic_Equal
                       (M.Get (M_Left, P.Get (P_Left, C)),
                        M.Get (M_Right, P.Get (P_Right, C)))));

      function Model (Container : List) return M.Sequence with
      --  The high-level model of a list is a sequence of elements. Cursors are
      --  not represented in this model.

        Ghost,
        Global => null,
        Post   => M.Last (Model'Result) = Length (Container);

      function Positions (Container : List) return P.Map with
      --  The Positions map is used to model cursors. It only contains valid
      --  cursors and map them to their position in the container.

        Ghost,
        Global => null,
        Post   =>
          not P.Has_Key (Positions'Result, No_Element)

            --  Positions of cursors are smaller than the container's length.

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

      procedure Lift_Abstraction_Level (Container : List) with
        --  Lift_Abstraction_Level is a ghost procedure that does nothing but
        --  assume that we can access to the same elements by iterating over
        --  positions or cursors.
        --  This information is not generally useful except when switching from
        --  a low-level cursor-aware view of a container to a high-level
        --  position-based view.

        Ghost,
        Global => null,
        Post   =>
          (for all Elt of Model (Container) =>
            (for some I of Positions (Container) =>
               Element_Logic_Equal
                 (M.Get (Model (Container), P.Get (Positions (Container), I)),
                  Elt)));

      function Element
        (S : M.Sequence;
         I : Count_Type) return Element_Type renames M.Get;
      --  To improve readability of contracts, we rename the function used to
      --  access an element in the model to Element.

   end Formal_Model;
   use Formal_Model;

   function "=" (Left, Right : List) return Boolean with
     Global => null,
     Post   => "="'Result =
       (M.Equivalent_Sequences (Model (Left), Model (Right)));

   function Is_Empty (Container : List) return Boolean with
     Global => null,
     Post   => Is_Empty'Result = (Length (Container) = 0);

   procedure Clear (Container : in out List) with
     Global => null,
     Post   => Length (Container) = 0;

   procedure Assign (Target : in out List; Source : List) with
     Global => null,
     Pre    => Target.Capacity >= Length (Source),
     Post   => M.Equal (Model (Target), Model (Source));

   function Copy (Source : List; Capacity : Count_Type := 0) return List with
     Global => null,
     Pre    => Capacity = 0 or else Capacity >= Source.Capacity,
     Post   =>
       M.Equal (Model (Copy'Result), Model (Source))
         and Positions (Copy'Result) = Positions (Source)
         and (if Capacity = 0 then
                 Copy'Result.Capacity = Source.Capacity
              else
                 Copy'Result.Capacity = Capacity);

   function Element
     (Container : List;
      Position : Cursor) return Element_Type
   with
     Global   => null,
     Pre      => Has_Element (Container, Position),
     Post     =>
       Element'Result =
         Element (Model (Container), P.Get (Positions (Container), Position)),
     Annotate => (GNATprove, Inline_For_Proof);

   procedure Replace_Element
     (Container : in out List;
      Position  : Cursor;
      New_Item  : Element_Type)
   with
     Global => null,
     Pre    => Has_Element (Container, Position),
     Post   =>
       Length (Container) = Length (Container)'Old

         --  Cursors are preserved

         and Positions (Container)'Old = Positions (Container)

         --  The element at the position of Position in Container is New_Item

         and Element_Logic_Equal
               (Element
                  (Model (Container),
                   P.Get (Positions (Container), Position)),
                M.Copy_Element (New_Item))

         --  Other elements are preserved

         and M.Equal_Except
               (Model (Container)'Old,
                Model (Container),
                P.Get (Positions (Container), Position));

   function At_End (E : List) return List is (E)
   with Ghost,
     Annotate => (GNATprove, At_End_Borrow);

   function At_End
     (E : access constant Element_Type) return access constant Element_Type
   is (E)
   with Ghost,
     Annotate => (GNATprove, At_End_Borrow);

   function Constant_Reference
     (Container : aliased List;
      Position  : Cursor) return not null access constant Element_Type
   with
     Global => null,
     Pre    => Has_Element (Container, Position),
     Post   =>
       Element_Logic_Equal
         (Constant_Reference'Result.all,
          Element (Model (Container),
                   P.Get (Positions (Container), Position)));

   function Reference
     (Container : aliased in out List;
      Position  : Cursor) return not null access Element_Type
   with
     Global => null,
     Pre    => Has_Element (Container, Position),
     Post   =>
      Length (Container) = Length (At_End (Container))

         --  Cursors are preserved

         and Positions (Container) = Positions (At_End (Container))

         --  Container will have Result.all at position Position

         and Element_Logic_Equal
               (At_End (Reference'Result).all,
                Element (Model (At_End (Container)),
                         P.Get (Positions (At_End (Container)), Position)))

         --  All other elements are preserved

         and M.Equal_Except
               (Model (Container),
                Model (At_End (Container)),
                P.Get (Positions (At_End (Container)), Position));

   procedure Move (Target : in out List; Source : in out List) with
     Global => null,
     Pre    => Target.Capacity >= Length (Source),
     Post   =>
       M.Equal (Model (Target), Model (Source'Old)) and Length (Source) = 0;

   procedure Insert
     (Container : in out List;
      Before    : Cursor;
      New_Item  : Element_Type)
   with
     Global         => null,
     Pre            =>
       Length (Container) < Container.Capacity
         and then (Has_Element (Container, Before)
                    or else Before = No_Element),
     Post           => Length (Container) = Length (Container)'Old + 1,
     Contract_Cases =>
       (Before = No_Element =>

          --  Positions contains a new mapping from the last cursor of
          --  Container to its length.

          P.Get (Positions (Container), Last (Container)) = Length (Container)

            --  Other cursors come from Container'Old

            and P.Keys_Included_Except
                  (Left    => Positions (Container),
                   Right   => Positions (Container)'Old,
                   New_Key => Last (Container))

            --  Cursors of Container'Old keep the same position

            and Positions (Container)'Old <= Positions (Container)

            --  Model contains a new element New_Item at the end

            and Element_Logic_Equal
                  (Element (Model (Container), Length (Container)),
                   M.Copy_Element (New_Item))

            --  Elements of Container'Old are preserved

            and M.Equal_Prefix (Model (Container)'Old, Model (Container)),

        others =>

          --  The elements of Container located before Before are preserved

          M.Range_Equal
            (Left  => Model (Container)'Old,
             Right => Model (Container),
             Fst   => 1,
             Lst   => P.Get (Positions (Container)'Old, Before) - 1)

            --  Other elements are shifted by 1

            and M.Range_Shifted
                  (Left   => Model (Container)'Old,
                   Right  => Model (Container),
                   Fst    => P.Get (Positions (Container)'Old, Before),
                   Lst    => Length (Container)'Old,
                   Offset => 1)

            --  New_Item is stored at the previous position of Before in
            --  Container.

            and Element_Logic_Equal
                  (Element
                     (Model (Container),
                      P.Get (Positions (Container)'Old, Before)),
                   M.Copy_Element (New_Item))

            --  A new cursor has been inserted at position Before in Container

            and P_Positions_Shifted
                  (Positions (Container)'Old,
                   Positions (Container),
                   Cut => P.Get (Positions (Container)'Old, Before)));

   procedure Insert
     (Container : in out List;
      Before    : Cursor;
      New_Item  : Element_Type;
      Count     : Count_Type)
   with
     Global         => null,
     Pre            =>
       Length (Container) <= Container.Capacity - Count
         and then (Has_Element (Container, Before)
                    or else Before = No_Element),
     Post           => Length (Container) = Length (Container)'Old + Count,
     Contract_Cases =>
       (Before = No_Element =>

          --  The elements of Container are preserved

          M.Range_Equal
            (Left  => Model (Container)'Old,
             Right => Model (Container),
             Fst   => 1,
             Lst   => Length (Container)'Old)

            --  Container contains Count times New_Item at the end

            and (if Count > 0 then
                    M.Constant_Range
                      (Container => Model (Container),
                       Fst       => Length (Container)'Old + 1,
                       Lst       => Length (Container),
                       Item      => New_Item))

            --  Count cursors have been inserted at the end of Container

            and P_Positions_Truncated
                  (Positions (Container)'Old,
                   Positions (Container),
                   Cut   => Length (Container)'Old + 1,
                   Count => Count),

        others =>

          --  The elements of Container located before Before are preserved

          M.Range_Equal
            (Left  => Model (Container)'Old,
             Right => Model (Container),
             Fst   => 1,
             Lst   => P.Get (Positions (Container)'Old, Before) - 1)

            --  Other elements are shifted by Count

            and M.Range_Shifted
                  (Left   => Model (Container)'Old,
                   Right  => Model (Container),
                   Fst    => P.Get (Positions (Container)'Old, Before),
                   Lst    => Length (Container)'Old,
                   Offset => M.Big (Count))

            --  Container contains Count times New_Item after position Before

            and M.Constant_Range
                  (Container => Model (Container),
                   Fst       => P.Get (Positions (Container)'Old, Before),
                   Lst       =>
                     P.Get (Positions (Container)'Old, Before) - 1 + Count,
                   Item      => New_Item)

            --  Count cursors have been inserted at position Before in
            --  Container.

            and P_Positions_Shifted
                  (Positions (Container)'Old,
                   Positions (Container),
                   Cut   => P.Get (Positions (Container)'Old, Before),
                   Count => Count));

   procedure Insert
     (Container : in out List;
      Before    : Cursor;
      New_Item  : Element_Type;
      Position  : out Cursor)
   with
     Global => null,
     Pre    =>
       Length (Container) < Container.Capacity
         and then (Has_Element (Container, Before)
                    or else Before = No_Element),
     Post   =>
       Length (Container) = Length (Container)'Old + 1

          --  Positions is valid in Container and it is located either before
          --  Before if it is valid in Container or at the end if it is
          --  No_Element.

          and P.Has_Key (Positions (Container), Position)
          and (if Before = No_Element then
                  P.Get (Positions (Container), Position) = Length (Container)
               else
                  P.Get (Positions (Container), Position) =
                  P.Get (Positions (Container)'Old, Before))

          --  The elements of Container located before Position are preserved

          and M.Range_Equal
                (Left  => Model (Container)'Old,
                 Right => Model (Container),
                 Fst   => 1,
                 Lst   => P.Get (Positions (Container), Position) - 1)

          --  Other elements are shifted by 1

          and M.Range_Shifted
                (Left   => Model (Container)'Old,
                 Right  => Model (Container),
                 Fst    => P.Get (Positions (Container), Position),
                 Lst    => Length (Container)'Old,
                 Offset => 1)

          --  New_Item is stored at Position in Container

          and Element_Logic_Equal
                (Element
                   (Model (Container),
                    P.Get (Positions (Container), Position)),
                 M.Copy_Element (New_Item))

          --  A new cursor has been inserted at position Position in Container

          and P_Positions_Shifted
                (Positions (Container)'Old,
                 Positions (Container),
                 Cut => P.Get (Positions (Container), Position));

   procedure Insert
     (Container : in out List;
      Before    : Cursor;
      New_Item  : Element_Type;
      Position  : out Cursor;
      Count     : Count_Type)
   with
     Global         => null,
     Pre            =>
       Length (Container) <= Container.Capacity - Count
         and then (Has_Element (Container, Before)
                    or else Before = No_Element),
     Post           => Length (Container) = Length (Container)'Old + Count,
     Contract_Cases =>
       (Count = 0 =>
         Position = Before
           and M.Equal (Model (Container), Model (Container)'Old)
           and Positions (Container) = Positions (Container)'Old,

        others =>

          --  Positions is valid in Container and it is located either before
          --  Before if it is valid in Container or at the end if it is
          --  No_Element.

          P.Has_Key (Positions (Container), Position)
            and (if Before = No_Element then
                    P.Get (Positions (Container), Position) =
                    Length (Container)'Old + 1
                 else
                    P.Get (Positions (Container), Position) =
                    P.Get (Positions (Container)'Old, Before))

            --  The elements of Container located before Position are preserved

            and M.Range_Equal
                  (Left  => Model (Container)'Old,
                   Right => Model (Container),
                   Fst   => 1,
                   Lst   => P.Get (Positions (Container), Position) - 1)

            --  Other elements are shifted by Count

            and M.Range_Shifted
                  (Left   => Model (Container)'Old,
                   Right  => Model (Container),
                   Fst    => P.Get (Positions (Container), Position),
                   Lst    => Length (Container)'Old,
                   Offset => M.Big (Count))

            --  Container contains Count times New_Item after position Position

            and M.Constant_Range
                  (Container => Model (Container),
                   Fst       => P.Get (Positions (Container), Position),
                   Lst       =>
                     P.Get (Positions (Container), Position) - 1 + Count,
                   Item      => New_Item)

            --  Count cursor have been inserted at Position in Container

            and P_Positions_Shifted
                  (Positions (Container)'Old,
                   Positions (Container),
                   Cut   => P.Get (Positions (Container), Position),
                   Count => Count));

   procedure Prepend (Container : in out List; New_Item : Element_Type) with
     Global => null,
     Pre    => Length (Container) < Container.Capacity,
     Post   =>
       Length (Container) = Length (Container)'Old + 1

         --  Elements are shifted by 1

         and M.Range_Shifted
               (Left   => Model (Container)'Old,
                Right  => Model (Container),
                Fst    => 1,
                Lst    => Length (Container)'Old,
                Offset => 1)

         --  New_Item is the first element of Container

         and Element_Logic_Equal
               (Element (Model (Container), 1), M.Copy_Element (New_Item))

         --  A new cursor has been inserted at the beginning of Container

         and P_Positions_Shifted
               (Positions (Container)'Old,
                Positions (Container),
                Cut => 1);

   procedure Prepend
     (Container : in out List;
      New_Item  : Element_Type;
      Count     : Count_Type)
   with
     Global => null,
     Pre    => Length (Container) <= Container.Capacity - Count,
     Post   =>
       Length (Container) = Length (Container)'Old + Count

         --  Elements are shifted by Count

         and M.Range_Shifted
               (Left     => Model (Container)'Old,
                Right     => Model (Container),
                Fst    => 1,
                Lst    => Length (Container)'Old,
                Offset => M.Big (Count))

         --  Container starts with Count times New_Item

         and M.Constant_Range
               (Container => Model (Container),
                Fst       => 1,
                Lst       => Count,
                Item      => New_Item)

         --  Count cursors have been inserted at the beginning of Container

         and P_Positions_Shifted
               (Positions (Container)'Old,
                Positions (Container),
                Cut   => 1,
                Count => Count);

   procedure Append (Container : in out List; New_Item : Element_Type) with
     Global => null,
     Pre    => Length (Container) < Container.Capacity,
     Post   =>
       Length (Container) = Length (Container)'Old + 1

         --  Positions contains a new mapping from the last cursor of Container
         --  to its length.

         and P.Get (Positions (Container), Last (Container)) =
               Length (Container)

         --  Other cursors come from Container'Old

         and P.Keys_Included_Except
               (Left    => Positions (Container),
                Right   => Positions (Container)'Old,
                New_Key => Last (Container))

         --  Cursors of Container'Old keep the same position

         and Positions (Container)'Old <= Positions (Container)

         --  Model contains a new element New_Item at the end

         and Element_Logic_Equal
               (Element (Model (Container), Length (Container)),
                M.Copy_Element (New_Item))

         --  Elements of Container'Old are preserved

         and M.Equal_Prefix (Model (Container)'Old, Model (Container));

   procedure Append
     (Container : in out List;
      New_Item  : Element_Type;
      Count     : Count_Type)
   with
     Global => null,
     Pre    => Length (Container) <= Container.Capacity - Count,
     Post   =>
       Length (Container) = Length (Container)'Old + Count

         --  The elements of Container are preserved

         and M.Equal_Prefix (Model (Container)'Old, Model (Container))

         --  Container contains Count times New_Item at the end

         and (if Count > 0 then
                 M.Constant_Range
                   (Container => Model (Container),
                     Fst       => Length (Container)'Old + 1,
                     Lst       => Length (Container),
                     Item      => New_Item))

         --  Count cursors have been inserted at the end of Container

         and P_Positions_Truncated
               (Positions (Container)'Old,
                Positions (Container),
                Cut   => Length (Container)'Old + 1,
                Count => Count);

   procedure Delete (Container : in out List; Position : in out Cursor) with
     Global  => null,
     Depends => (Container =>+ Position, Position => null),
     Pre     => Has_Element (Container, Position),
     Post    =>
       Length (Container) = Length (Container)'Old - 1

         --  Position is set to No_Element

         and Position = No_Element

         --  The elements of Container located before Position are preserved.

         and M.Range_Equal
               (Left  => Model (Container)'Old,
                Right => Model (Container),
                Fst   => 1,
                Lst   => P.Get (Positions (Container)'Old, Position'Old) - 1)

         --  The elements located after Position are shifted by 1

         and M.Range_Shifted
               (Left   => Model (Container),
                Right  => Model (Container)'Old,
                Fst    => P.Get (Positions (Container)'Old, Position'Old),
                Lst    => Length (Container),
                Offset => 1)

         --  Position has been removed from Container

         and P_Positions_Shifted
               (Positions (Container),
                Positions (Container)'Old,
                Cut   => P.Get (Positions (Container)'Old, Position'Old));

   procedure Delete
     (Container : in out List;
      Position  : in out Cursor;
      Count     : Count_Type)
   with
     Global         => null,
     Pre            => Has_Element (Container, Position),
     Post           =>
       Length (Container) in
         Length (Container)'Old - Count .. Length (Container)'Old

         --  Position is set to No_Element

         and Position = No_Element

         --  The elements of Container located before Position are preserved.

         and M.Range_Equal
               (Left  => Model (Container)'Old,
                Right => Model (Container),
                Fst   => 1,
                Lst   => P.Get (Positions (Container)'Old, Position'Old) - 1),

     Contract_Cases =>

       --  All the elements after Position have been erased

       (Length (Container) - Count < P.Get (Positions (Container), Position) =>
          Length (Container) =
            P.Get (Positions (Container)'Old, Position'Old) - 1

            --  At most Count cursors have been removed at the end of Container

            and P_Positions_Truncated
                 (Positions (Container),
                  Positions (Container)'Old,
                  Cut   => P.Get (Positions (Container)'Old, Position'Old),
                  Count => Count),

        others =>
          Length (Container) = Length (Container)'Old - Count

            --  Other elements are shifted by Count

            and M.Range_Shifted
                  (Left   => Model (Container),
                   Right  => Model (Container)'Old,
                   Fst    => P.Get (Positions (Container)'Old, Position'Old),
                   Lst    => Length (Container),
                   Offset => M.Big (Count))

            --  Count cursors have been removed from Container at Position

            and P_Positions_Shifted
                 (Positions (Container),
                  Positions (Container)'Old,
                  Cut   => P.Get (Positions (Container)'Old, Position'Old),
                  Count => Count));

   procedure Delete_First (Container : in out List) with
     Global => null,
     Pre    => not Is_Empty (Container),
     Post   =>
       Length (Container) = Length (Container)'Old - 1

         --  The elements of Container are shifted by 1

         and M.Range_Shifted
               (Left   => Model (Container),
                Right  => Model (Container)'Old,
                Fst    => 1,
                Lst    => Length (Container),
                Offset => 1)

         --  The first cursor of Container has been removed

         and P_Positions_Shifted
               (Positions (Container),
                Positions (Container)'Old,
                Cut   => 1);

   procedure Delete_First (Container : in out List; Count : Count_Type) with
     Global         => null,
     Contract_Cases =>

       --  All the elements of Container have been erased

       (Length (Container) <= Count =>
          Length (Container) = 0,

        others =>
          Length (Container) = Length (Container)'Old - Count

            --  Elements of Container are shifted by Count

            and M.Range_Shifted
                  (Left   => Model (Container),
                   Right  => Model (Container)'Old,
                   Fst    => 1,
                   Lst    => Length (Container),
                   Offset => M.Big (Count))

            --  The first Count cursors have been removed from Container

            and P_Positions_Shifted
                  (Positions (Container),
                   Positions (Container)'Old,
                   Cut   => 1,
                   Count => Count));

   procedure Delete_Last (Container : in out List) with
     Global => null,
     Pre    => not Is_Empty (Container),
     Post   =>
       Length (Container) = Length (Container)'Old - 1

         --  The elements of Container are preserved

         and M.Equal_Prefix (Model (Container), Model (Container)'Old)

         --  The last cursor of Container has been removed

         and not P.Has_Key (Positions (Container), Last (Container)'Old)

         --  Other cursors are still valid

         and P.Keys_Included_Except
               (Left    => Positions (Container)'Old,
                Right   => Positions (Container),
                New_Key => Last (Container)'Old)

         --  The positions of other cursors are preserved

         and Positions (Container) <= Positions (Container)'Old;

   procedure Delete_Last (Container : in out List; Count : Count_Type) with
     Global         => null,
     Contract_Cases =>

       --  All the elements of Container have been erased

       (Length (Container) <= Count =>
          Length (Container) = 0,

        others =>
          Length (Container) = Length (Container)'Old - Count

            --  The elements of Container are preserved

            and M.Equal_Prefix (Model (Container), Model (Container)'Old)

            --  At most Count cursors have been removed at the end of Container

            and P_Positions_Truncated
                  (Positions (Container),
                   Positions (Container)'Old,
                   Cut   => Length (Container) + 1,
                   Count => Count));

   procedure Reverse_Elements (Container : in out List) with
     Global => null,
     Post   => M_Elements_Reversed (Model (Container)'Old, Model (Container));

   procedure Swap
     (Container : in out List;
      I         : Cursor;
      J         : Cursor)
   with
     Global => null,
     Pre    => Has_Element (Container, I) and then Has_Element (Container, J),
     Post   =>
       M_Elements_Swapped
         (Model (Container)'Old,
          Model (Container),
          X => P.Get (Positions (Container)'Old, I),
          Y => P.Get (Positions (Container)'Old, J))

         and Positions (Container) = Positions (Container)'Old;

   procedure Swap_Links
     (Container : in out List;
      I         : Cursor;
      J         : Cursor)
   with
     Global => null,
     Pre    => Has_Element (Container, I) and then Has_Element (Container, J),
     Post   =>
       M_Elements_Swapped
         (Model (Container'Old),
          Model (Container),
          X => P.Get (Positions (Container)'Old, I),
          Y => P.Get (Positions (Container)'Old, J))
         and P_Positions_Swapped
               (Positions (Container)'Old, Positions (Container), I, J);

   procedure Splice
     (Target : in out List;
      Before : Cursor;
      Source : in out List)
   --  Target and Source should not be aliased
   with
     Global         => null,
     Pre            =>
       Length (Source) <= Target.Capacity - Length (Target)
         and then (Has_Element (Target, Before)
                    or else Before = No_Element),
     Post           =>
       Length (Source) = 0
         and Length (Target) = Length (Target)'Old + Length (Source)'Old,
     Contract_Cases =>
       (Before = No_Element =>

          --  The elements of Target are preserved

          M.Range_Equal
            (Left  => Model (Target)'Old,
             Right => Model (Target),
             Fst   => 1,
             Lst   => Length (Target)'Old)

            --  The elements of Source are appended to target, the order is not
            --  specified.

            and M_Elements_Included
                  (Left   => Model (Source)'Old,
                   L_Lst  => Length (Source)'Old,
                   Right  => Model (Target),
                   R_Fst  => Length (Target)'Old + 1,
                   R_Lst  => Length (Target))

            and M_Elements_Included
                  (Left   => Model (Target),
                   L_Fst  => Length (Target)'Old + 1,
                   L_Lst  => Length (Target),
                   Right  => Model (Source)'Old,
                   R_Lst  => Length (Source)'Old)

            --  Cursors have been inserted at the end of Target

            and P_Positions_Truncated
                  (Positions (Target)'Old,
                   Positions (Target),
                   Cut   => Length (Target)'Old + 1,
                   Count => Length (Source)'Old),

        others =>

          --  The elements of Target located before Before are preserved

          M.Range_Equal
            (Left  => Model (Target)'Old,
             Right => Model (Target),
             Fst   => 1,
             Lst   => P.Get (Positions (Target)'Old, Before) - 1)

            --  The elements of Source are inserted before Before, the order is
            --  not specified.

            and M_Elements_Included
                  (Left   => Model (Source)'Old,
                   L_Lst  => Length (Source)'Old,
                   Right  => Model (Target),
                   R_Fst  => P.Get (Positions (Target)'Old, Before),
                   R_Lst  =>
                     P.Get (Positions (Target)'Old, Before) - 1 +
                       Length (Source)'Old)

            and M_Elements_Included
                  (Left   => Model (Target),
                   L_Fst  => P.Get (Positions (Target)'Old, Before),
                   L_Lst  =>
                     P.Get (Positions (Target)'Old, Before) - 1 +
                       Length (Source)'Old,
                   Right  => Model (Source)'Old,
                   R_Lst  => Length (Source)'Old)

          --  Other elements are shifted by the length of Source

          and M.Range_Shifted
                (Left   => Model (Target)'Old,
                 Right  => Model (Target),
                 Fst    => P.Get (Positions (Target)'Old, Before),
                 Lst    => Length (Target)'Old,
                 Offset => M.Big (Length (Source)'Old))

          --  Cursors have been inserted at position Before in Target

          and P_Positions_Shifted
                (Positions (Target)'Old,
                 Positions (Target),
                 Cut   => P.Get (Positions (Target)'Old, Before),
                 Count => Length (Source)'Old));

   procedure Splice
     (Target   : in out List;
      Before   : Cursor;
      Source   : in out List;
      Position : in out Cursor)
   --  Target and Source should not be aliased
   with
     Global => null,
     Pre    =>
       (Has_Element (Target, Before) or else Before = No_Element)
         and then Has_Element (Source, Position)
         and then Length (Target) < Target.Capacity,
     Post   =>
       Length (Target) = Length (Target)'Old + 1
         and Length (Source) = Length (Source)'Old - 1

         --  The elements of Source located before Position are preserved

         and M.Range_Equal
               (Left  => Model (Source)'Old,
                Right => Model (Source),
                Fst   => 1,
                Lst   => P.Get (Positions (Source)'Old, Position'Old) - 1)

         --  The elements located after Position are shifted by 1

         and M.Range_Shifted
               (Left   => Model (Source)'Old,
                Right  => Model (Source),
                Fst    => P.Get (Positions (Source)'Old, Position'Old) + 1,
                Lst    => Length (Source)'Old,
                Offset => -1)

         --  Position has been removed from Source

         and P_Positions_Shifted
               (Positions (Source),
                Positions (Source)'Old,
                Cut   => P.Get (Positions (Source)'Old, Position'Old))

         --  Positions is valid in Target and it is located either before
         --  Before if it is valid in Target or at the end if it is No_Element.

         and P.Has_Key (Positions (Target), Position)
         and (if Before = No_Element then
                 P.Get (Positions (Target), Position) = Length (Target)
              else
                 P.Get (Positions (Target), Position) =
                 P.Get (Positions (Target)'Old, Before))

         --  The elements of Target located before Position are preserved

         and M.Range_Equal
               (Left  => Model (Target)'Old,
                Right => Model (Target),
                Fst   => 1,
                Lst   => P.Get (Positions (Target), Position) - 1)

         --  Other elements are shifted by 1

         and M.Range_Shifted
               (Left   => Model (Target)'Old,
                Right  => Model (Target),
                Fst    => P.Get (Positions (Target), Position),
                Lst    => Length (Target)'Old,
                Offset => 1)

         --  The element located at Position in Source is moved to Target

         and Element_Logic_Equal
               (Element (Model (Target),
                         P.Get (Positions (Target), Position)),
                Element (Model (Source)'Old,
                         P.Get (Positions (Source)'Old, Position'Old)))

         --  A new cursor has been inserted at position Position in Target

         and P_Positions_Shifted
               (Positions (Target)'Old,
                Positions (Target),
                Cut => P.Get (Positions (Target), Position));

   procedure Splice
     (Container : in out List;
      Before    : Cursor;
      Position  : Cursor)
   with
     Global         => null,
     Pre            =>
       (Has_Element (Container, Before) or else Before = No_Element)
         and then Has_Element (Container, Position),
     Post           => Length (Container) = Length (Container)'Old,
     Contract_Cases =>
       (Before = Position =>
          M.Equal (Model (Container), Model (Container)'Old)
            and Positions (Container) = Positions (Container)'Old,

        Before = No_Element =>

          --  The elements located before Position are preserved

          M.Range_Equal
            (Left  => Model (Container)'Old,
             Right => Model (Container),
             Fst   => 1,
             Lst   => P.Get (Positions (Container)'Old, Position) - 1)

          --  The elements located after Position are shifted by 1

          and M.Range_Shifted
                (Left   => Model (Container)'Old,
                 Right  => Model (Container),
                 Fst    => P.Get (Positions (Container)'Old, Position) + 1,
                 Lst    => Length (Container)'Old,
                 Offset => -1)

          --  The last element of Container is the one that was previously at
          --  Position.

          and Element_Logic_Equal
                (Element (Model (Container), Length (Container)),
                 Element (Model (Container)'Old,
                          P.Get (Positions (Container)'Old, Position)))

          --  Cursors from Container continue designating the same elements

          and Mapping_Preserved
                (M_Left  => Model (Container)'Old,
                 M_Right => Model (Container),
                 P_Left  => Positions (Container)'Old,
                 P_Right => Positions (Container)),

        others =>

          --  The elements located before Position and Before are preserved

          M.Range_Equal
            (Left  => Model (Container)'Old,
             Right => Model (Container),
             Fst   => 1,
             Lst   =>
               Count_Type'Min
                 (P.Get (Positions (Container)'Old, Position) - 1,
                  P.Get (Positions (Container)'Old, Before) - 1))

            --  The elements located after Position and Before are preserved

            and M.Range_Equal
                  (Left  => Model (Container)'Old,
                   Right => Model (Container),
                   Fst   =>
                     Count_Type'Max
                       (P.Get (Positions (Container)'Old, Position) + 1,
                        P.Get (Positions (Container)'Old, Before)),
                   Lst   => Length (Container))

            --  The elements located after Before and before Position are
            --  shifted by 1 to the right.

            and M.Range_Shifted
                  (Left   => Model (Container)'Old,
                   Right  => Model (Container),
                   Fst    => P.Get (Positions (Container)'Old, Before),
                   Lst    => P.Get (Positions (Container)'Old, Position) - 1,
                   Offset => 1)

            --  The elements located after Position and before Before are
            --  shifted by 1 to the left.

            and M.Range_Shifted
                  (Left   => Model (Container)'Old,
                   Right  => Model (Container),
                   Fst    => P.Get (Positions (Container)'Old, Position) + 1,
                   Lst    => P.Get (Positions (Container)'Old, Before) - 1,
                   Offset => -1)

            --  The element previously at Position is now before Before

            and Element_Logic_Equal
                  (Element
                     (Model (Container),
                      P.Get (Positions (Container), Before) - 1),
                   Element
                     (Model (Container)'Old,
                      P.Get (Positions (Container)'Old, Position)))

            --  Cursors from Container continue designating the same elements

            and Mapping_Preserved
                  (M_Left  => Model (Container)'Old,
                   M_Right => Model (Container),
                   P_Left  => Positions (Container)'Old,
                   P_Right => Positions (Container)));

   function First (Container : List) return Cursor with
     Global         => null,
     Contract_Cases =>
       (Length (Container) = 0 =>
          First'Result = No_Element,

        others =>
          Has_Element (Container, First'Result)
            and P.Get (Positions (Container), First'Result) = 1);

   function First_Element (Container : List) return Element_Type with
     Global => null,
     Pre    => not Is_Empty (Container),
     Post   => Element_Logic_Equal
       (First_Element'Result, M.Get (Model (Container), 1));

   function Last (Container : List) return Cursor with
     Global         => null,
     Contract_Cases =>
       (Length (Container) = 0 =>
          Last'Result = No_Element,

        others =>
          Has_Element (Container, Last'Result)
            and P.Get (Positions (Container), Last'Result) =
                  Length (Container));

   function Last_Element (Container : List) return Element_Type with
     Global => null,
     Pre    => not Is_Empty (Container),
     Post   => Element_Logic_Equal
       (Last_Element'Result, M.Get (Model (Container), Length (Container)));

   function Next (Container : List; Position : Cursor) return Cursor with
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

   procedure Next (Container : List; Position : in out Cursor) with
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

   function Previous (Container : List; Position : Cursor) return Cursor with
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

   procedure Previous (Container : List; Position : in out Cursor) with
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

   function Find
     (Container : List;
      Item      : Element_Type;
      Position  : Cursor := No_Element) return Cursor
   with
     Global         => null,
     Pre            =>
       Has_Element (Container, Position) or else Position = No_Element,
     Contract_Cases =>

       --  If Item is not contained in Container after Position, Find returns
       --  No_Element.

       (not M.Contains
              (Container => Model (Container),
               Fst       =>
                 (if Position = No_Element then
                     1
                  else
                     P.Get (Positions (Container), Position)),
               Lst       => Length (Container),
               Item      => Item)
        =>
          Find'Result = No_Element,

        --  Otherwise, Find returns a valid cursor in Container

        others =>
          P.Has_Key (Positions (Container), Find'Result)

            --  The element designated by the result of Find is Item

            and Element
                  (Model (Container),
                   P.Get (Positions (Container), Find'Result)) = Item

            --  The result of Find is located after Position

            and (if Position /= No_Element then
                    P.Get (Positions (Container), Find'Result) >=
                    P.Get (Positions (Container), Position))

            --  It is the first occurrence of Item in this slice

            and not M.Contains
                      (Container => Model (Container),
                       Fst       =>
                         (if Position = No_Element then
                             1
                          else
                             P.Get (Positions (Container), Position)),
                       Lst       =>
                         P.Get (Positions (Container), Find'Result) - 1,
                       Item      => Item));

   function Reverse_Find
     (Container : List;
      Item      : Element_Type;
      Position  : Cursor := No_Element) return Cursor
   with
     Global         => null,
     Pre            =>
       Has_Element (Container, Position) or else Position = No_Element,
     Contract_Cases =>

       --  If Item is not contained in Container before Position, Find returns
       --  No_Element.

       (not M.Contains
              (Container => Model (Container),
               Fst       => 1,
               Lst       =>
                 (if Position = No_Element then
                     Length (Container)
                  else
                     P.Get (Positions (Container), Position)),
               Item      => Item)
        =>
          Reverse_Find'Result = No_Element,

        --  Otherwise, Find returns a valid cursor in Container

        others =>
          P.Has_Key (Positions (Container), Reverse_Find'Result)

            --  The element designated by the result of Find is Item

            and Element
                  (Model (Container),
                   P.Get (Positions (Container), Reverse_Find'Result)) = Item

            --  The result of Find is located before Position

            and (if Position /= No_Element then
                    P.Get (Positions (Container), Reverse_Find'Result) <=
                    P.Get (Positions (Container), Position))

            --  It is the last occurrence of Item in this slice

            and not M.Contains
                      (Container => Model (Container),
                       Fst       =>
                         P.Get (Positions (Container),
                                Reverse_Find'Result) + 1,
                       Lst       =>
                         (if Position = No_Element then
                             Length (Container)
                          else
                             P.Get (Positions (Container), Position)),
                       Item      => Item));

   function Contains
     (Container : List;
      Item      : Element_Type) return Boolean
   with
     Global => null,
     Post   =>
       Contains'Result = M.Contains (Container => Model (Container),
                                     Fst       => 1,
                                     Lst       => Length (Container),
                                     Item      => Item);

   function Has_Element
     (Container : List;
      Position  : Cursor) return Boolean
   with
     Global => null,
     Post   =>
       Has_Element'Result = P.Has_Key (Positions (Container), Position);
   pragma Annotate (GNATprove, Inline_For_Proof, Has_Element);

   generic
      with function "<" (Left, Right : Element_Type) return Boolean is <>;

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

   package Generic_Sorting with SPARK_Mode, Always_Terminates is

      --  Contracts in this unit are meant for analysis only, not for run-time
      --  checking.

      pragma Assertion_Policy (Ignore);

      package Formal_Model with Ghost is

         --------------------------
         -- Instantiation Checks --
         --------------------------

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

         function M_Elements_Sorted (Container : M.Sequence) return Boolean
         with
           Global => null,
           Post   =>
             M_Elements_Sorted'Result =
               (for all I in 1 .. M.Last (Container) =>
                 (for all J in I .. M.Last (Container) =>
                   not (Element (Container, J) < Element (Container, I))));
         pragma Annotate (GNATprove, Inline_For_Proof, M_Elements_Sorted);

      end Formal_Model;
      use Formal_Model;

      function Is_Sorted (Container : List) return Boolean with
        Global => null,
        Post   => Is_Sorted'Result = M_Elements_Sorted (Model (Container));

      procedure Sort (Container : in out List) with
        Global => null,
        Post   =>
          Length (Container) = Length (Container)'Old
            and M_Elements_Sorted (Model (Container))
            and M_Elements_Included
                  (Left  => Model (Container)'Old,
                   L_Lst => Length (Container),
                   Right => Model (Container),
                   R_Lst => Length (Container))
            and M_Elements_Included
                  (Left  => Model (Container),
                   L_Lst => Length (Container),
                   Right => Model (Container)'Old,
                   R_Lst => Length (Container));

      procedure Merge (Target : in out List; Source : in out List) with
      --  Target and Source should not be aliased
        Global => null,
        Pre    => Length (Source) <= Target.Capacity - Length (Target),
        Post   =>
          Length (Target) = Length (Target)'Old + Length (Source)'Old
            and Length (Source) = 0
            and (if M_Elements_Sorted (Model (Target)'Old)
                   and M_Elements_Sorted (Model (Source)'Old)
                 then
                    M_Elements_Sorted (Model (Target)))
            and M_Elements_Included
                  (Left  => Model (Target)'Old,
                   L_Lst => Length (Target)'Old,
                   Right => Model (Target),
                   R_Lst => Length (Target))
            and M_Elements_Included
                  (Left  => Model (Source)'Old,
                   L_Lst => Length (Source)'Old,
                   Right => Model (Target),
                   R_Lst => Length (Target))
            and M_Elements_In_Union
                  (Model (Target),
                   Model (Source)'Old,
                   Model (Target)'Old);
   end Generic_Sorting;

   ------------------------------------------------------------------
   -- Additional Expression Functions For Iteration and Aggregates --
   ------------------------------------------------------------------

   function Aggr_Capacity (Container : List) return Count_Type is
      (Container.Capacity)
   with
     Ghost,
     Global   => null,
     Annotate => (GNATprove, Inline_For_Proof),
     Annotate => (GNATprove, Container_Aggregates, "Capacity");

   function Aggr_And_Iter_Model (Container : List) return M.Sequence is
      (Model (Container))
   with
     Ghost,
     Global   => null,
     Annotate => (GNATprove, Inline_For_Proof),
     Annotate => (GNATprove, Iterable_For_Proof, "Model"),
     Annotate => (GNATprove, Container_Aggregates, "Model");

private
   pragma SPARK_Mode (Off);

   type Node_Type is record
      Prev    : Count_Type'Base := -1;
      Next    : Count_Type;
      Element : aliased Element_Type;
   end record;

   function "=" (L, R : Node_Type) return Boolean is abstract;

   type Node_Array is array (Count_Type range <>) of Node_Type;
   function "=" (L, R : Node_Array) return Boolean is abstract;

   type List (Capacity : Count_Type) is record
      Free   : Count_Type'Base := -1;
      Length : Count_Type := 0;
      First  : Count_Type := 0;
      Last   : Count_Type := 0;
      Nodes  : Node_Array (1 .. Capacity);
   end record;

   function Empty_List (Capacity : Count_Type := 10) return List is
     ((Capacity, others => <>));

end SPARK.Containers.Formal.Doubly_Linked_Lists;
