--
--  Copyright (C) 2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with SPARK.Big_Integers;     use SPARK.Big_Integers;
with SPARK.Containers.Functional.Infinite_Sequences;
with SPARK.Containers.Functional.Maps;
with SPARK.Containers.Functional.Trees;
with SPARK.Containers.Types; use SPARK.Containers.Types;

private with SPARK.Containers.Formal.Ordered_Maps;

generic
   type Way_Type is (<>);
   type Element_Type is private;

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

package SPARK.Containers.Formal.Trees with SPARK_Mode, Always_Terminates
is
   pragma Annotate (CodePeer, Skip_Analysis);

   type Tree (Capacity : Count_Type) is private
   with Default_Initial_Condition => Is_Empty (Tree);

   type Cursor is record
      Node : Count_Type := 0;
   end record;

   No_Element : constant Cursor := Cursor'(Node => 0);

   function Node_Count (Container : Tree) return Count_Type
   with
     Global => null,
     Post   => (SPARKlib_Full => Node_Count'Result <= Container.Capacity);

   pragma Unevaluated_Use_Of_Old (Allow);

   package Formal_Model
     with Ghost => SPARKlib_Logic
   is

      package Count_Type_Conversions is new
        Signed_Conversions (Int => Count_Type);

      function Big (J : Count_Type) return Big_Integer
      renames Count_Type_Conversions.To_Big_Integer;

      package M is new
        SPARK.Containers.Functional.Trees
          (Way_Type      => Way_Type,
           Element_Type  => Element_Type,
           "="           => "=",
           Eq_Reflexive  => Eq_Reflexive,
           Eq_Symmetric  => Eq_Symmetric,
           Eq_Transitive => Eq_Transitive);

      function Is_Empty (Container : M.Tree) return Boolean renames M.Is_Empty;

      subtype Non_Empty_Tree is M.Tree
      with Predicate => not Is_Empty (Non_Empty_Tree);

      package K is new
        SPARK.Containers.Functional.Infinite_Sequences
          (Way_Type,
           Use_Logical_Equality => True);
      subtype Path is K.Sequence;
      use type K.Sequence;

      package R is new
        SPARK.Containers.Functional.Maps
          (Key_Type     => Path,
           Element_Type => Non_Empty_Tree,
           "="          => M."=");

      package P is new SPARK.Containers.Functional.Maps (Cursor, Path);

      function Parent (P : Path) return Path
      with
        Global => null,
        Pre    => K.Length (P) > 0,
        Post   =>
          (SPARKlib_Full =>
             K.Length (Parent'Result) = K.Length (P) - 1
             and then K.Equal_Prefix (Parent'Result, P));

      function Subtrees_Preserved_Except
        (R_Left : R.Map; R_Right : R.Map; Prefix : Path) return Boolean
      is

         --  Paths of R_Left that are not inside the subtree rooted at Prefix
         --  are in R_Right.

         ((for all P of R_Left =>
             (if not (Prefix <= P) then R.Has_Key (R_Right, P)))

          --  Among those paths, those that are not prefixes of Prefix
          --  designate the same subtree.

          and then
            (for all P of R_Left =>
               (if not (Prefix <= P) and not (P < Prefix)
                then
                  M.Tree_Logic_Equal (R.Get (R_Left, P), R.Get (R_Right, P))))

          --  Strict prefixes of Prefix have the same element and the same
          --  children, except the one on the path.

          and then
            (for all P of R_Left =>
               (if P < Prefix
                then
                  M.Element_Logic_Equal
                    (M.Get (R.Get (R_Left, P)), M.Get (R.Get (R_Right, P)))))

          and then
            (for all P of R_Left =>
               (if P < Prefix
                then
                  (for all W in Way_Type =>
                     (if W /= K.Get (Prefix, K.Last (P) + 1)
                      then
                        M.Tree_Logic_Equal
                          (M.Child (R.Get (R_Left, P), W),
                           M.Child (R.Get (R_Right, P), W)))))))
      with Ghost => SPARKlib_Full;

      function Same_Paths (P_Left : P.Map; P_Right : P.Map) return Boolean
      is
         --  Same as P."<=" but using logical equality

         (for all C of P_Left =>
            P.Has_Key (P_Right, C)
            and then K.Logical_Eq (P.Get (P_Right, C), P.Get (P_Left, C)))
      with Ghost => SPARKlib_Full;

      function Same_Paths_Except
        (P_Left : P.Map; P_Right : P.Map; Prefix : Path) return Boolean
      is
         --  Same as above, but excluding cursors that are inside the subtree
         --  rooted at Prefix.

         (for all C of P_Left =>
            (if not (Prefix <= P.Get (P_Left, C))
             then
               P.Has_Key (P_Right, C)
               and then K.Logical_Eq (P.Get (P_Right, C), P.Get (P_Left, C))))
      with Ghost => SPARKlib_Full;

      function Paths_Included_Except
        (P_Left : P.Map; P_Right : P.Map; Prefix : Path) return Boolean
      is
         --  Cursors of P_Left that are not inside the subtree rooted at Prefix
         --  are valid in P_Right.

         (for all C of P_Left =>
            (if not (Prefix <= P.Get (P_Left, C)) then P.Has_Key (P_Right, C)))
      with Ghost => SPARKlib_Full;

      function Paths_Included_Except
        (P_Left : P.Map; P_Right : P.Map; Prefix : Path; Way : Way_Type)
         return Boolean
      is
         --  Same as above, by for Add (Prefix, Way)

         (for all C of P_Left =>
            (if not (Prefix < P.Get (P_Left, C))
               or else K.Get (P.Get (P_Left, C), K.Last (Prefix) + 1) /= Way
             then P.Has_Key (P_Right, C)))
      with Ghost => SPARKlib_Full;

      function Paths_Extended
        (P_Left : P.Map; P_Right : P.Map; Prefix : Path; Way : Way_Type)
         return Boolean
      is
         --  Cursors of P_Left whose paths are prefixed by Prefix have their
         --  prefix extended by Way in P_Right.

         (for all C of P_Left =>
            (if Prefix <= P.Get (P_Left, C)
             then
               P.Has_Key (P_Right, C)
               and then
                 K.Length (P.Get (P_Right, C))
                 = K.Length (P.Get (P_Left, C)) + 1
               and then
                 K.Range_Equal
                   (Left  => P.Get (P_Left, C),
                    Right => P.Get (P_Right, C),
                    Fst   => 1,
                    Lst   => K.Length (Prefix))
               and then
                 K.Range_Shifted
                   (Left   => P.Get (P_Left, C),
                    Right  => P.Get (P_Right, C),
                    Fst    => K.Length (Prefix) + 1,
                    Lst    => K.Last (P.Get (P_Left, C)),
                    Offset => 1)
               and then
                 K.Get (P.Get (P_Right, C), K.Length (Prefix) + 1) = Way))
      with Ghost => SPARKlib_Full;

      function Model (T : Tree) return M.Tree
      with
        --  The high level model of a formal tree is a functional tree

        Global => null,
        Post   =>
          (SPARKlib_Full => M.Count (Model'Result) = Big (Node_Count (T)));

      function Subtrees (T : Tree) return R.Map
      with
        --  Map a path to the subtree rooted at this path in T if any.
        --  The definition is given inductively using Parent.
        --  We do not assume that this map includes all children. It is in
        --  general not necessary. It is assumed specifically when Child is
        --  called.

        Global => null,
        Post   =>
          (SPARKlib_Full =>
             R.Length (Subtrees'Result) = Big (Node_Count (T))
             and then
               (if M.Is_Empty (Model (T))
                then R.Is_Empty (Subtrees'Result)
                else
                  R.Has_Key (Subtrees'Result, K.Empty_Sequence)
                  and then
                    M.Tree_Logic_Equal
                      (R.Get (Subtrees'Result, K.Empty_Sequence), Model (T)))
             and then
               (for all P of Subtrees'Result =>
                  (if K.Length (P) > 0
                   then R.Has_Key (Subtrees'Result, Parent (P))))
             and then
               (for all P of Subtrees'Result =>
                  (if K.Length (P) > 0
                   then
                     M.Tree_Logic_Equal
                       (R.Get (Subtrees'Result, P),
                        M.Child
                          (R.Get (Subtrees'Result, Parent (P)),
                           K.Get (P, K.Last (P)))))));

      function Paths (T : Tree) return P.Map
      with
        --  Mapping from cursors directly to paths. There is not one logical
        --  iteration order on trees, so we don't go through a sequence like in
        --  other containers.

        Global => null,
        Post   =>
          (SPARKlib_Full =>
             P.Length (Paths'Result) = Big (Node_Count (T))
             and then not P.Has_Key (Paths'Result, No_Element)
             and then
               (for all I of Paths'Result =>
                  R.Has_Key (Subtrees (T), P.Get (Paths'Result, I))
                  and then
                    (for all J of Paths'Result =>
                       (if K.Logical_Eq
                             (P.Get (Paths'Result, I), P.Get (Paths'Result, J))
                        then I = J))));

      function Get_Path (T : Tree; C : Cursor) return Path
      is (P.Get (Paths (T), C))
      with Pre => P.Has_Key (Paths (T), C);

      function Get_Subtree (T : Tree; C : Cursor) return Non_Empty_Tree
      is (R.Get (Subtrees (T), Get_Path (T, C)))
      with Pre => P.Has_Key (Paths (T), C);

      function Get_Parent_Subtree (T : Tree; C : Cursor) return Non_Empty_Tree
      is (R.Get (Subtrees (T), Parent (Get_Path (T, C))))
      with
        Pre =>
          P.Has_Key (Paths (T), C) and then K.Length (Get_Path (T, C)) > 0;

   end Formal_Model;
   use Formal_Model;
   use type M.Tree;
   use type K.Sequence;

   ---------------------
   -- Query Functions --
   ---------------------

   function "=" (Left, Right : Tree) return Boolean
   with
     Global => null,
     Post   => (SPARKlib_Full => "="'Result = (Model (Left) = Model (Right)));

   function Node_Count (Container : Tree; Position : Cursor) return Count_Type
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => Has_Element (Container, Position)),
     Post   =>
       (SPARKlib_Full =>
          Big (Node_Count'Result)
          = M.Count (Get_Subtree (Container, Position)));
   --  Count the number of nodes in the subtree rooted at Position

   function Is_Empty (Container : Tree) return Boolean
   with
     Global => null,
     Post   =>
       (SPARKlib_Full => Is_Empty'Result = M.Is_Empty (Model (Container)));

   function Is_Root (Container : Tree; Position : Cursor) return Boolean
   with
     Global => null,
     Post   =>
       (SPARKlib_Full =>
          Is_Root'Result
          = (Has_Element (Container, Position)
             and then K.Length (Get_Path (Container, Position)) = 0));

   function Is_Leaf (Container : Tree; Position : Cursor) return Boolean
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => Has_Element (Container, Position)),
     Post   =>
       (SPARKlib_Full =>
          Is_Leaf'Result
          = (for all W in Way_Type =>
               M.Is_Empty (M.Child (Get_Subtree (Container, Position), W))));
   --  Query if the node at Position has no child nodes

   function Is_Ancestor_Of
     (Container : Tree; Parent : Cursor; Position : Cursor) return Boolean
   with
     Global => null,
     Pre    =>
       (SPARKlib_Defensive =>
          Has_Element (Container, Parent)
          and Has_Element (Container, Position)),
     Post   =>
       (SPARKlib_Full =>
          Is_Ancestor_Of'Result
          = (Get_Path (Container, Parent) < Get_Path (Container, Position)));
   --  Query if the node at Parent is an ancestor of the node at Position

   function In_Subtree
     (Container : Tree; Position : Cursor; Subtree_Root : Cursor)
      return Boolean
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => Has_Element (Container, Subtree_Root)),
     Post   =>
       (SPARKlib_Full =>
          In_Subtree'Result
          = (Has_Element (Container, Position)
             and then
               Get_Path (Container, Subtree_Root)
               <= Get_Path (Container, Position)));
   --  Query if the node at Position is in the subtree rooted by the node at
   --  Subtree_Root.

   function Depth (Container : Tree; Position : Cursor) return Count_Type
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => Has_Element (Container, Position)),
     Post   =>
       (SPARKlib_Full =>
          Big (Depth'Result) = K.Length (Get_Path (Container, Position)));
   --  Get the number of ancestor nodes of the node at Position

   function Has_Element (Container : Tree; Position : Cursor) return Boolean
   with
     Global => null,
     Post   =>
       (SPARKlib_Full =>
          Has_Element'Result = (P.Has_Key (Paths (Container), Position)));

   function Element (Container : Tree; Position : Cursor) return Element_Type
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => Has_Element (Container, Position)),
     Post   =>
       (SPARKlib_Full =>
          M.Element_Logic_Equal
            (Element'Result, M.Get (Get_Subtree (Container, Position))));

   function Root (Container : Tree) return Cursor
   with
     Global => null,
     Post   =>
       (SPARKlib_Full =>
          (if M.Is_Empty (Model (Container))
           then Root'Result = No_Element
           else
             P.Has_Key (Paths (Container), Root'Result)
             and then
               K.Logical_Eq
                 (Get_Path (Container, Root'Result), K.Empty_Sequence)));

   function Direction (Container : Tree; Position : Cursor) return Way_Type
   with
     Global => null,
     Pre    =>
       (SPARKlib_Defensive =>
          Has_Element (Container, Position)
          and not Is_Root (Container, Position)),
     Post   =>
       (SPARKlib_Full =>
          Direction'Result
          = K.Get
              (Get_Path (Container, Position),
               K.Last (Get_Path (Container, Position))));
   --  Get the branch that is taken to get to the node at Position from its
   --  parent.
   --
   --  This is only meaningful for non-root nodes.

   function Has_Child
     (Container : Tree; Parent : Cursor; Way : Way_Type) return Boolean
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => Has_Element (Container, Parent)),
     Post   =>
       (SPARKlib_Full =>
          Has_Child'Result
          = (not M.Is_Empty (M.Child (Get_Subtree (Container, Parent), Way))));
   --  Query if the node at Position has a child in the branch designated by
   --  Way.

   -------------------------
   -- Traversal Functions --
   -------------------------

   function Parent (Container : Tree; Position : Cursor) return Cursor
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => Has_Element (Container, Position)),
     Post   =>
       (SPARKlib_Full =>
          (if K.Length (Get_Path (Container, Position)) = 0
           then Parent'Result = No_Element
           else
             Has_Element (Container, Parent'Result)
             and then
               K.Logical_Eq
                 (Get_Path (Container, Parent'Result),
                  Parent (Get_Path (Container, Position)))));
   --  Get the immediate ancestor of the node at Position.
   --
   --  No_Element is returned only for the root node, which has no ancestors.

   function Child
     (Container : Tree; Position : Cursor; Way : Way_Type) return Cursor
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => Has_Element (Container, Position)),
     Post   =>
       (SPARKlib_Full =>
          (declare
             TC : constant M.Tree :=
               M.Child (Get_Subtree (Container, Position), Way);
           begin
             (if M.Is_Empty (TC)
              then Child'Result = No_Element
              else
                Has_Element (Container, Child'Result)
                and then
                  K.Logical_Eq
                    (Get_Path (Container, Position),
                     Parent (Get_Path (Container, Child'Result)))
                and then
                  Get_Path (Container, Position)
                  < Get_Path (Container, Child'Result)
                and then
                  K.Length (Get_Path (Container, Position)) + 1
                  = K.Length (Get_Path (Container, Child'Result))
                and then
                  K.Get
                    (Get_Path (Container, Child'Result),
                     K.Last (Get_Path (Container, Child'Result)))
                  = Way
                and then
                  M.Tree_Logic_Equal
                    (Get_Subtree (Container, Child'Result), TC))));
   --  Get the immediate child of the node at Position in the branch designated
   --  by Way.
   --
   --  No_Element is returned if the node at Position has no child at the
   --  designated Way.

   function First_Child (Container : Tree; Position : Cursor) return Cursor
   with
     Global         => null,
     Pre            =>
       (SPARKlib_Defensive => Has_Element (Container, Position)),
     Contract_Cases =>
       (SPARKlib_Full =>
          (Is_Leaf (Container, Position) => First_Child'Result = No_Element,
           others                        =>
             --  The returned cursor designates a child subtree of the subtree
             --  at Position.

             Has_Element (Container, First_Child'Result)
             and then
               K.Logical_Eq
                 (Get_Path (Container, Position),
                  Parent (Get_Path (Container, First_Child'Result)))
             and then
               Get_Path (Container, Position)
               < Get_Path (Container, First_Child'Result)
             and then
               K.Length (Get_Path (Container, First_Child'Result))
               = K.Length (Get_Path (Container, Position)) + 1
             and then
               M.Tree_Logic_Equal
                 (Get_Subtree (Container, First_Child'Result),
                  M.Child
                    (Get_Subtree (Container, Position),
                     Direction (Container, First_Child'Result)))

             --  The returned cursor designates the first child. That is, there
             --  are no children of Position with a lower direction.

             and then
               (for all W in Way_Type =>
                  (if W < Direction (Container, First_Child'Result)
                   then
                     M.Is_Empty
                       (M.Child (Get_Subtree (Container, Position), W))))));

   function Last_Child (Container : Tree; Position : Cursor) return Cursor
   with
     Global         => null,
     Pre            =>
       (SPARKlib_Defensive => Has_Element (Container, Position)),
     Contract_Cases =>
       (SPARKlib_Full =>
          (Is_Leaf (Container, Position) => Last_Child'Result = No_Element,
           others                        =>
             --  The returned cursor designates a child subtree of the subtree
             --  at Position.

             Has_Element (Container, Last_Child'Result)
             and then
               K.Logical_Eq
                 (Get_Path (Container, Position),
                  Parent (Get_Path (Container, Last_Child'Result)))
             and then
               Get_Path (Container, Position)
               < Get_Path (Container, Last_Child'Result)
             and then
               K.Length (Get_Path (Container, Last_Child'Result))
               = K.Length (Get_Path (Container, Position)) + 1
             and then
               M.Tree_Logic_Equal
                 (Get_Subtree (Container, Last_Child'Result),
                  M.Child
                    (Get_Subtree (Container, Position),
                     Direction (Container, Last_Child'Result)))

             --  The returned cursor designates the last child. That is, there
             --  are no children of Position with a higher direction.

             and then
               (for all W in Way_Type =>
                  (if W > Direction (Container, Last_Child'Result)
                   then
                     M.Is_Empty
                       (M.Child (Get_Subtree (Container, Position), W))))));

   function Next_Sibling (Container : Tree; Position : Cursor) return Cursor
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => Has_Element (Container, Position)),
     Post   =>
       (SPARKlib_Full =>
          (
           --  The root has no siblings

           if Is_Root (Container, Position)
           then Next_Sibling'Result = No_Element

           --  No_Element is returned if there are no siblings with a
           --  higher direction than the node at Position.

           elsif (for all W in Way_Type =>
                    (if W > Direction (Container, Position)
                     then
                       M.Is_Empty
                         (M.Child
                            (Get_Parent_Subtree (Container, Position), W))))
           then Next_Sibling'Result = No_Element

           --  The returned cursor designates a sibling of the node at
           --  Position. That is, they have the same parent.

           else
             Has_Element (Container, Next_Sibling'Result)
             and then
               K.Length (Get_Path (Container, Next_Sibling'Result))
               = K.Length (Get_Path (Container, Position))
             and then
               K.Range_Equal
                 (Get_Path (Container, Position),
                  Get_Path (Container, Next_Sibling'Result),
                  1,
                  K.Last (Get_Path (Container, Position)) - 1)
             and then
               K.Logical_Eq
                 (Parent (Get_Path (Container, Position)),
                  Parent (Get_Path (Container, Next_Sibling'Result)))
             and then
               M.Tree_Logic_Equal
                 (Get_Subtree (Container, Next_Sibling'Result),
                  M.Child
                    (Get_Parent_Subtree (Container, Position),
                     Direction (Container, Next_Sibling'Result)))

             --  The returned cursor designates the next sibling. That is,
             --  there are no other siblings with a direction between the node
             --  at Position and the returned cursor.

             and then
               Direction (Container, Next_Sibling'Result)
               > Direction (Container, Position)
             and then
               (for all W in Way_Type =>
                  (if W > Direction (Container, Position)
                     and W < Direction (Container, Next_Sibling'Result)
                   then
                     M.Is_Empty
                       (M.Child
                          (Get_Parent_Subtree (Container, Position), W))))));

   function Previous_Sibling
     (Container : Tree; Position : Cursor) return Cursor
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => Has_Element (Container, Position)),
     Post   =>
       (SPARKlib_Full =>
          (
           --  The root has no siblings

           if Is_Root (Container, Position)
           then Previous_Sibling'Result = No_Element

           --  No_Element is returned if there are no siblings with a
           --  lower direction than the node at Position.

           elsif (for all W in Way_Type =>
                    (if W < Direction (Container, Position)
                     then
                       M.Is_Empty
                         (M.Child
                            (Get_Parent_Subtree (Container, Position), W))))
           then Previous_Sibling'Result = No_Element

           --  The returned cursor designates a sibling of the node at
           --  Position. That is, they have the same parent.

           else
             Has_Element (Container, Previous_Sibling'Result)
             and then
               K.Length (Get_Path (Container, Previous_Sibling'Result))
               = K.Length (Get_Path (Container, Position))
             and then
               K.Range_Equal
                 (Get_Path (Container, Position),
                  Get_Path (Container, Previous_Sibling'Result),
                  1,
                  K.Last (Get_Path (Container, Position)) - 1)
             and then
               K.Logical_Eq
                 (Parent (Get_Path (Container, Position)),
                  Parent (Get_Path (Container, Previous_Sibling'Result)))
             and then
               M.Tree_Logic_Equal
                 (Get_Subtree (Container, Previous_Sibling'Result),
                  M.Child
                    (Get_Parent_Subtree (Container, Position),
                     Direction (Container, Previous_Sibling'Result)))

             --  The returned cursor designates the previous sibling. That is,
             --  there are no other siblings with a direction between the node
             --  at Position and the returned cursor.

             and then
               Direction (Container, Previous_Sibling'Result)
               < Direction (Container, Position)
             and then
               (for all W in Way_Type =>
                  (if W > Direction (Container, Previous_Sibling'Result)
                     and W < Direction (Container, Position)
                   then
                     M.Is_Empty
                       (M.Child
                          (Get_Parent_Subtree (Container, Position), W))))));

   ---------------------------
   -- Constructor functions --
   ---------------------------

   function Empty_Tree (Capacity : Count_Type := 10) return Tree
   with
     Global => null,
     Post   =>
       (SPARKlib_Full =>
          Is_Empty (Empty_Tree'Result)
          and then Empty_Tree'Result.Capacity = Capacity);

   -----------------------
   -- Tree manipulation --
   -----------------------

   procedure Clear (Container : out Tree)
   with
     Global => null,
     Post   => (SPARKlib_Full => (M.Is_Empty (Model (Container))));

   procedure Assign (Target : in out Tree; Source : Tree)
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => Target.Capacity >= Node_Count (Source)),
     Post   =>
       (SPARKlib_Full => M.Tree_Logic_Equal (Model (Target), Model (Source)));

   procedure Move (Target : in out Tree; Source : in out Tree)
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => Target.Capacity >= Node_Count (Source)),
     Post   =>
       (SPARKlib_Full =>
          M.Tree_Logic_Equal (Model (Target), Model (Source'Old))
          and then M.Is_Empty (Model (Source)));

   function Copy (Source : Tree; Capacity : Count_Type := 0) return Tree
   with
     Global => null,
     Pre    =>
       (SPARKlib_Defensive =>
          Capacity = 0 or else Capacity >= Source.Capacity),
     Post   =>
       (SPARKlib_Full =>
          M.Tree_Logic_Equal (Model (Copy'Result), Model (Source))
          and then
            (if Capacity = 0
             then Copy'Result.Capacity = Source.Capacity
             else Copy'Result.Capacity = Capacity));

   procedure Insert_Root (Container : in out Tree; New_Item : Element_Type)
   with
     Global => null,
     Pre    =>
       (SPARKlib_Defensive =>
          Is_Empty (Container) and then Container.Capacity > 0),
     Post   =>
       (SPARKlib_Full =>
          not M.Is_Empty (Model (Container))
          and then Node_Count (Container) = 1
          and then
            M.Element_Logic_Equal
              (M.Get (Model (Container)), M.Copy_Element (New_Item))
          and then
            (for all W in Way_Type =>
               M.Is_Empty (M.Child (Model (Container), W)))
          and then (for all C of Paths (Container) => C = Root (Container)));
   --  Insert the root node into an empty container

   procedure Insert_Child
     (Container : in out Tree;
      New_Item  : Element_Type;
      Parent    : Cursor;
      Way       : Way_Type)
   with
     Global => null,
     Pre    =>
       (SPARKlib_Defensive =>
          Has_Element (Container, Parent)
          and then Node_Count (Container) < Container.Capacity
          and then not Has_Child (Container, Parent, Way)),
     Post   =>
       (SPARKlib_Full =>
          Node_Count (Container) = Node_Count (Container)'Old + 1

          --  A tree with a single root has been inserted as a child of Parent

          and then
            not M.Is_Empty (M.Child (Get_Subtree (Container, Parent), Way))
          and then
            M.Element_Logic_Equal
              (M.Get (M.Child (Get_Subtree (Container, Parent), Way)),
               M.Copy_Element (New_Item))
          and then
            (for all W in Way_Type =>
               M.Is_Empty
                 (M.Child (M.Child (Get_Subtree (Container, Parent), Way), W)))

          --  Subtrees are preserved except for the path leading to Parent and
          --  Parent itself

          and then
            Subtrees_Preserved_Except
              (Subtrees (Container'Old),
               Subtrees (Container),
               Get_Path (Container'Old, Parent))

          --  The subtree designated by Parent is unchanged except for the
          --  branch designated by Way.

          and then
            M.Element_Logic_Equal
              (M.Get (Get_Subtree (Container, Parent)),
               M.Get (Get_Subtree (Container'Old, Parent)))
          and then
            (for all W in Way_Type =>
               (if W /= Way
                then
                  M.Tree_Logic_Equal
                    (M.Child (Get_Subtree (Container, Parent), W),
                     M.Child (Get_Subtree (Container'Old, Parent), W))))

          --  Valid cursors stay valid and continue designating the same path

          and then Same_Paths (Paths (Container'Old), Paths (Container))
          and then
            Paths_Included_Except
              (Paths (Container),
               Paths (Container'Old),
               Get_Path (Container'Old, Parent),
               Way)
          and then
            P.Keys_Included_Except
              (Paths (Container),
               Paths (Container'Old),
               Child (Container, Parent, Way)));
   --  Insert a new node as the child of the node at Position in the branch
   --  designated by Way.

   procedure Insert_Parent
     (Container : in out Tree;
      New_Item  : Element_Type;
      Position  : Cursor;
      Way       : Way_Type)
   with
     Global => null,
     Pre    =>
       (SPARKlib_Defensive =>
          Has_Element (Container, Position)
          and then Node_Count (Container) < Container.Capacity),
     Post   =>
       (SPARKlib_Full =>
          Node_Count (Container) = Node_Count (Container)'Old + 1

          --  A new tree has been inserted which has the subtree at Position
          --  as a child in the branch designated by Way.

          and then
            M.Element_Logic_Equal
              (M.Get (Get_Parent_Subtree (Container, Position)),
               M.Copy_Element (New_Item))
          and then
            M.Tree_Logic_Equal
              (M.Child (Get_Parent_Subtree (Container, Position), Way),
               Get_Subtree (Container'Old, Position))
          and then
            (for all W in Way_Type =>
               (if W /= Way
                then
                  M.Is_Empty
                    (M.Child (Get_Parent_Subtree (Container, Position), W))))

          --  If the node at Position was not the root, then the subtree of
          --  the old parent of Position is preserved, except for the branch
          --  leading to Position which now contains the new tree.

          and then
            (if K.Length (Get_Path (Container'Old, Position)) > 0
             then
               M.Element_Logic_Equal
                 (M.Get
                    (Get_Subtree
                       (Container, Parent (Container'Old, Position))),
                  M.Get (Get_Parent_Subtree (Container'Old, Position)))

               and then
                 M.Tree_Logic_Equal
                   (Get_Parent_Subtree (Container, Position),
                    M.Child
                      (Get_Subtree
                         (Container, Parent (Container'Old, Position)),
                       K.Get
                         (Get_Path (Container'Old, Position),
                          K.Last (Get_Path (Container'Old, Position)))))
               and then
                 (for all W in Way_Type =>
                    (if W
                       /= K.Get
                            (Get_Path (Container'Old, Position),
                             K.Last (Get_Path (Container'Old, Position)))
                     then
                       M.Tree_Logic_Equal
                         (M.Child
                            (Get_Subtree
                               (Container, Parent (Container'Old, Position)),
                             W),
                          M.Child
                            (Get_Parent_Subtree (Container'Old, Position),
                             W)))))

          --  Subtrees are preserved except for those in the path leading to
          --  (and including) the old parent of the node at Position.

          and then
            (if K.Length (Get_Path (Container'Old, Position)) > 0
             then
               Subtrees_Preserved_Except
                 (Subtrees (Container'Old),
                  Subtrees (Container),
                  Parent (Get_Path (Container'Old, Position))))

          --  Subtrees that are in the subtree rooted at Position are
          --  preserved.

          and then
            (for all C of Paths (Container'Old) =>
               (if Get_Path (Container'Old, Position)
                  <= Get_Path (Container'Old, C)
                then
                  M.Tree_Logic_Equal
                    (Get_Subtree (Container, C),
                     Get_Subtree (Container'Old, C))))

          --  Valid cursors stay valid and continue designating the same
          --  path except for cursors in the subtree rooted at Position
          --  which now have an extra ancestor in their path.

          and then P.Keys_Included (Paths (Container'Old), Paths (Container))
          and then
            P.Keys_Included_Except
              (Paths (Container),
               Paths (Container'Old),
               Parent (Container, Position))

          and then
            Same_Paths_Except
              (Paths (Container'Old),
               Paths (Container),
               Get_Path (Container'Old, Position))

          and then
            Paths_Extended
              (Paths (Container'Old),
               Paths (Container),
               Get_Path (Container'Old, Position),
               Way)

          and then
            P.Keys_Included_Except
              (Paths (Container),
               Paths (Container'Old),
               Parent (Container, Position))

          --  The new parent cursor of Position designates Position's
          --  previous path.

          and then Has_Element (Container, Parent (Container, Position))

          and then
            K.Logical_Eq
              (Get_Path (Container, Parent (Container, Position)),
               Get_Path (Container'Old, Position)));
   --  Insert a new node as the parent of the node at Position.

   procedure Delete (Container : in out Tree; Position : Cursor)
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => Has_Element (Container, Position)),
     Post   =>
       (SPARKlib_Full =>
          M.Count (Model (Container))
          = M.Count (Model (Container)'Old)
            - M.Count (Get_Subtree (Container, Position)'Old)
          and then
            not R.Has_Key
                  (Subtrees (Container), Get_Path (Container, Position)'Old)

          --  Subtrees are preserved except for the path leading to Position

          and then
            (if Is_Root (Container'Old, Position)
             then M.Is_Empty (Model (Container))
             else
               Subtrees_Preserved_Except
                 (Subtrees (Container'Old),
                  Subtrees (Container),
                  Get_Path (Container'Old, Position))
               and then
                 M.Is_Empty
                   (M.Child
                      (R.Get
                         (Subtrees (Container),
                          Parent (Get_Path (Container'Old, Position))),
                       K.Get
                         (Get_Path (Container'Old, Position),
                          K.Last (Get_Path (Container'Old, Position))))))

          --  Cursors are preserved and continue designating the same path,
          --  except those in the subtree designated by Position

          and then Same_Paths (Paths (Container), Paths (Container'Old))
          and then
            Paths_Included_Except
              (Paths (Container'Old),
               Paths (Container),
               Get_Path (Container'Old, Position)));
   --  Delete all nodes in the subtree rooted at Position

   procedure Replace_Element
     (Container : in out Tree; New_Item : Element_Type; Position : Cursor)
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => Has_Element (Container, Position)),
     Post   =>
       (SPARKlib_Full =>
          Node_Count (Container) = Node_Count (Container'Old)

          --  The element of the substree rooted at Position has been updated

          and then
            M.Element_Logic_Equal
              (M.Get (Get_Subtree (Container, Position)),
               M.Copy_Element (New_Item))
          and then
            (for all W in Way_Type =>
               M.Tree_Logic_Equal
                 (M.Child (Get_Subtree (Container, Position), W),
                  M.Child (Get_Subtree (Container'Old, Position), W)))

          --  Subtrees are preserved except on the path leading to Position

          and then R.Same_Keys (Subtrees (Container'Old), Subtrees (Container))
          and then
            Subtrees_Preserved_Except
              (Subtrees (Container'Old),
               Subtrees (Container),
               Get_Path (Container'Old, Position))
          and then
            (for all PP of Subtrees (Container'Old) =>
               (if Get_Path (Container'Old, Position) < PP
                then
                  M.Tree_Logic_Equal
                    (R.Get (Subtrees (Container), PP),
                     R.Get (Subtrees (Container'Old), PP))))

          --  Valid cursors stay valid and continue designating the same paths

          and then
            P.Equivalent_Maps (Paths (Container), Paths (Container'Old)));

   function At_End (E : Tree) return Tree
   is (E)
   with Ghost, Annotate => (GNATprove, At_End_Borrow);

   function At_End
     (E : access constant Element_Type) return access constant Element_Type
   is (E)
   with Ghost, Annotate => (GNATprove, At_End_Borrow);

   function Reference
     (Container : aliased in out Tree; Position : Cursor)
      return not null access Element_Type
   with
     Global => null,
     Pre    => (SPARKlib_Defensive => Has_Element (Container, Position)),
     Post   =>
       (SPARKlib_Full =>
          Node_Count (At_End (Container)) = Node_Count (Container)

          --  The element of the subtree rooted at Position has been updated

          and then
            M.Element_Logic_Equal
              (M.Get (Get_Subtree (At_End (Container), Position)),
               At_End (Reference'Result).all)
          and then
            (for all W in Way_Type =>
               M.Tree_Logic_Equal
                 (M.Child (Get_Subtree (At_End (Container), Position), W),
                  M.Child (Get_Subtree (Container, Position), W)))

          --  Subtrees are preserved except on the path leading to Position

          and then
            R.Same_Keys (Subtrees (Container), Subtrees (At_End (Container)))
          and then
            Subtrees_Preserved_Except
              (Subtrees (Container),
               Subtrees (At_End (Container)),
               Get_Path (Container, Position))
          and then
            (for all PP of Subtrees (Container) =>
               (if Get_Path (Container, Position) < PP
                then
                  M.Tree_Logic_Equal
                    (R.Get (Subtrees (At_End (Container)), PP),
                     R.Get (Subtrees (Container), PP))))

          --  Valid cursors stay valid and continue designating the same paths

          and then
            P.Equivalent_Maps (Paths (At_End (Container)), Paths (Container)));

   function Constant_Reference
     (Container : aliased Tree; Position : Cursor)
      return not null access constant Element_Type
   with
     Inline,
     Global => null,
     Pre    => (SPARKlib_Defensive => Has_Element (Container, Position)),
     Post   =>
       (SPARKlib_Full =>
          M.Element_Logic_Equal
            (Constant_Reference'Result.all,
             M.Get (Get_Subtree (Container, Position))));

private
   pragma SPARK_Mode (Off);

   pragma Inline (Has_Element);
   pragma Inline (Is_Empty);
   pragma Inline (Is_Root);
   pragma Inline (Root);

   -------------------
   -- Child Mapping --
   -------------------

   --  Child_Maps stores the links from parent nodes to their children.
   --
   --  Keys are a pair of 1) a cursor to the parent node, and 2) the branch
   --  (Way) from that parent to the child. Elements are cursors to the child
   --  node.
   --
   --  The ordering of Child_Maps ensures that nodes with the same parent are
   --  ordered contiguously and sequentially in Child_Maps. This allows the
   --  next sibling of any child to be obtained using Child_Maps.Next.

   type Cursor_Way_Pair is record
      Parent : Cursor;
      Way    : Way_Type;
   end record;

   function "<" (Left, Right : Cursor_Way_Pair) return Boolean
   is (Left.Parent.Node < Right.Parent.Node
       or (Left.Parent.Node = Right.Parent.Node and Left.Way < Right.Way));

   package Child_Maps is new
     SPARK.Containers.Formal.Ordered_Maps
       (Key_Type     => Cursor_Way_Pair,
        Element_Type => Cursor,
        "<"          => "<");

   -----------
   -- Cells --
   -----------

   --  The nodes in the tree are stored in memory as an array of cells, with
   --  links (cursors) to form the tree structure.

   subtype Positive_Count_Type is Count_Type range 1 .. Count_Type'Last;

   type Cell_Type is record
      Parent : Cursor := No_Element;
      --  Cursor to the parent node. This is No_Element for the root node.

      First_Child : Cursor := No_Element;
      --  Cursor to the first child of this node. That is, the child with
      --  the lowest Direction.
      --
      --  This is No_Element if the node is a leaf node.

      Last_Child : Cursor := No_Element;
      --  Cursor to the last child of this node. That is, the child with
      --  the highest Direction.
      --
      --  This is No_Element if the node is a leaf node.

      Direction : Way_Type := Way_Type'First;
      --  The direction to this node from the parent.
      --
      --  This is only relevant for non-root nodes.

      Position : Child_Maps.Cursor := Child_Maps.No_Element;
      --  Holds this node's position in the Children map.
      --
      --  This is used to get the next/previous sibling of this node via
      --  Child_Maps.Next or Child_Maps.Previous, since siblings are ordered
      --  sequentially in Child_Maps.

      Free : Boolean := False;
      --  True when this node is deallocated and is in the free list.
      --  False when the node is allocated and in-use.

      Element : aliased Element_Type;
      --  The element for this node.
   end record;

   type Cell_Array is array (Positive_Count_Type range <>) of Cell_Type;

   type Tree (Capacity : Count_Type) is record
      Children   : Child_Maps.Map (Capacity);
      Cells      : Cell_Array (1 .. Capacity);
      Root       : Cursor := No_Element;
      Free_List  : Cursor := No_Element;
      Node_Count : Count_Type := 0;
      Used_Cells : Count_Type := 0;
   end record;

end SPARK.Containers.Formal.Trees;
