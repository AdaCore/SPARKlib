--
--  Copyright (C) 2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with System;

package body SPARK.Containers.Formal.Trees
  with SPARK_Mode => Off
is
   use type System.Address;

   procedure Allocate_Cell
     (Container : in out Tree; Index : out Positive_Count_Type);
   --  Allocate a new cell for the tree.
   --
   --  All parent/child/sibling links of the new node are set to No_Element.

   procedure Deallocate_Leaf (Container : in out Tree; Position : Cursor)
   with Pre => (Static => Has_Element (Container, Position));
   --  Deallocate a node from the tree.
   --
   --  The node at Position must be a leaf node, i.e. any descendants must
   --  have already been deallocated.

   procedure Link_Child
     (Container : in out Tree;
      Parent    : Cursor;
      Child     : Cursor;
      Way       : Way_Type);
   --  Link a Child node with its Parent.
   --
   --  The Child node must not be already linked with any other parent.

   procedure Unlink (Container : in out Tree; Position : Cursor);
   --  Unlink the node at Position from its parent and siblings.
   --
   --  The links to child nodes are unchanged.

   procedure Unlink_And_Replace
     (Container : in out Tree; Old_Position : Cursor; New_Position : Cursor);
   --  Unlinks the node at Old_Position from its parent and replaces it with
   --  New_Position.
   --
   --  Links to child nodes of Old_Position and New_Position are unchanged.

   --------------------------
   -- Traversal functions  --
   --------------------------

   function First_Post_Order
     (Container : Tree; Subtree_Root : Cursor) return Cursor
   with Pre => (Static => Has_Element (Container, Subtree_Root));
   --  Get the first node to traverse in the subtree rooted at Position using
   --  depth-first post-order traversal.

   function Next_Post_Order (Container : Tree; Position : Cursor) return Cursor
   with Pre => (Static => Has_Element (Container, Position));
   --  Get the next node in the tree traversal using depth-first post-order
   --  traversal.

   --  The following functions are variants that perform no run-time checks
   --  and have no executable contracts.
   --
   --  They are intended for internal use, particularly in cases where using
   --  the function in the spec would cause recursion when contracts are
   --  executable.
   --
   --  For example, the postcondition of First_Child calls Paths, so the
   --  implementation of Paths cannot call First_Child to traverse the tree
   --  (doing so would cause infinite recursion); it must use
   --  First_Child_Nocheck instead.

   function First_Child_Nocheck
     (Container : Tree; Position : Cursor) return Cursor
   with Pre => (Static => Has_Element (Container, Position));

   function Next_Sibling_Nocheck
     (Container : Tree; Position : Cursor) return Cursor
   with Pre => (Static => Has_Element (Container, Position));

   function Previous_Sibling_Nocheck
     (Container : Tree; Position : Cursor) return Cursor
   with Pre => (Static => Has_Element (Container, Position));

   function Parent_Nocheck (Container : Tree; Position : Cursor) return Cursor
   with Pre => (Static => Has_Element (Container, Position));

   function Child_Nocheck
     (Container : Tree; Position : Cursor; Way : Way_Type) return Cursor
   with Pre => (Static => Has_Element (Container, Position));

   function Direction_Nocheck
     (Container : Tree; Position : Cursor) return Way_Type
   with
     Pre =>
       (Static =>
          Has_Element (Container, Position)
          and then Position /= Root (Container));

   package body Formal_Model is

      ------------
      -- Parent --
      ------------

      function Parent (P : Path) return Path
      is (K.Remove (P, K.Length (P)));

      -----------
      -- Model --
      -----------

      function Model (T : Tree) return M.Tree is
         function Subtree_Model (T : Tree; C : Cursor) return M.Tree;

         -------------------
         -- Subtree_Model --
         -------------------

         function Subtree_Model (T : Tree; C : Cursor) return M.Tree is
            Result   : M.Tree;
            Node     : Cursor;
            Children : M.Tree_Array (Way_Type) := (others => M.Empty_Tree);

         begin
            if C = No_Element then
               Result := M.Empty_Tree;
            else
               Node := First_Child_Nocheck (T, C);

               while Node /= No_Element loop
                  Children (Direction_Nocheck (T, Node)) :=
                    Subtree_Model (T, Node);

                  Node := Next_Sibling_Nocheck (T, Node);
               end loop;

               Result := M.Create (T.Cells (C.Node).Element, Children);
            end if;

            return Result;
         end Subtree_Model;

      begin
         return Subtree_Model (T, T.Root);
      end Model;

      -----------
      -- Paths --
      -----------

      function Paths (T : Tree) return P.Map is
         Current_Path : Path := K.Empty_Sequence;
         Node         : Cursor;
         Next         : Cursor;
         Result       : P.Map := P.Empty_Map;

      begin
         Node := T.Root;

         --  Walk the tree using pre-order traversal to make it easier to keep
         --  track of the Current_Path.

         Outer_Loop : while Node /= No_Element loop

            --  Add this node to the Result map

            Result := P.Add (Result, Node, Current_Path);

            --  Traverse all child nodes.

            Next := First_Child_Nocheck (T, Node);

            if Next /= No_Element then
               Current_Path :=
                 K.Add (Current_Path, Direction_Nocheck (T, Next));
            else

               --  There are no children, try the sibling of Node.
               --
               --  If Node has no siblings, then walk up the tree until we
               --  find an ancestor with a sibling.

               Inner_Loop : while K.Length (Current_Path) > 0 loop
                  Next := Next_Sibling_Nocheck (T, Node);

                  if Next /= No_Element then
                     Current_Path :=
                       K.Set
                         (Current_Path,
                          K.Last (Current_Path),
                          Direction_Nocheck (T, Next));
                     exit Inner_Loop;
                  else
                     Node := Parent_Nocheck (T, Node);
                     Current_Path :=
                       K.Remove (Current_Path, K.Last (Current_Path));
                  end if;
               end loop Inner_Loop;
            end if;

            Node := Next;
         end loop Outer_Loop;

         return Result;
      end Paths;

      --------------
      -- Subtrees --
      --------------

      function Subtrees (T : Tree) return R.Map is
         function Path_Of (C : Cursor) return Path
         with Pre => (Static => Has_Element (T, C));

         -------------
         -- Path_Of --
         -------------

         function Path_Of (C : Cursor) return Path is
            Result : Path := K.Empty_Sequence;
            Node   : Cursor := C;
            Next   : Cursor := Parent_Nocheck (T, C);
         begin
            while Next /= No_Element loop
               Result := K.Add (Result, 1, Direction_Nocheck (T, Node));
               Node := Next;
               Next := Parent_Nocheck (T, Node);
            end loop;

            return Result;
         end Path_Of;

         Result    : R.Map;
         Node      : Cursor;
         C         : Cursor;
         Node_Path : Path;
         ST        : M.Tree;
         Way       : Way_Type;
         Children  : M.Tree_Array (Way_Type);

      begin
         if Is_Empty (T) then
            Result := R.Empty_Map;
         else

            --  Use post-order traversal so that for each node N, all child
            --  subtrees of N are inserted before N itself is inserted.
            --
            --  This allows the child subtrees to be retrieved and linked with
            --  N's subtree, instead of needing to reconstruct the child
            --  subtree each time, which would be inefficient.

            Node := First_Post_Order (T, T.Root);

            while Node /= No_Element loop
               Node_Path := Path_Of (Node);

               --  Get child subtrees of Node

               Children := (others => M.Empty_Tree);

               C := First_Child_Nocheck (T, Node);

               while C /= No_Element loop
                  Way := Direction_Nocheck (T, C);
                  Children (Way) := R.Get (Result, K.Add (Node_Path, Way));
                  C := Next_Sibling_Nocheck (T, C);
               end loop;

               --  Create the subtree for Node and add it to the result map

               ST := M.Create (T.Cells (Node.Node).Element, Children);

               Result := R.Add (Result, Node_Path, ST);

               Node := Next_Post_Order (T, Node);
            end loop;
         end if;

         return Result;
      end Subtrees;

   end Formal_Model;

   ---------
   -- "=" --
   ---------

   function "=" (Left, Right : Tree) return Boolean is
      L_Node : Cursor;
      R_Node : Cursor;

      L_Next : Cursor;
      R_Next : Cursor;
   begin
      --  Traverse both trees using depth-first pre-order traversal, checking
      --  that the same paths are taken at each step and that each node has
      --  equal elements.
      --
      --  Depth-first pre-order is chosen as this makes it simpler to follow
      --  the same path in both trees than other traversal methods.

      L_Node := Root (Left);
      R_Node := Root (Right);

      Tree_Traversal_Loop : loop
         if (L_Node = No_Element) /= (R_Node = No_Element) then
            return False;
         end if;

         exit Tree_Traversal_Loop when L_Node = No_Element;

         --  Compare elements

         if Left.Cells (L_Node.Node).Element
           /= Right.Cells (R_Node.Node).Element
         then
            return False;
         end if;

         --  Traverse to the next node. In pre-order traversal, we try the
         --  following sequence until a valid node is found in both trees:
         --  1. Go to the first child of the current node.
         --  2. If the node has no children, then go to the next sibling of the
         --     current node.
         --  3. If the node has no more siblings, then walk up the tree to go
         --     to the next sibling of an ancestor node.
         --  4. If all ancestors have no more siblings, then the traversal is
         --     complete.

         L_Next := First_Child_Nocheck (Left, L_Node);
         R_Next := First_Child_Nocheck (Right, R_Node);

         Ancestor_Loop : loop
            if (L_Next = No_Element) /= (R_Next = No_Element) then
               return False;
            end if;

            if L_Next /= No_Element then
               if Direction_Nocheck (Left, L_Next)
                 /= Direction_Nocheck (Right, R_Next)
               then
                  return False;
               end if;

               exit Ancestor_Loop;
            end if;

            --  Traversal is complete when we reach the root

            exit Ancestor_Loop when L_Node = No_Element;

            L_Next := Next_Sibling_Nocheck (Left, L_Node);
            R_Next := Next_Sibling_Nocheck (Right, R_Node);

            L_Node := Parent_Nocheck (Left, L_Node);
            R_Node := Parent_Nocheck (Right, R_Node);
         end loop Ancestor_Loop;

         L_Node := L_Next;
         R_Node := R_Next;
      end loop Tree_Traversal_Loop;

      return True;
   end "=";

   -------------------
   -- Allocate_Cell --
   -------------------

   procedure Allocate_Cell
     (Container : in out Tree; Index : out Positive_Count_Type) is
   begin
      if Container.Free_List /= No_Element then

         --  This is the case when the free list is non-empty

         Index := Container.Free_List.Node;
         Container.Free_List := Container.Cells (Index).Parent;

      elsif Container.Used_Cells < Container.Capacity then

         --  This is the case when we've exhaused the free list, but there
         --  are still some unused cells in the Cells array.

         Container.Used_Cells := Container.Used_Cells + 1;
         Index := Container.Used_Cells;

      else

         --  This is the case when the cells array is completely full, and
         --  should never happen as defensive checks should not allow a new
         --  node to be inserted into a full tree.

         raise Storage_Error;
      end if;

      Container.Node_Count := Container.Node_Count + 1;

      Container.Cells (Index) :=
        Cell_Type'
          (Parent      => No_Element,
           Direction   => Way_Type'First,
           First_Child => No_Element,
           Last_Child  => No_Element,
           Position    => Child_Maps.No_Element,
           Free        => False,
           Element     => <>);
   end Allocate_Cell;

   ------------
   -- Assign --
   ------------

   procedure Assign (Target : in out Tree; Source : Tree) is
      S_Node         : Cursor;
      S_Next         : Cursor;
      T_Parent       : Cursor;
      New_Cell_Index : Positive_Count_Type;
      Way            : Way_Type;

   begin
      if Target'Address = Source'Address then
         return;
      end if;

      if Target.Capacity < Node_Count (Source) then
         raise Constraint_Error with "Source length exceeds Target capacity";
      end if;

      Clear (Target);

      if not Is_Empty (Source) then

         --  We can't copy the Cells array here because although
         --  Node_Count (Source) does not exceed Target.Capacity, this does
         --  not guarantee that Source.Capacity does not exceed
         --  Target.Capacity since one of the nodes in Source might have a
         --  position in Source.Cells that is greater than Target.Capacity.
         --
         --  Instead, copy the tree node-by-node using pre-order traversal.

         --  First, insert the root

         Allocate_Cell (Target, New_Cell_Index);
         Target.Cells (New_Cell_Index).Element :=
           Source.Cells (Source.Root.Node).Element;
         Target.Root := Cursor'(Node => New_Cell_Index);

         T_Parent := Target.Root;
         S_Node := First_Child_Nocheck (Source, Source.Root);

         --  Next, walk the Source tree and copy each node into Target

         while S_Node /= No_Element loop

            --  Insert a new child in Target

            Allocate_Cell (Target, New_Cell_Index);

            Target.Cells (New_Cell_Index).Element :=
              Source.Cells (S_Node.Node).Element;

            Way := Direction_Nocheck (Source, S_Node);

            Link_Child
              (Container => Target,
               Parent    => T_Parent,
               Child     => Cursor'(Node => New_Cell_Index),
               Way       => Way);

            --  Go to the next node

            S_Next := First_Child_Nocheck (Source, S_Node);

            if S_Next /= No_Element then
               T_Parent := Child_Nocheck (Target, T_Parent, Way);
               S_Node := S_Next;

            else
               S_Next := Next_Sibling_Nocheck (Source, S_Node);

               while S_Next = No_Element and then T_Parent /= No_Element loop
                  S_Node := Parent_Nocheck (Source, S_Node);
                  S_Next := Next_Sibling_Nocheck (Source, S_Node);
                  T_Parent := Parent_Nocheck (Target, T_Parent);
               end loop;

               S_Node := S_Next;
            end if;
         end loop;
      end if;
   end Assign;

   ------------
   -- Child --
   ------------

   function Child
     (Container : Tree; Position : Cursor; Way : Way_Type) return Cursor
   is
      use type Child_Maps.Cursor;

      Pos : Child_Maps.Cursor;

   begin
      if not Has_Element (Container, Position) then
         raise Constraint_Error with "Position cursor not in tree";
      end if;

      Pos := Child_Maps.Find (Container.Children, (Position, Way));

      if Pos = Child_Maps.No_Element then
         return No_Element;
      else
         return Child_Maps.Element (Container.Children, Pos);
      end if;
   end Child;

   -------------------
   -- Child_Nocheck --
   -------------------

   function Child_Nocheck
     (Container : Tree; Position : Cursor; Way : Way_Type) return Cursor
   is
      use type Child_Maps.Cursor;

      Pos : Child_Maps.Cursor;

   begin
      Pos := Child_Maps.Find (Container.Children, (Position, Way));

      if Pos = Child_Maps.No_Element then
         return No_Element;
      else
         return Child_Maps.Element (Container.Children, Pos);
      end if;
   end Child_Nocheck;

   -----------
   -- Clear --
   -----------

   procedure Clear (Container : out Tree) is
   begin
      Container.Root := No_Element;
      Container.Free_List := No_Element;
      Container.Node_Count := 0;
      Container.Used_Cells := 0;

      Child_Maps.Clear (Container.Children);
   end Clear;

   ------------------------
   -- Constant_Reference --
   ------------------------

   function Constant_Reference
     (Container : aliased Tree; Position : Cursor)
      return not null access constant Element_Type is
   begin
      if not Has_Element (Container, Position) then
         raise Constraint_Error with "Position cursor has no element";
      end if;

      return Container.Cells (Position.Node).Element'Access;
   end Constant_Reference;

   ----------
   -- Copy --
   ----------

   function Copy (Source : Tree; Capacity : Count_Type := 0) return Tree is
   begin
      if Capacity /= 0 and then Capacity < Source.Capacity then
         raise Capacity_Error;
      end if;

      return
         Result : Tree (Capacity => Count_Type'Max (Source.Capacity, Capacity))
      do
         Result.Cells (Source.Cells'Range) := Source.Cells;
         Result.Free_List := Source.Free_List;
         Result.Used_Cells := Source.Used_Cells;
         Result.Node_Count := Source.Node_Count;
         Result.Root := Source.Root;

         Result.Children := Child_Maps.Copy (Source.Children, Capacity);
      end return;
   end Copy;

   ---------------------
   -- Deallocate_Leaf --
   ---------------------

   procedure Deallocate_Leaf (Container : in out Tree; Position : Cursor) is
      Cell_Ref : Cell_Type renames Container.Cells (Position.Node);
   begin
      Cell_Ref.Free := True;
      Cell_Ref.Parent := Container.Free_List;
      Cell_Ref.First_Child := No_Element;
      Cell_Ref.Last_Child := No_Element;

      Container.Free_List := Position;
      Container.Node_Count := Container.Node_Count - 1;
   end Deallocate_Leaf;

   ------------
   -- Delete --
   ------------

   procedure Delete (Container : in out Tree; Position : Cursor) is
      Node : Cursor;
      Next : Cursor;
   begin
      if not Has_Element (Container, Position) then
         raise Constraint_Error with "attempt to delete cursor not in tree";
      end if;

      if Position = Container.Root then
         Clear (Container);
      else

         Unlink (Container, Position);

         --  Traverse the subtree using depth-first post-order traversal and
         --  deallocate each node. This traversal order ensures that all
         --  descendants of a node are traversed and deallocated before the
         --  node itself is traversed and deallocated.

         Node := First_Post_Order (Container, Position);

         loop
            --  The node at Position is the last node in the traversal, so
            --  stop when we reach that node to avoid deleting nodes outside of
            --  the subtree rooted at Position.

            if Node = Position then
               Next := No_Element;
            else
               Next := Next_Post_Order (Container, Node);
            end if;

            Deallocate_Leaf (Container, Node);

            exit when Next = No_Element;

            Node := Next;
         end loop;
      end if;
   end Delete;

   -----------
   -- Depth --
   -----------

   function Depth (Container : Tree; Position : Cursor) return Count_Type is
      Result : Count_Type := 0;
      Next   : Cursor := Position;
   begin
      if not Has_Element (Container, Position) then
         raise Constraint_Error with "Position cursor not in tree";
      end if;

      loop
         Next := Container.Cells (Next.Node).Parent;
         exit when Next = No_Element;
         Result := Result + 1;
      end loop;

      return Result;
   end Depth;

   ---------------
   -- Direction --
   ---------------

   function Direction (Container : Tree; Position : Cursor) return Way_Type is
   begin
      if not Has_Element (Container, Position) then
         raise Constraint_Error with "Position cursor not in tree";
      end if;

      return Direction_Nocheck (Container, Position);
   end Direction;

   -----------------------
   -- Direction_Nocheck --
   -----------------------

   function Direction_Nocheck
     (Container : Tree; Position : Cursor) return Way_Type
   is (Container.Cells (Position.Node).Direction);

   -------------
   -- Element --
   -------------

   function Element (Container : Tree; Position : Cursor) return Element_Type
   is
   begin
      if not Has_Element (Container, Position) then
         raise Constraint_Error with "Position cursor has no element";
      end if;

      return Container.Cells (Position.Node).Element;
   end Element;

   ----------------
   -- Empty_Tree --
   ----------------

   function Empty_Tree (Capacity : Count_Type := 10) return Tree
   is (Tree'(Capacity => Capacity, others => <>));

   -----------------
   -- First_Child --
   -----------------

   function First_Child (Container : Tree; Position : Cursor) return Cursor is
   begin
      if not Has_Element (Container, Position) then
         raise Constraint_Error with "Position cursor not in tree";
      end if;

      return First_Child_Nocheck (Container, Position);
   end First_Child;

   -------------------------
   -- First_Child_Nocheck --
   -------------------------

   function First_Child_Nocheck
     (Container : Tree; Position : Cursor) return Cursor
   is (Container.Cells (Position.Node).First_Child);

   ----------------------
   -- First_Post_Order --
   ----------------------

   function First_Post_Order
     (Container : Tree; Subtree_Root : Cursor) return Cursor
   is
      Node : Cursor := Subtree_Root;
      Next : Cursor;
   begin
      loop
         Next := First_Child_Nocheck (Container, Node);
         exit when Next = No_Element;
         Node := Next;
      end loop;

      return Node;
   end First_Post_Order;

   ---------------
   -- Has_Child --
   ---------------

   function Has_Child
     (Container : Tree; Parent : Cursor; Way : Way_Type) return Boolean is
   begin
      if not Has_Element (Container, Parent) then
         raise Constraint_Error with "Parent cursor not in tree";
      end if;

      return Child_Maps.Contains (Container.Children, (Parent, Way));
   end Has_Child;

   -----------------
   -- Has_Element --
   -----------------

   function Has_Element (Container : Tree; Position : Cursor) return Boolean
   is (Position.Node in 1 .. Container.Used_Cells
       and then not Container.Cells (Position.Node).Free);

   ----------------
   -- In_Subtree --
   ----------------

   function In_Subtree
     (Container : Tree; Position : Cursor; Subtree_Root : Cursor)
      return Boolean
   is
      Next : Cursor := Position;
   begin
      if not Has_Element (Container, Position) then
         raise Constraint_Error with "Subtree_Root cursor not in tree";
      end if;

      while Next /= Subtree_Root and Next /= No_Element loop
         Next := Container.Cells (Next.Node).Parent;
      end loop;

      return Next = Subtree_Root;
   end In_Subtree;

   ------------------
   -- Insert_Child --
   ------------------

   procedure Insert_Child
     (Container : in out Tree;
      New_Item  : Element_Type;
      Parent    : Cursor;
      Way       : Way_Type)
   is

      New_Cell_Index : Positive_Count_Type;

   begin
      --  Note that Has_Child performs the defensive check for
      --  Has_Element (Container, Parent).

      if Has_Child (Container, Parent, Way) then
         raise Constraint_Error with "Parent node already has a child at Way";
      end if;

      if Container.Node_Count = Container.Capacity then
         raise Constraint_Error
           with "tree is already at its maximum number of nodes";
      end if;

      Allocate_Cell (Container, New_Cell_Index);

      Container.Cells (New_Cell_Index).Element := New_Item;

      Link_Child
        (Container => Container,
         Parent    => Parent,
         Child     => Cursor'(Node => New_Cell_Index),
         Way       => Way);
   end Insert_Child;

   -------------------
   -- Insert_Parent --
   -------------------

   procedure Insert_Parent
     (Container : in out Tree;
      New_Item  : Element_Type;
      Position  : Cursor;
      Way       : Way_Type)
   is
      New_Parent : Cursor;

   begin
      if not Has_Element (Container, Position) then
         raise Constraint_Error with "Position cursor not in tree";
      end if;

      if Container.Node_Count = Container.Capacity then
         raise Constraint_Error
           with "tree is already at its maximum number of nodes";
      end if;

      Allocate_Cell (Container, New_Parent.Node);

      Container.Cells (New_Parent.Node).Element := New_Item;

      Unlink_And_Replace
        (Container    => Container,
         Old_Position => Position,
         New_Position => New_Parent);

      Link_Child
        (Container => Container,
         Parent    => New_Parent,
         Child     => Position,
         Way       => Way);

      if Position = Container.Root then
         Container.Root := New_Parent;
      end if;
   end Insert_Parent;

   -----------------
   -- Insert_Root --
   -----------------

   procedure Insert_Root (Container : in out Tree; New_Item : Element_Type) is
      New_Cell_Index : Positive_Count_Type;

   begin
      Clear (Container);

      Allocate_Cell (Container, New_Cell_Index);

      Container.Cells (New_Cell_Index).Element := New_Item;

      Container.Root := Cursor'(Node => New_Cell_Index);
      Container.Node_Count := 1;
   end Insert_Root;

   --------------------
   -- Is_Ancestor_Of --
   --------------------

   function Is_Ancestor_Of
     (Container : Tree; Parent : Cursor; Position : Cursor) return Boolean
   is
      Next : Cursor := Position;
   begin
      if not Has_Element (Container, Parent) then
         raise Constraint_Error with "Parent cursor not in tree";
      end if;

      if not Has_Element (Container, Position) then
         raise Constraint_Error with "Position cursor not in tree";
      end if;

      loop
         Next := Container.Cells (Next.Node).Parent;
         exit when Next = No_Element or Next = Parent;
      end loop;

      return Next = Parent;
   end Is_Ancestor_Of;

   --------------
   -- Is_Empty --
   --------------

   function Is_Empty (Container : Tree) return Boolean
   is (Container.Node_Count = 0);

   -------------
   -- Is_Leaf --
   -------------

   function Is_Leaf (Container : Tree; Position : Cursor) return Boolean is
   begin
      if not Has_Element (Container, Position) then
         raise Constraint_Error with "Position cursor not in tree";
      end if;

      return Container.Cells (Position.Node).First_Child = No_Element;
   end Is_Leaf;

   -------------
   -- Is_Root --
   -------------

   function Is_Root (Container : Tree; Position : Cursor) return Boolean
   is (Position /= No_Element and Position = Container.Root);

   ----------------
   -- Last_Child --
   ----------------

   function Last_Child (Container : Tree; Position : Cursor) return Cursor is
   begin
      if not Has_Element (Container, Position) then
         raise Constraint_Error with "Position cursor not in tree";
      end if;

      return Container.Cells (Position.Node).Last_Child;
   end Last_Child;

   ----------------
   -- Link_Child --
   ----------------

   procedure Link_Child
     (Container : in out Tree; Parent : Cursor; Child : Cursor; Way : Way_Type)
   is
      Parent_Ref : Cell_Type renames Container.Cells (Parent.Node);
      Child_Ref  : Cell_Type renames Container.Cells (Child.Node);
      Inserted   : Boolean;
   begin
      --  Link Parent and Child

      Child_Ref.Parent := Parent;
      Child_Ref.Direction := Way;

      --  Link Child with its new siblings

      if Parent_Ref.First_Child = No_Element then

         --  This is the case when the Parent is a leaf. Child becomes the
         --  sole child of Parent.

         Parent_Ref.First_Child := Child;
         Parent_Ref.Last_Child := Child;

      elsif Way < Direction_Nocheck (Container, Parent_Ref.First_Child) then

         --  This is the case when Parent is a non-leaf node, and the Way of
         --  Child is before Parent's first child. In this case, Child
         --  becomes the new first child of Parent.

         Parent_Ref.First_Child := Child;

      elsif Direction_Nocheck (Container, Parent_Ref.Last_Child) < Way then

         --  This is the case when Parent is a non-leaf node, and the Way of
         --  Child is after Parent's first child. In this case, Child
         --  becomes the new last child of Parent.

         Parent_Ref.Last_Child := Child;

      else
         --  This is the case when Parent is a non-leaf node and Child is
         --  somewhere between the first and last children of Parent.
         --
         --  In this case there are no references to be updated in the parent.

         null;
      end if;

      Child_Maps.Insert
        (Container => Container.Children,
         Key       => (Parent, Way),
         New_Item  => Child,
         Position  => Child_Ref.Position,
         Inserted  => Inserted);

      --  The key (Parent, Way) should not already be in the Children map, so
      --  the new item should always be inserted.

      pragma Assert (Inserted);
   end Link_Child;

   ----------
   -- Move --
   ----------

   procedure Move (Target : in out Tree; Source : in out Tree) is
   begin
      if Target'Address = Source'Address then
         return;
      end if;

      Assign (Target => Target, Source => Source);
      Clear (Source);
   end Move;

   ---------------------
   -- Next_Post_Order --
   ---------------------

   function Next_Post_Order (Container : Tree; Position : Cursor) return Cursor
   is
      Next : Cursor;
   begin
      Next := Next_Sibling_Nocheck (Container, Position);

      if Next /= No_Element then
         return First_Post_Order (Container, Next);
      else
         return Parent_Nocheck (Container, Position);
      end if;
   end Next_Post_Order;

   ------------------
   -- Next_Sibling --
   ------------------

   function Next_Sibling (Container : Tree; Position : Cursor) return Cursor is
   begin
      if not Has_Element (Container, Position) then
         raise Constraint_Error with "Position cursor not in tree";
      end if;

      return Next_Sibling_Nocheck (Container, Position);
   end Next_Sibling;

   --------------------------
   -- Next_Sibling_Nocheck --
   --------------------------

   function Next_Sibling_Nocheck
     (Container : Tree; Position : Cursor) return Cursor
   is
      Node_Ref : Cell_Type renames Container.Cells (Position.Node);
      Next     : Child_Maps.Cursor;

   begin
      --  The root node never has siblings

      if Node_Ref.Parent = No_Element then
         return No_Element;
      end if;

      --  Don't go beyond the last child of the parent

      if Position = Container.Cells (Node_Ref.Parent.Node).Last_Child then
         return No_Element;
      end if;

      --  The ordering of Child_Maps guarantees that the next cursor will be
      --  a sibling of the node at Position.

      Next := Child_Maps.Next (Container.Children, Node_Ref.Position);

      return Child_Maps.Element (Container.Children, Next);
   end Next_Sibling_Nocheck;

   ----------------
   -- Node_Count --
   ----------------

   function Node_Count (Container : Tree) return Count_Type
   is (Container.Node_Count);

   function Node_Count (Container : Tree; Position : Cursor) return Count_Type
   is
      Count : Count_Type := 0;
      Node  : Cursor;
   begin
      if not Has_Element (Container, Position) then
         raise Constraint_Error with "Position cursor not in tree";
      end if;

      --  Traverse the subtree using depth-first post-order traversal so that
      --  the last node in the traversal is the node at Position, which
      --  simplifies the loop exit condition.

      Node := First_Post_Order (Container, Position);

      loop
         Count := Count + 1;
         exit when Node = Position;
         Node := Next_Post_Order (Container, Node);
      end loop;

      return Count;
   end Node_Count;

   ------------
   -- Parent --
   ------------

   function Parent (Container : Tree; Position : Cursor) return Cursor is
   begin
      if not Has_Element (Container, Position) then
         raise Constraint_Error with "Position cursor not in tree";
      end if;

      return Parent_Nocheck (Container, Position);
   end Parent;

   --------------------
   -- Parent_Nocheck --
   --------------------

   function Parent_Nocheck (Container : Tree; Position : Cursor) return Cursor
   is (Container.Cells (Position.Node).Parent);

   ----------------------
   -- Previous_Sibling --
   ----------------------

   function Previous_Sibling
     (Container : Tree; Position : Cursor) return Cursor is
   begin
      if not Has_Element (Container, Position) then
         raise Constraint_Error with "Position cursor not in tree";
      end if;

      return Previous_Sibling_Nocheck (Container, Position);
   end Previous_Sibling;

   ------------------------------
   -- Previous_Sibling_Nocheck --
   ------------------------------

   function Previous_Sibling_Nocheck
     (Container : Tree; Position : Cursor) return Cursor
   is
      Node_Ref : Cell_Type renames Container.Cells (Position.Node);
      Prev     : Child_Maps.Cursor;

   begin
      --  The root node never has siblings

      if Node_Ref.Parent = No_Element then
         return No_Element;
      end if;

      --  Don't go beyond the first child of the parent

      if Position = Container.Cells (Node_Ref.Parent.Node).First_Child then
         return No_Element;
      end if;

      --  The ordering of Child_Maps guarantees that the previous cursor will
      --  be a sibling of the node at Position.

      Prev := Child_Maps.Previous (Container.Children, Node_Ref.Position);

      return Child_Maps.Element (Container.Children, Prev);
   end Previous_Sibling_Nocheck;

   ---------------
   -- Reference --
   ---------------

   function Reference
     (Container : aliased in out Tree; Position : Cursor)
      return not null access Element_Type is
   begin
      if not Has_Element (Container, Position) then
         raise Constraint_Error with "Position cursor not in tree";
      end if;

      return Container.Cells (Position.Node).Element'Access;
   end Reference;

   ---------------------
   -- Replace_Element --
   ---------------------

   procedure Replace_Element
     (Container : in out Tree; New_Item : Element_Type; Position : Cursor) is
   begin
      if not Has_Element (Container, Position) then
         raise Constraint_Error with "Position cursor not in tree";
      end if;

      Container.Cells (Position.Node).Element := New_Item;
   end Replace_Element;

   ----------
   -- Root --
   ----------

   function Root (Container : Tree) return Cursor
   is (Container.Root);

   ------------
   -- Unlink --
   ------------

   procedure Unlink (Container : in out Tree; Position : Cursor) is
      Cell_Ref : Cell_Type renames Container.Cells (Position.Node);
   begin
      if Cell_Ref.Parent /= No_Element then
         declare
            Parent_Ref : Cell_Type renames
              Container.Cells (Cell_Ref.Parent.Node);
         begin
            if Parent_Ref.First_Child = Position then
               Parent_Ref.First_Child :=
                 Next_Sibling_Nocheck (Container, Parent_Ref.First_Child);
            end if;

            if Parent_Ref.Last_Child = Position then
               Parent_Ref.Last_Child :=
                 Previous_Sibling_Nocheck (Container, Parent_Ref.Last_Child);
            end if;
         end;

         Child_Maps.Delete
           (Container => Container.Children,
            Key       => (Cell_Ref.Parent, Cell_Ref.Direction));

         Cell_Ref.Position := Child_Maps.No_Element;
         Cell_Ref.Parent := No_Element;
      end if;
   end Unlink;

   ------------------------
   -- Unlink_And_Replace --
   ------------------------

   procedure Unlink_And_Replace
     (Container : in out Tree; Old_Position : Cursor; New_Position : Cursor)
   is
      Old_Ref : Cell_Type renames Container.Cells (Old_Position.Node);
      New_Ref : Cell_Type renames Container.Cells (New_Position.Node);
   begin
      New_Ref.Parent := Old_Ref.Parent;
      New_Ref.Direction := Old_Ref.Direction;
      New_Ref.Position := Old_Ref.Position;

      --  Replace links to parent

      if Old_Ref.Parent /= No_Element then
         Child_Maps.Replace
           (Container => Container.Children,
            Key       => (Old_Ref.Parent, Old_Ref.Direction),
            New_Item  => New_Position);

         declare
            Parent_Ref : Cell_Type renames
              Container.Cells (Old_Ref.Parent.Node);
         begin
            if Parent_Ref.First_Child = Old_Position then
               Parent_Ref.First_Child := New_Position;
            end if;

            if Parent_Ref.Last_Child = Old_Position then
               Parent_Ref.Last_Child := New_Position;
            end if;
         end;
      end if;

      Old_Ref.Parent := No_Element;
      Old_Ref.Position := Child_Maps.No_Element;
   end Unlink_And_Replace;

end SPARK.Containers.Formal.Trees;
