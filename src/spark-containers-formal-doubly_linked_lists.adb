--
--  Copyright (C) 2004-2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with SPARK.Containers.Formal.Doubly_Linked_Lists.Impl;

package body SPARK.Containers.Formal.Doubly_Linked_Lists
  with SPARK_Mode => Off
is

   package List_Impl is new SPARK.Containers.Formal.Doubly_Linked_Lists.Impl;

   ---------
   -- "=" --
   ---------

   function "=" (Left : List; Right : List) return Boolean
   is (List_Impl."=" (Left, Right));

   ------------
   -- Append --
   ------------

   procedure Append (Container : in out List; New_Item : Element_Type)
   renames List_Impl.Append;

   procedure Append
     (Container : in out List; New_Item : Element_Type; Count : Count_Type)
   renames List_Impl.Append;

   ------------
   -- Assign --
   ------------

   procedure Assign (Target : in out List; Source : List)
   renames List_Impl.Assign;

   -----------
   -- Clear --
   -----------

   procedure Clear (Container : in out List) renames List_Impl.Clear;

   ------------------------
   -- Constant_Reference --
   ------------------------

   function Constant_Reference
     (Container : aliased List; Position : Cursor)
      return not null access constant Element_Type
   renames List_Impl.Constant_Reference;

   --------------
   -- Contains --
   --------------

   function Contains (Container : List; Item : Element_Type) return Boolean
   renames List_Impl.Contains;

   ----------
   -- Copy --
   ----------

   function Copy (Source : List; Capacity : Count_Type := 0) return List
   renames List_Impl.Copy;

   ------------
   -- Delete --
   ------------

   procedure Delete (Container : in out List; Position : in out Cursor)
   renames List_Impl.Delete;

   procedure Delete
     (Container : in out List; Position : in out Cursor; Count : Count_Type)
   renames List_Impl.Delete;

   ------------------
   -- Delete_First --
   ------------------

   procedure Delete_First (Container : in out List)
   renames List_Impl.Delete_First;

   procedure Delete_First (Container : in out List; Count : Count_Type)
   renames List_Impl.Delete_First;

   -----------------
   -- Delete_Last --
   -----------------

   procedure Delete_Last (Container : in out List)
   renames List_Impl.Delete_Last;

   procedure Delete_Last (Container : in out List; Count : Count_Type)
   renames List_Impl.Delete_Last;

   -------------
   -- Element --
   -------------

   function Element (Container : List; Position : Cursor) return Element_Type
   renames List_Impl.Element;

   ----------------
   -- Empty_List --
   ----------------

   function Empty_List (Capacity : Count_Type := 10) return List
   renames List_Impl.Empty_List;

   ----------
   -- Find --
   ----------

   function Find
     (Container : List; Item : Element_Type; Position : Cursor := No_Element)
      return Cursor
   renames List_Impl.Find;

   -----------
   -- First --
   -----------

   function First (Container : List) return Cursor renames List_Impl.First;

   -------------------
   -- First_Element --
   -------------------

   function First_Element (Container : List) return Element_Type
   renames List_Impl.First_Element;

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
         return Boolean is
      begin
         for Index in 1 .. M.Last (Container) loop
            declare
               Found : Boolean := False;
            begin
               for J in 1 .. M.Last (Left) loop
                  if Element_Logic_Equal
                       (Element (Container, Index), Element (Left, J))
                  then
                     Found := True;
                     exit;
                  end if;
               end loop;

               if not Found then
                  for J in 1 .. M.Last (Right) loop
                     if Element_Logic_Equal
                          (Element (Container, Index), Element (Right, J))
                     then
                        Found := True;
                        exit;
                     end if;
                  end loop;
               end if;

               if not Found then
                  return False;
               end if;
            end;
         end loop;

         return True;
      end M_Elements_In_Union;

      -------------------------
      -- M_Elements_Included --
      -------------------------

      function M_Elements_Included
        (Left  : M.Sequence;
         L_Fst : Positive_Count_Type := 1;
         L_Lst : Count_Type;
         Right : M.Sequence;
         R_Fst : Positive_Count_Type := 1;
         R_Lst : Count_Type) return Boolean is
      begin
         for I in L_Fst .. L_Lst loop
            declare
               Found : Boolean := False;
               J     : Count_Type := R_Fst - 1;

            begin
               while not Found and J < R_Lst loop
                  J := J + 1;
                  if Element_Logic_Equal
                       (Element (Left, I), Element (Right, J))
                  then
                     Found := True;
                  end if;
               end loop;

               if not Found then
                  return False;
               end if;
            end;
         end loop;

         return True;
      end M_Elements_Included;

      -------------------------
      -- M_Elements_Reversed --
      -------------------------

      function M_Elements_Reversed
        (Left : M.Sequence; Right : M.Sequence) return Boolean
      is
         L : constant M.Extended_Index := M.Last (Left);

      begin
         if L /= M.Last (Right) then
            return False;
         end if;

         for I in 1 .. L loop
            if not Element_Logic_Equal
                     (Element (Left, I), Element (Right, L - I + 1))
            then
               return False;
            end if;
         end loop;

         return True;
      end M_Elements_Reversed;

      ------------------------
      -- M_Elements_Swapped --
      ------------------------

      function M_Elements_Swapped
        (Left  : M.Sequence;
         Right : M.Sequence;
         X     : Positive_Count_Type;
         Y     : Positive_Count_Type) return Boolean is
      begin
         if M.Last (Left) /= M.Last (Right)
           or else
             not Element_Logic_Equal (Element (Left, X), Element (Right, Y))
           or else
             not Element_Logic_Equal (Element (Left, Y), Element (Right, X))
         then
            return False;
         end if;

         for I in 1 .. M.Last (Left) loop
            if I /= X
              and then I /= Y
              and then
                not Element_Logic_Equal (Element (Left, I), Element (Right, I))
            then
               return False;
            end if;
         end loop;

         return True;
      end M_Elements_Swapped;

      -----------------------
      -- Mapping_Preserved --
      -----------------------

      function Mapping_Preserved
        (M_Left  : M.Sequence;
         M_Right : M.Sequence;
         P_Left  : P.Map;
         P_Right : P.Map) return Boolean is
      begin
         for C of P_Left loop
            if not P.Has_Key (P_Right, C)
              or else P.Get (P_Left, C) > M.Last (M_Left)
              or else P.Get (P_Right, C) > M.Last (M_Right)
              or else
                not Element_Logic_Equal
                      (M.Get (M_Left, P.Get (P_Left, C)),
                       M.Get (M_Right, P.Get (P_Right, C)))
            then
               return False;
            end if;
         end loop;

         for C of P_Right loop
            if not P.Has_Key (P_Left, C) then
               return False;
            end if;
         end loop;

         return True;
      end Mapping_Preserved;

      -----------
      -- Model --
      -----------

      function Model (Container : List) return M.Sequence
      renames List_Impl.Model;

      -------------------------
      -- P_Positions_Shifted --
      -------------------------

      function P_Positions_Shifted
        (Small : P.Map;
         Big   : P.Map;
         Cut   : Positive_Count_Type;
         Count : Count_Type := 1) return Boolean is
      begin
         for Cu of P.Iterate (Small) loop
            if not P.Has_Key (Big, Cu) then
               return False;
            end if;
         end loop;

         for Cu of P.Iterate (Big) loop
            declare
               Pos : constant Positive_Count_Type := P.Get (Big, Cu);

            begin
               if Pos < Cut then
                  if not P.Has_Key (Small, Cu) or else Pos /= P.Get (Small, Cu)
                  then
                     return False;
                  end if;

               elsif Pos >= Cut + Count then
                  if not P.Has_Key (Small, Cu)
                    or else Pos /= P.Get (Small, Cu) + Count
                  then
                     return False;
                  end if;

               else
                  if P.Has_Key (Small, Cu) then
                     return False;
                  end if;
               end if;
            end;
         end loop;

         return True;
      end P_Positions_Shifted;

      -------------------------
      -- P_Positions_Swapped --
      -------------------------

      function P_Positions_Swapped
        (Left : P.Map; Right : P.Map; X : Cursor; Y : Cursor) return Boolean is
      begin
         if not P.Has_Key (Left, X)
           or not P.Has_Key (Left, Y)
           or not P.Has_Key (Right, X)
           or not P.Has_Key (Right, Y)
         then
            return False;
         end if;

         if P.Get (Left, X) /= P.Get (Right, Y)
           or P.Get (Left, Y) /= P.Get (Right, X)
         then
            return False;
         end if;

         for C of P.Iterate (Left) loop
            if not P.Has_Key (Right, C) then
               return False;
            end if;
         end loop;

         for C of P.Iterate (Right) loop
            if not P.Has_Key (Left, C)
              or else
                (C /= X and C /= Y and P.Get (Left, C) /= P.Get (Right, C))
            then
               return False;
            end if;
         end loop;

         return True;
      end P_Positions_Swapped;

      ---------------------------
      -- P_Positions_Truncated --
      ---------------------------

      function P_Positions_Truncated
        (Small : P.Map;
         Big   : P.Map;
         Cut   : Positive_Count_Type;
         Count : Count_Type := 1) return Boolean is
      begin
         for Cu of P.Iterate (Small) loop
            if not P.Has_Key (Big, Cu) then
               return False;
            end if;
         end loop;

         for Cu of P.Iterate (Big) loop
            declare
               Pos : constant Positive_Count_Type := P.Get (Big, Cu);

            begin
               if Pos < Cut then
                  if not P.Has_Key (Small, Cu) or else Pos /= P.Get (Small, Cu)
                  then
                     return False;
                  end if;

               elsif Pos >= Cut + Count then
                  return False;

               elsif P.Has_Key (Small, Cu) then
                  return False;
               end if;
            end;
         end loop;

         return True;
      end P_Positions_Truncated;

      ---------------
      -- Positions --
      ---------------

      function Positions (Container : List) return P.Map
      renames List_Impl.Positions;

   end Formal_Model;

   ---------------------
   -- Generic_Sorting --
   ---------------------

   package body Generic_Sorting
     with SPARK_Mode => Off
   is
      package Sorting_Impl is new List_Impl.Generic_Sorting ("<");

      ------------------
      -- Formal_Model --
      ------------------

      package body Formal_Model is

         -----------------------
         -- M_Elements_Sorted --
         -----------------------

         function M_Elements_Sorted (Container : M.Sequence) return Boolean is
         begin
            if M.Length (Container) = 0 then
               return True;
            end if;

            declare
               E1 : Element_Type := Element (Container, 1);

            begin
               for I in 2 .. M.Last (Container) loop
                  declare
                     E2 : constant Element_Type := Element (Container, I);

                  begin
                     if E2 < E1 then
                        return False;
                     end if;

                     E1 := E2;
                  end;
               end loop;
            end;

            return True;
         end M_Elements_Sorted;

      end Formal_Model;

      ---------------
      -- Is_Sorted --
      ---------------

      function Is_Sorted (Container : List) return Boolean
      renames Sorting_Impl.Is_Sorted;

      -----------
      -- Merge --
      -----------

      procedure Merge (Target : in out List; Source : in out List)
      renames Sorting_Impl.Merge;

      ----------
      -- Sort --
      ----------

      procedure Sort (Container : in out List) renames Sorting_Impl.Sort;

   end Generic_Sorting;

   -----------------
   -- Has_Element --
   -----------------

   function Has_Element (Container : List; Position : Cursor) return Boolean
   renames List_Impl.Has_Element;

   ------------
   -- Insert --
   ------------

   procedure Insert
     (Container : in out List;
      Before    : Cursor;
      New_Item  : Element_Type;
      Position  : out Cursor;
      Count     : Count_Type)
   renames List_Impl.Insert;

   procedure Insert
     (Container : in out List;
      Before    : Cursor;
      New_Item  : Element_Type;
      Position  : out Cursor)
   renames List_Impl.Insert;

   procedure Insert
     (Container : in out List;
      Before    : Cursor;
      New_Item  : Element_Type;
      Count     : Count_Type)
   renames List_Impl.Insert;

   procedure Insert
     (Container : in out List; Before : Cursor; New_Item : Element_Type)
   renames List_Impl.Insert;

   ----------
   -- Last --
   ----------

   function Last (Container : List) return Cursor renames List_Impl.Last;

   ------------------
   -- Last_Element --
   ------------------

   function Last_Element (Container : List) return Element_Type
   renames List_Impl.Last_Element;

   ----------
   -- Move --
   ----------

   procedure Move (Target : in out List; Source : in out List)
   renames List_Impl.Move;

   ----------
   -- Next --
   ----------

   procedure Next (Container : List; Position : in out Cursor)
   renames List_Impl.Next;

   function Next (Container : List; Position : Cursor) return Cursor
   renames List_Impl.Next;

   -------------
   -- Prepend --
   -------------

   procedure Prepend (Container : in out List; New_Item : Element_Type)
   renames List_Impl.Prepend;

   procedure Prepend
     (Container : in out List; New_Item : Element_Type; Count : Count_Type)
   renames List_Impl.Prepend;

   --------------
   -- Previous --
   --------------

   procedure Previous (Container : List; Position : in out Cursor)
   renames List_Impl.Previous;

   function Previous (Container : List; Position : Cursor) return Cursor
   renames List_Impl.Previous;

   ---------------
   -- Reference --
   ---------------

   function Reference
     (Container : aliased in out List; Position : Cursor)
      return not null access Element_Type
   renames List_Impl.Reference;

   ---------------------
   -- Replace_Element --
   ---------------------

   procedure Replace_Element
     (Container : in out List; Position : Cursor; New_Item : Element_Type)
   renames List_Impl.Replace_Element;

   ----------------------
   -- Reverse_Elements --
   ----------------------

   procedure Reverse_Elements (Container : in out List)
   renames List_Impl.Reverse_Elements;

   ------------------
   -- Reverse_Find --
   ------------------

   function Reverse_Find
     (Container : List; Item : Element_Type; Position : Cursor := No_Element)
      return Cursor
   renames List_Impl.Reverse_Find;

   ------------
   -- Splice --
   ------------

   procedure Splice
     (Target : in out List; Before : Cursor; Source : in out List)
   renames List_Impl.Splice;

   procedure Splice
     (Target   : in out List;
      Before   : Cursor;
      Source   : in out List;
      Position : in out Cursor)
   renames List_Impl.Splice;

   procedure Splice
     (Container : in out List; Before : Cursor; Position : Cursor)
   renames List_Impl.Splice;

   ----------
   -- Swap --
   ----------

   procedure Swap (Container : in out List; I : Cursor; J : Cursor)
   renames List_Impl.Swap;

   ----------------
   -- Swap_Links --
   ----------------

   procedure Swap_Links (Container : in out List; I : Cursor; J : Cursor)
   renames List_Impl.Swap_Links;

end SPARK.Containers.Formal.Doubly_Linked_Lists;
