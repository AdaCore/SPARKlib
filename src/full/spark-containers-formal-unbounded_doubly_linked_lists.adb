--
--  Copyright (C) 2022-2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with Ada.Unchecked_Deallocation;
with System;
use type System.Address;

package body SPARK.Containers.Formal.Unbounded_Doubly_Linked_Lists
  with SPARK_Mode => Off
is
   use type Cells.Pointer;
   use type Node_Array_Access;
   use type Elements_Array_Access;

   --  Calls to Ops pass array storage and scalar controls separately. If an
   --  element allocation raises Storage_Error, array updates can remain while
   --  scalar out parameters are not copied back. No exceptional copy-back or
   --  rollback is provided, as recovery from Storage_Error is not supported.

   procedure Free_Nodes is new
     Ada.Unchecked_Deallocation (Node_Array, Node_Array_Access);
   procedure Free_Elements is new
     Ada.Unchecked_Deallocation (Elements_Array, Elements_Array_Access);

   procedure Ensure_Capacity (Container : in out List; Size : Count_Type);

   function To_Cursor (Index : Count_Type) return Cursor
   is ((Node => Index))
   with Ghost => SPARKlib_Logic;

   function Node (Position : Cursor) return Count_Type
   is (Position.Node)
   with Ghost => SPARKlib_Logic;

   package List_Model is new
     Ops.Generic_Model
       (Cursor,
        To_Cursor,
        Node,
        Formal_Model.M,
        Formal_Model.P);

   ---------
   -- "=" --
   ---------

   function "=" (Left : List; Right : List) return Boolean is
   begin
      if Left'Address = Right'Address then
         return True;
      end if;
      if Left.Length /= Right.Length then
         return False;
      end if;
      if Left.Length = 0 then
         return True;
      end if;
      return
        Ops.Equal
          (Left.Nodes.all,
           Left.Elements.all,
           Left.Free,
           Left.First,
           Left.Last,
           Left.Length,
           Right.Nodes.all,
           Right.Elements.all,
           Right.Free,
           Right.First,
           Right.Last,
           Right.Length);
   end "=";

   ------------
   -- Adjust --
   ------------

   overriding
   procedure Adjust (Container : in out List) is
      Source_Nodes        : constant Node_Array_Access := Container.Nodes;
      Source_Elements     : constant Elements_Array_Access :=
        Container.Elements;
      New_Nodes           : Node_Array_Access;
      New_Elements        : Elements_Array_Access;
      Free                : Count_Type'Base := -1;
      First, Last, Length : Count_Type;
   begin
      if Source_Nodes = null then
         return;
      end if;
      if Container.Length = 0 then
         Container.Nodes := null;
         Container.Elements := null;
         Container.Free := -1;
         return;
      end if;
      --  The separate allocations have no cleanup on Storage_Error: failure
      --  of the second can leak the first. This is accepted because recovery
      --  from Storage_Error is not supported.
      New_Nodes := new Node_Array (1 .. Source_Nodes'Length);
      New_Elements := new Elements_Array (1 .. Source_Elements'Length);
      Ops.Copy
        (New_Nodes.all,
         New_Elements.all,
         Free,
         First,
         Last,
         Length,
         Source_Nodes.all,
         Source_Elements.all,
         Container.Free,
         Container.First,
         Container.Last,
         Container.Length);
      Container.Nodes := New_Nodes;
      Container.Elements := New_Elements;
      Container.Free := Free;
      Container.First := First;
      Container.Last := Last;
      Container.Length := Length;
   end Adjust;

   ------------
   -- Append --
   ------------

   procedure Append (Container : in out List; New_Item : Element_Type) is
   begin
      Insert (Container, No_Element, New_Item, 1);
   end Append;

   procedure Append
     (Container : in out List; New_Item : Element_Type; Count : Count_Type) is
   begin
      Insert (Container, No_Element, New_Item, Count);
   end Append;

   ------------
   -- Assign --
   ------------

   procedure Assign (Target : in out List; Source : List) is
   begin
      if Target'Address = Source'Address then
         return;
      end if;
      Clear (Target);
      if Source.Length = 0 then
         return;
      end if;
      Ensure_Capacity (Target, Source.Length);
      Ops.Assign
        (Target.Nodes.all,
         Target.Elements.all,
         Target.Free,
         Target.First,
         Target.Last,
         Target.Length,
         Source.Nodes.all,
         Source.Elements.all,
         Source.Free,
         Source.First,
         Source.Last,
         Source.Length);
   end Assign;

   -----------
   -- Clear --
   -----------

   procedure Clear (Container : in out List) is
   begin
      if Container.Length = 0 then
         return;
      end if;
      Ops.Clear
        (Container.Nodes.all,
         Container.Elements.all,
         Container.Free,
         Container.First,
         Container.Last,
         Container.Length);
   end Clear;

   ------------------------
   -- Constant_Reference --
   ------------------------

   function Constant_Reference
     (Container : List; Position : Cursor)
      return not null access constant Element_Type is
   begin
      if Position.Node = 0 then
         raise Constraint_Error with "Position cursor has no element";
      elsif not Has_Element (Container, Position) then
         raise Program_Error
           with "Position cursor designates no element in Container";
      end if;
      return Cells.Constant_Reference (Container.Elements (Position.Node));
   end Constant_Reference;

   --------------
   -- Contains --
   --------------

   function Contains (Container : List; Item : Element_Type) return Boolean is
   begin
      return Find (Container, Item) /= No_Element;
   end Contains;

   ----------
   -- Copy --
   ----------

   function Copy (Source : List) return List is
      Result : List;
   begin
      if Source.Nodes = null then
         return Result;
      end if;
      Result.Nodes := new Node_Array (1 .. Source.Nodes'Length);
      Result.Elements := new Elements_Array (1 .. Source.Elements'Length);
      Ops.Copy
        (Result.Nodes.all,
         Result.Elements.all,
         Result.Free,
         Result.First,
         Result.Last,
         Result.Length,
         Source.Nodes.all,
         Source.Elements.all,
         Source.Free,
         Source.First,
         Source.Last,
         Source.Length);
      return Result;
   end Copy;

   ------------
   -- Delete --
   ------------

   procedure Delete (Container : in out List; Position : in out Cursor) is
   begin
      Delete (Container, Position, 1);
   end Delete;

   procedure Delete
     (Container : in out List; Position : in out Cursor; Count : Count_Type) is
   begin
      if Position.Node = 0 then
         raise Constraint_Error with "Position cursor has no element";
      elsif not Has_Element (Container, Position) then
         raise Program_Error
           with "Position cursor designates no element in Container";
      end if;
      Ops.Delete
        (Container.Nodes.all,
         Container.Elements.all,
         Container.Free,
         Container.First,
         Container.Last,
         Container.Length,
         Position.Node,
         Count);
   end Delete;

   ------------------
   -- Delete_First --
   ------------------

   procedure Delete_First (Container : in out List) is
   begin
      Delete_First (Container, 1);
   end Delete_First;

   procedure Delete_First (Container : in out List; Count : Count_Type) is
   begin
      if Container.Length = 0 then
         return;
      end if;
      Ops.Delete_First
        (Container.Nodes.all,
         Container.Elements.all,
         Container.Free,
         Container.First,
         Container.Last,
         Container.Length,
         Count);
   end Delete_First;

   -----------------
   -- Delete_Last --
   -----------------

   procedure Delete_Last (Container : in out List) is
   begin
      Delete_Last (Container, 1);
   end Delete_Last;

   procedure Delete_Last (Container : in out List; Count : Count_Type) is
   begin
      if Container.Length = 0 then
         return;
      end if;
      Ops.Delete_Last
        (Container.Nodes.all,
         Container.Elements.all,
         Container.Free,
         Container.First,
         Container.Last,
         Container.Length,
         Count);
   end Delete_Last;

   -------------
   -- Element --
   -------------

   function Element (Container : List; Position : Cursor) return Element_Type
   is
   begin
      if Position.Node = 0 then
         raise Constraint_Error with "Position cursor has no element";
      elsif not Has_Element (Container, Position) then
         raise Program_Error
           with "Position cursor designates no element in Container";
      end if;
      return Ops.Element (Container.Elements.all, Position.Node);
   end Element;

   ----------------
   -- Empty_List --
   ----------------

   function Empty_List return List
   is ((Controlled with others => <>));

   ---------------------
   -- Ensure_Capacity --
   ---------------------

   procedure Ensure_Capacity (Container : in out List; Size : Count_Type) is
   begin
      if Size = 0 then
         return;
      end if;
      if Container.Nodes = null or else Size > Container.Nodes'Length then
         Indefinite_Ops.Resize
           (Container.Nodes, Container.Elements, Container.Free, Size);
      end if;
   end Ensure_Capacity;

   --------------
   -- Finalize --
   --------------

   overriding
   procedure Finalize (Container : in out List) is
      X : Count_Type := Container.First;
   begin
      if Container.Nodes = null then
         return;
      end if;
      while X /= 0 loop
         Cells.Reclaim (Container.Elements (X));
         X := Container.Nodes (X).Next;
      end loop;
      Free_Elements (Container.Elements);
      Free_Nodes (Container.Nodes);
      Container.Free := 0;
      Container.First := 0;
      Container.Last := 0;
      Container.Length := 0;
   end Finalize;

   ----------
   -- Find --
   ----------

   function Find
     (Container : List; Item : Element_Type; Position : Cursor := No_Element)
      return Cursor is
   begin
      if Position.Node /= 0 and then not Has_Element (Container, Position) then
         raise Program_Error
           with "Position cursor designates no element in Container";
      end if;
      if Position.Node = 0 and then Container.Length = 0 then
         return No_Element;
      end if;
      return
        (Node =>
           Ops.Find
             (Container.Nodes.all,
              Container.Elements.all,
              Container.Free,
              Container.First,
              Container.Last,
              Container.Length,
              Item,
              Position.Node));
   end Find;

   -----------
   -- First --
   -----------

   function First (Container : List) return Cursor
   is ((Node => Container.First));

   -------------------
   -- First_Element --
   -------------------

   function First_Element (Container : List) return Element_Type is
   begin
      if Container.First = 0 then
         raise Constraint_Error with "list is empty";
      end if;
      return Ops.Element (Container.Elements.all, Container.First);
   end First_Element;

   ------------------
   -- Formal_Model --
   ------------------

   package body Formal_Model is

      ----------------------------
      -- Lift_Abstraction_Level --
      ----------------------------

      procedure Lift_Abstraction_Level (Container : List) is null;

      -------------------------
      -- M_Elements_In_Union --
      -------------------------

      function M_Elements_In_Union
        (Container : M.Sequence; Left : M.Sequence; Right : M.Sequence)
         return Boolean
      renames List_Model.M_Elements_In_Union;

      -------------------------
      -- M_Elements_Included --
      -------------------------

      function M_Elements_Included
        (Left  : M.Sequence;
         L_Fst : Positive_Count_Type := 1;
         L_Lst : Count_Type;
         Right : M.Sequence;
         R_Fst : Positive_Count_Type := 1;
         R_Lst : Count_Type) return Boolean
      renames List_Model.M_Elements_Included;

      -------------------------
      -- M_Elements_Reversed --
      -------------------------

      function M_Elements_Reversed (Left, Right : M.Sequence) return Boolean
      renames List_Model.M_Elements_Reversed;

      ------------------------
      -- M_Elements_Swapped --
      ------------------------

      function M_Elements_Swapped
        (Left, Right : M.Sequence; X, Y : Positive_Count_Type) return Boolean
      renames List_Model.M_Elements_Swapped;

      -----------------------
      -- Mapping_Preserved --
      -----------------------

      function Mapping_Preserved
        (M_Left, M_Right : M.Sequence; P_Left, P_Right : P.Map) return Boolean
      renames List_Model.Mapping_Preserved;

      -----------
      -- Model --
      -----------

      function Model (Container : List) return M.Sequence is
      begin
         if Container.Nodes = null then
            return M.Empty_Sequence;
         end if;
         return
           List_Model.Model
             (Container.Nodes.all,
              Container.Elements.all,
              Container.Free,
              Container.First,
              Container.Last,
              Container.Length);
      end Model;

      -------------------------
      -- P_Positions_Shifted --
      -------------------------

      function P_Positions_Shifted
        (Small, Big : P.Map;
         Cut        : Positive_Count_Type;
         Count      : Count_Type := 1) return Boolean
      renames List_Model.P_Positions_Shifted;

      -------------------------
      -- P_Positions_Swapped --
      -------------------------

      function P_Positions_Swapped
        (Left, Right : P.Map; X, Y : Cursor) return Boolean
      renames List_Model.P_Positions_Swapped;

      ---------------------------
      -- P_Positions_Truncated --
      ---------------------------

      function P_Positions_Truncated
        (Small, Big : P.Map;
         Cut        : Positive_Count_Type;
         Count      : Count_Type := 1) return Boolean
      renames List_Model.P_Positions_Truncated;

      ---------------
      -- Positions --
      ---------------

      function Positions (Container : List) return P.Map is
      begin
         if Container.Nodes = null then
            return P.Empty_Map;
         end if;
         return
           List_Model.Positions
             (Container.Nodes.all,
              Container.Free,
              Container.First,
              Container.Last,
              Container.Length);
      end Positions;

   end Formal_Model;

   ---------------------
   -- Generic_Sorting --
   ---------------------

   package body Generic_Sorting
     with SPARK_Mode => Off
   is
      package Sorting_Ops is new Ops.Generic_Sorting ("<");
      package Sorting_Model is new List_Model.Generic_Sorting ("<");

      ------------------
      -- Formal_Model --
      ------------------

      package body Formal_Model is

         -----------------------
         -- M_Elements_Sorted --
         -----------------------

         function M_Elements_Sorted (Container : M.Sequence) return Boolean
         renames Sorting_Model.M_Elements_Sorted;

      end Formal_Model;

      ---------------
      -- Is_Sorted --
      ---------------

      function Is_Sorted (Container : List) return Boolean is
      begin
         if Container.Length <= 1 then
            return True;
         end if;
         return
           Sorting_Ops.Is_Sorted
             (Container.Nodes.all,
              Container.Elements.all,
              Container.Free,
              Container.First,
              Container.Last,
              Container.Length);
      end Is_Sorted;

      -----------
      -- Merge --
      -----------

      procedure Merge (Target : in out List; Source : in out List) is
      begin
         if Target'Address = Source'Address then
            raise Program_Error with "Target and Source denote same container";
         end if;
         if Source.Length = 0 then
            return;
         end if;
         Ensure_Capacity (Target, Target.Length + Source.Length);
         Sorting_Ops.Merge
           (Target.Nodes.all,
            Target.Elements.all,
            Target.Free,
            Target.First,
            Target.Last,
            Target.Length,
            Source.Nodes.all,
            Source.Elements.all,
            Source.Free,
            Source.First,
            Source.Last,
            Source.Length);
      end Merge;

      ----------
      -- Sort --
      ----------

      procedure Sort (Container : in out List) is
      begin
         if Container.Length <= 1 then
            return;
         end if;
         Sorting_Ops.Sort
           (Container.Nodes.all,
            Container.Elements.all,
            Container.Free,
            Container.First,
            Container.Last,
            Container.Length);
      end Sort;

   end Generic_Sorting;

   -----------------
   -- Has_Element --
   -----------------

   function Has_Element (Container : List; Position : Cursor) return Boolean is
   begin
      return
        Position.Node /= 0
        and then Container.Nodes /= null
        and then Position.Node <= Container.Nodes'Last
        and then
          (Container.Free >= 0 or else Position.Node <= -(1 + Container.Free))
        and then Container.Nodes (Position.Node).Prev /= -1;
   end Has_Element;

   ------------
   -- Insert --
   ------------

   procedure Insert
     (Container : in out List;
      Before    : Cursor;
      New_Item  : Element_Type;
      Position  : out Cursor;
      Count     : Count_Type) is
   begin
      if Before.Node /= 0 and then not Has_Element (Container, Before) then
         raise Program_Error
           with "Before cursor designates no element in Container";
      end if;
      if Count = 0 then
         Position := Before;
         return;
      end if;
      Ensure_Capacity (Container, Container.Length + Count);
      Ops.Insert
        (Container.Nodes.all,
         Container.Elements.all,
         Container.Free,
         Container.First,
         Container.Last,
         Container.Length,
         Before.Node,
         New_Item,
         Position.Node,
         Count);
   end Insert;

   procedure Insert
     (Container : in out List;
      Before    : Cursor;
      New_Item  : Element_Type;
      Position  : out Cursor) is
   begin
      Insert (Container, Before, New_Item, Position, 1);
   end Insert;

   procedure Insert
     (Container : in out List;
      Before    : Cursor;
      New_Item  : Element_Type;
      Count     : Count_Type)
   is
      Position : Cursor;
   begin
      Insert (Container, Before, New_Item, Position, Count);
   end Insert;

   procedure Insert
     (Container : in out List; Before : Cursor; New_Item : Element_Type)
   is
      Position : Cursor;
   begin
      Insert (Container, Before, New_Item, Position, 1);
   end Insert;

   --------------
   -- Is_Empty --
   --------------

   function Is_Empty (Container : List) return Boolean
   is (Container.Length = 0);

   ----------
   -- Last --
   ----------

   function Last (Container : List) return Cursor
   is ((Node => Container.Last));

   ------------------
   -- Last_Element --
   ------------------

   function Last_Element (Container : List) return Element_Type is
   begin
      if Container.Last = 0 then
         raise Constraint_Error with "list is empty";
      end if;
      return Ops.Element (Container.Elements.all, Container.Last);
   end Last_Element;

   ------------
   -- Length --
   ------------

   function Length (Container : List) return Count_Type
   is (Container.Length);

   ----------
   -- Move --
   ----------

   procedure Move (Target : in out List; Source : in out List) is
   begin
      if Target'Address = Source'Address then
         raise Program_Error with "Source and Target are aliases";
      end if;
      Clear (Target);
      if Source.Length = 0 then
         return;
      end if;
      if Target.Nodes = null or else Target.Nodes'Length < Source.Length then
         --  Storage is replaced without rollback. An allocation failure can
         --  leave Target with only part of its backing storage; recovery from
         --  Storage_Error is not supported.
         Free_Elements (Target.Elements);
         Free_Nodes (Target.Nodes);
         Target.Nodes := new Node_Array (1 .. Source.Length);
         Target.Elements := new Elements_Array (1 .. Source.Length);
         Target.Free := -1;
      end if;
      Ops.Move
        (Target.Nodes.all,
         Target.Elements.all,
         Target.Free,
         Target.First,
         Target.Last,
         Target.Length,
         Source.Nodes.all,
         Source.Elements.all,
         Source.Free,
         Source.First,
         Source.Last,
         Source.Length);
   end Move;

   ----------
   -- Next --
   ----------

   procedure Next (Container : List; Position : in out Cursor) is
   begin
      Position := Next (Container, Position);
   end Next;

   function Next (Container : List; Position : Cursor) return Cursor is
   begin
      if Position.Node = 0 then
         return No_Element;
      elsif not Has_Element (Container, Position) then
         raise Program_Error
           with "Position cursor designates no element in Container";
      end if;
      return (Node => Container.Nodes (Position.Node).Next);
   end Next;

   -------------
   -- Prepend --
   -------------

   procedure Prepend (Container : in out List; New_Item : Element_Type) is
   begin
      Insert (Container, First (Container), New_Item, 1);
   end Prepend;

   procedure Prepend
     (Container : in out List; New_Item : Element_Type; Count : Count_Type) is
   begin
      Insert (Container, First (Container), New_Item, Count);
   end Prepend;

   --------------
   -- Previous --
   --------------

   procedure Previous (Container : List; Position : in out Cursor) is
   begin
      Position := Previous (Container, Position);
   end Previous;

   function Previous (Container : List; Position : Cursor) return Cursor is
   begin
      if Position.Node = 0 then
         return No_Element;
      elsif not Has_Element (Container, Position) then
         raise Program_Error
           with "Position cursor designates no element in Container";
      end if;
      return (Node => Container.Nodes (Position.Node).Prev);
   end Previous;

   ---------------
   -- Reference --
   ---------------

   function Reference
     (Container : List; Position : Cursor) return not null access Element_Type
   is
   begin
      if Position.Node = 0 then
         raise Constraint_Error with "Position cursor has no element";
      elsif not Has_Element (Container, Position) then
         raise Program_Error
           with "Position cursor designates no element in Container";
      end if;
      return Cells.Reference (Container.Elements (Position.Node));
   end Reference;

   ---------------------
   -- Replace_Element --
   ---------------------

   procedure Replace_Element
     (Container : in out List; Position : Cursor; New_Item : Element_Type) is
   begin
      if Position.Node = 0 then
         raise Constraint_Error with "Position cursor has no element";
      elsif not Has_Element (Container, Position) then
         raise Program_Error
           with "Position cursor designates no element in Container";
      end if;
      Ops.Replace_Element (Container.Elements (Position.Node), New_Item);
   end Replace_Element;

   ----------------------
   -- Reverse_Elements --
   ----------------------

   procedure Reverse_Elements (Container : in out List) is
   begin
      if Container.Length <= 1 then
         return;
      end if;
      Ops.Reverse_Elements
        (Container.Nodes.all,
         Container.Free,
         Container.First,
         Container.Last,
         Container.Length);
   end Reverse_Elements;

   ------------------
   -- Reverse_Find --
   ------------------

   function Reverse_Find
     (Container : List; Item : Element_Type; Position : Cursor := No_Element)
      return Cursor is
   begin
      if Position.Node /= 0 and then not Has_Element (Container, Position) then
         raise Program_Error
           with "Position cursor designates no element in Container";
      end if;
      if Position.Node = 0 and then Container.Length = 0 then
         return No_Element;
      end if;
      return
        (Node =>
           Ops.Reverse_Find
             (Container.Nodes.all,
              Container.Elements.all,
              Container.Free,
              Container.First,
              Container.Last,
              Container.Length,
              Item,
              Position.Node));
   end Reverse_Find;

   ------------
   -- Splice --
   ------------

   procedure Splice
     (Target : in out List; Before : Cursor; Source : in out List) is
   begin
      if Target'Address = Source'Address then
         raise Program_Error with "Target and Source denote same container";
      end if;
      if Before.Node /= 0 and then not Has_Element (Target, Before) then
         raise Program_Error
           with "Before cursor designates no element in Target";
      end if;
      if Source.Length = 0 then
         return;
      end if;
      Ensure_Capacity (Target, Target.Length + Source.Length);
      Ops.Splice
        (Target.Nodes.all,
         Target.Elements.all,
         Target.Free,
         Target.First,
         Target.Last,
         Target.Length,
         Source.Nodes.all,
         Source.Elements.all,
         Source.Free,
         Source.First,
         Source.Last,
         Source.Length,
         Before.Node);
   end Splice;

   procedure Splice
     (Target   : in out List;
      Before   : Cursor;
      Source   : in out List;
      Position : in out Cursor) is
   begin
      if Target'Address = Source'Address then
         raise Program_Error with "Target and Source denote same container";
      end if;
      if Position.Node = 0 then
         raise Constraint_Error with "Position cursor has no element";
      elsif not Has_Element (Source, Position) then
         raise Program_Error
           with "Position cursor designates no element in Source";
      end if;
      if Before.Node /= 0 and then not Has_Element (Target, Before) then
         raise Program_Error
           with "Before cursor designates no element in Target";
      end if;
      Ensure_Capacity (Target, Target.Length + 1);
      Ops.Splice
        (Target.Nodes.all,
         Target.Elements.all,
         Target.Free,
         Target.First,
         Target.Last,
         Target.Length,
         Source.Nodes.all,
         Source.Elements.all,
         Source.Free,
         Source.First,
         Source.Last,
         Source.Length,
         Before.Node,
         Position.Node);
   end Splice;

   procedure Splice
     (Container : in out List; Before : Cursor; Position : Cursor) is
   begin
      if Position.Node = 0 then
         raise Constraint_Error with "Position cursor has no element";
      elsif not Has_Element (Container, Position) then
         raise Program_Error
           with "Position cursor designates no element in Container";
      end if;
      if Before.Node /= 0 and then not Has_Element (Container, Before) then
         raise Program_Error
           with "Before cursor designates no element in Container";
      end if;
      Ops.Splice
        (Container.Nodes.all,
         Container.Free,
         Container.First,
         Container.Last,
         Container.Length,
         Before.Node,
         Position.Node);
   end Splice;

   ----------
   -- Swap --
   ----------

   procedure Swap (Container : in out List; I : Cursor; J : Cursor) is
   begin
      if I.Node = 0 then
         raise Constraint_Error with "I cursor has no element";
      end if;
      if J.Node = 0 then
         raise Constraint_Error with "J cursor has no element";
      end if;
      if not Has_Element (Container, I) then
         raise Program_Error
           with "I cursor designates no element in Container";
      end if;
      if not Has_Element (Container, J) then
         raise Program_Error
           with "J cursor designates no element in Container";
      end if;
      if I.Node = J.Node then
         return;
      end if;
      Ops.Swap
        (Container.Nodes.all,
         Container.Elements.all,
         Container.Free,
         I.Node,
         J.Node);
   end Swap;

   ----------------
   -- Swap_Links --
   ----------------

   procedure Swap_Links (Container : in out List; I : Cursor; J : Cursor) is
   begin
      if I.Node = 0 then
         raise Constraint_Error with "I cursor has no element";
      end if;
      if J.Node = 0 then
         raise Constraint_Error with "J cursor has no element";
      end if;
      if not Has_Element (Container, I) then
         raise Program_Error
           with "I cursor designates no element in Container";
      end if;
      if not Has_Element (Container, J) then
         raise Program_Error
           with "J cursor designates no element in Container";
      end if;
      if I.Node = J.Node then
         return;
      end if;
      Ops.Swap_Links
        (Container.Nodes.all,
         Container.Free,
         Container.First,
         Container.Last,
         Container.Length,
         I.Node,
         J.Node);
   end Swap_Links;

end SPARK.Containers.Formal.Unbounded_Doubly_Linked_Lists;
