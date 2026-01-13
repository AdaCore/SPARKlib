--
--  Copyright (C) 2025, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with Ada.Unchecked_Deallocation;

package body SPARK.Containers.Functional.Trees
  with SPARK_Mode => Off
is

   package Conversions is new Signed_Conversions (Int => Count_Type);
   use Conversions;

   function Find_Child
     (L : Controlled_List; W : Way_Type) return List_Cell_Access;
   --  Look for the list cell with way W in L if any

   ---------
   -- "=" --
   ---------

   function "=" (Left, Right : Tree) return Boolean is

      function Eq (Left, Right : Controlled_Tree) return Boolean;
      --  Recursive definition of equality on trees

      --------
      -- Eq --
      --------

      function Eq (Left, Right : Controlled_Tree) return Boolean is
      begin
         if Left.T_Access = Right.T_Access then
            return True;

         elsif Left.T_Access = null
           or else Right.T_Access = null
           or else
             Get (Left.T_Access.Value).all /= Get (Right.T_Access.Value).all
           or else Left.T_Access.Count /= Right.T_Access.Count
           or else Left.T_Access.Height /= Right.T_Access.Height
         then
            return False;

         elsif Left.T_Access.Children = Right.T_Access.Children then
            return True;
         end if;

         --  Only go over the element of Left. Right cannot have more elements
         --  as their Count matches.

         declare
            Left_Child : Controlled_List := Left.T_Access.Children;
         begin
            while Left_Child.L_Access /= null loop
               declare
                  Right_Child : constant List_Cell_Access :=
                    Find_Child
                      (Right.T_Access.Children, Left_Child.L_Access.Way);
               begin
                  if Right_Child = null
                    or else not Eq (Left_Child.L_Access.Tree, Right_Child.Tree)
                  then
                     return False;
                  end if;
               end;
               Left_Child := Left_Child.L_Access.Next_Sibling;
            end loop;
         end;

         return True;
      end Eq;

   begin
      return Eq (Left.Base, Right.Base);
   end "=";

   ------------
   -- Adjust --
   ------------

   procedure Adjust (Container : in out Controlled_List) is
   begin
      if Container.L_Access /= null then
         Container.L_Access.Reference_Count :=
           Container.L_Access.Reference_Count + 1;
      end if;
   end Adjust;

   procedure Adjust (Container : in out Controlled_Tree) is
   begin
      if Container.T_Access /= null then
         Container.T_Access.Reference_Count :=
           Container.T_Access.Reference_Count + 1;
      end if;
   end Adjust;

   -----------
   -- Child --
   -----------

   function Child (Container : Tree; W : Way_Type) return Tree is
      C : constant List_Cell_Access :=
        Find_Child (Container.Base.T_Access.Children, W);
   begin
      if C = null then
         return Empty_Tree;
      else
         return (Base => C.Tree);
      end if;
   end Child;

   -----------
   -- Count --
   -----------

   function Count (Container : Tree) return Big_Natural
   is (if Container.Base.T_Access = null
       then 0
       else Container.Base.T_Access.Count);

   --------------------
   -- Count_Children --
   --------------------

   function Count_Children
     (Container : Tree; Way : Way_Type) return Big_Natural
   is
      Count : Big_Natural := 0;
      Child : Controlled_List := Container.Base.T_Access.Children;
   begin
      while Child.L_Access /= null loop
         if Child.L_Access.Way >= Way
           and then Child.L_Access.Tree.T_Access /= null
         then
            Count := Count + Child.L_Access.Tree.T_Access.Count;
         end if;
         Child := Child.L_Access.Next_Sibling;
      end loop;
      return Count;
   end Count_Children;

   ------------
   -- Create --
   ------------

   function Create (Item : Element_Type) return Tree is
   begin
      return R : Tree do
         R.Base.T_Access :=
           new Tree_Base'
             (Reference_Count => 1,
              Value           => Create_Holder (Item),
              others          => <>);
      end return;
   end Create;

   function Create (Item : Element_Type; Children : Tree_Array) return Tree is
      Height     : Count_Type := 1;
      Count      : Big_Positive := 1;
      R_Children : Controlled_List;

   begin
      for W in Children'Range loop
         if Children (W).Base.T_Access /= null then
            declare
               C_Height : constant Count_Type :=
                 Children (W).Base.T_Access.Height;
               C_Count  : constant Big_Positive :=
                 Children (W).Base.T_Access.Count;
            begin
               R_Children :=
                 Create
                   (new List_Cell'
                      (Reference_Count => 1,
                       Way             => W,
                       Tree            => Children (W).Base,
                       Next_Sibling    => R_Children));
               Count := Count + C_Count;
               Height := Count_Type'Max (C_Height + 1, Height);
            end;
         end if;
      end loop;

      return R : Tree do
         R.Base.T_Access :=
           new Tree_Base'
             (Reference_Count => 1,
              Value           => Create_Holder (Item),
              Children        => R_Children,
              Count           => Count,
              Height          => Height);
      end return;
   end Create;

   -------------------------
   -- Element_Logic_Equal --
   -------------------------

   function Element_Logic_Equal (Left, Right : Element_Type) return Boolean
   is (Left = Right);

   ----------------
   -- Empty_Tree --
   ----------------

   function Empty_Tree return Tree
   is ((Base => Create (null)));

   --------------
   -- Finalize --
   --------------

   procedure Finalize (Container : in out Controlled_List) is
      procedure Unchecked_Free_Cell is new
        Ada.Unchecked_Deallocation
          (Object => List_Cell,
           Name   => List_Cell_Access);

   begin
      if Container.L_Access /= null then
         Container.L_Access.Reference_Count :=
           Container.L_Access.Reference_Count - 1;
         if Container.L_Access.Reference_Count = 0 then
            Unchecked_Free_Cell (Container.L_Access);
         end if;
         Container.L_Access := null;
      end if;
   end Finalize;

   procedure Finalize (Container : in out Controlled_Tree) is
      procedure Unchecked_Free_Base is new
        Ada.Unchecked_Deallocation
          (Object => Tree_Base,
           Name   => Tree_Base_Access);

   begin
      if Container.T_Access /= null then
         Container.T_Access.Reference_Count :=
           Container.T_Access.Reference_Count - 1;
         if Container.T_Access.Reference_Count = 0 then
            Unchecked_Free_Base (Container.T_Access);
         end if;
         Container.T_Access := null;
      end if;
   end Finalize;

   ----------------
   -- Find_Child --
   ----------------

   function Find_Child
     (L : Controlled_List; W : Way_Type) return List_Cell_Access
   is
      Child : Controlled_List := L;
   begin
      while Child.L_Access /= null loop
         if Child.L_Access.Way = W then
            exit;
         end if;
         Child := Child.L_Access.Next_Sibling;
      end loop;

      return Child.L_Access;
   end Find_Child;

   ---------
   -- Get --
   ---------

   function Get (Container : Tree) return Element_Type is
   begin
      return Get (Container.Base.T_Access.Value).all;
   end Get;

   -----------
   -- Height --
   -----------

   function Height (Container : Tree) return Big_Natural
   is (if Container.Base.T_Access = null
       then 0
       else To_Big_Integer (Container.Base.T_Access.Height));

   --------------
   -- Is_Empty --
   --------------

   function Is_Empty (Container : Tree) return Boolean
   is (Container.Base.T_Access = null);

   -------------------------------
   -- Lemma_Count_Children_Tail --
   -------------------------------

   procedure Lemma_Count_Children_Tail (Container : Tree; Way : Way_Type)
   is null;

   --------------------------
   -- Lemma_Eq_Extensional --
   --------------------------

   procedure Lemma_Eq_Extensional (X, Y : Tree) is null;

   ------------------------
   -- Lemma_Eq_Reflexive --
   ------------------------

   procedure Lemma_Eq_Reflexive (X : Tree) is null;

   ------------------------
   -- Lemma_Eq_Symmetric --
   ------------------------

   procedure Lemma_Eq_Symmetric (X, Y : Tree) is null;

   -------------------------
   -- Lemma_Eq_Transitive --
   -------------------------

   procedure Lemma_Eq_Transtive (X, Y, Z : Tree) is null;

   ---------------
   -- Set_Child --
   ---------------

   function Set_Child
     (Container : Tree; Way : Way_Type; New_Child : Tree) return Tree
   is
      --  Traverse the children list once to find Way if any

      Old_Child : constant List_Cell_Access :=
        Find_Child (Container.Base.T_Access.Children, Way);
      C_Count   : constant Big_Integer :=
        (if New_Child.Base.T_Access = null
         then 0
         else New_Child.Base.T_Access.Count);
      --  Use Big_Integer instead of Big_Natural to avoid Program_Error in
      --  predicate check.
      C_Height  : constant Count_Type :=
        (if New_Child.Base.T_Access = null
         then 0
         else New_Child.Base.T_Access.Height);
   begin
      return R : Tree do
         if Old_Child = null then
            if New_Child.Base.T_Access = null then
               R := Container;
            else
               R.Base.T_Access :=
                 new Tree_Base'
                   (Reference_Count => 1,
                    Value           => Container.Base.T_Access.Value,
                    Children        =>
                      Create
                        (new List_Cell'
                           (Reference_Count => 1,
                            Way             => Way,
                            Tree            => New_Child.Base,
                            Next_Sibling    =>
                              Container.Base.T_Access.Children)),
                    Count           => Container.Base.T_Access.Count + C_Count,
                    Height          =>
                      Count_Type'Max
                        (Container.Base.T_Access.Height, C_Height + 1));
            end if;
         else
            declare
               Keep_Height : constant Boolean :=
                 Container.Base.T_Access.Height
                 /= Old_Child.Tree.T_Access.Height + 1;
               Max_Height  : Count_Type;
               R_Children  : Controlled_List := Old_Child.Next_Sibling;

            begin
               --  If Old_Child does not have the maximal Height, then the
               --  maximal Height of children of R can be computed directly.

               if Keep_Height then
                  Max_Height :=
                    Count_Type'Max
                      (C_Height, Container.Base.T_Access.Height - 1);

               --  Otherwise, go through the tail of the list to compute the
               --  new Height.

               else
                  declare
                     Current : List_Cell_Access :=
                       Old_Child.Next_Sibling.L_Access;
                  begin
                     Max_Height := C_Height;
                     while Current /= null loop
                        if Current.Tree.T_Access.Height > Max_Height then
                           Max_Height := Current.Tree.T_Access.Height;
                        end if;
                        Current := Current.Next_Sibling.L_Access;
                     end loop;
                  end;
               end if;

               --  Traverse again the first part of the list to construct a new
               --  list without Old_Child. Also update the Max_Height if
               --  necessary.

               declare
                  Current : List_Cell_Access :=
                    Container.Base.T_Access.Children.L_Access;
               begin
                  while Current /= Old_Child loop
                     if not Keep_Height
                       and then Current.Tree.T_Access.Height > Max_Height
                     then
                        Max_Height := Current.Tree.T_Access.Height;
                     end if;

                     R_Children :=
                       Create
                         (new List_Cell'
                            (Reference_Count => 1,
                             Way             => Current.Way,
                             Tree            => Current.Tree,
                             Next_Sibling    => R_Children));
                     Current := Current.Next_Sibling.L_Access;
                  end loop;
               end;

               --  Add New_Child at the top of R_Children if it is non empty

               if New_Child.Base.T_Access /= null then
                  R_Children :=
                    Create
                      (new List_Cell'
                         (Reference_Count => 1,
                          Way             => Way,
                          Tree            => New_Child.Base,
                          Next_Sibling    => R_Children));
               end if;

               R.Base.T_Access :=
                 new Tree_Base'
                   (Reference_Count => 1,
                    Value           => Container.Base.T_Access.Value,
                    Children        => R_Children,
                    Count           =>
                      Container.Base.T_Access.Count
                      - Old_Child.Tree.T_Access.Count
                      + C_Count,
                    Height          => Max_Height + 1);
            end;
         end if;
      end return;
   end Set_Child;

   --------------
   -- Set_Root --
   --------------

   function Set_Root (Container : Tree; Item : Element_Type) return Tree is
   begin
      return R : Tree do
         R.Base.T_Access :=
           new Tree_Base'
             (Reference_Count => 1,
              Value           => Create_Holder (Item),
              Children        => Container.Base.T_Access.Children,
              Count           => Container.Base.T_Access.Count,
              Height          => Container.Base.T_Access.Height);
      end return;
   end Set_Root;

   ----------------------
   -- Tree_Logic_Equal --
   ----------------------

   function Tree_Logic_Equal (Left, Right : Tree) return Boolean
   is (Left = Right);

end SPARK.Containers.Functional.Trees;
