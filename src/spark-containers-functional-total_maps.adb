--
--  Copyright (C) 2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

package body SPARK.Containers.Functional.Total_Maps
  with SPARK_Mode => Off --  #BODYMODE
is

   ---------
   -- "=" --
   ---------

   function "=" (Left : Map; Right : Map) return Boolean is
   begin
      for S in Maps.Iterate (Left.Content) loop
         pragma
           Loop_Invariant
             (Static =>
                (for all K of Left.Content =>
                   Maps.Has_Key (S, K)
                   or else Get (Right, K) = Get (Left, K)));
         declare
            K : constant Key_Type := Maps.Choose (S);
         begin
            if Get (Right, K) /= Get (Left, K) then
               return False;
            end if;
         end;
      end loop;

      for S in Maps.Iterate (Right.Content) loop
         pragma
           Loop_Invariant
             (Static =>
                (for all K of Right.Content =>
                   Maps.Has_Key (S, K)
                   or else
                     (if not Maps.Has_Key (Left.Content, K)
                      then Get (Right, K) = Get (Left, K))));
         declare
            K : constant Key_Type := Maps.Choose (S);
         begin
            if not Maps.Has_Key (Left.Content, K)
              and then Get (Right, K) /= Get (Left, K)
            then
               return False;
            end if;
         end;
      end loop;

      return True;
   end "=";

   ------------------
   -- Aggr_Include --
   ------------------

   procedure Aggr_Include
     (Container : in out Map; New_Key : Key_Type; New_Item : Element_Type) is
   begin
      Container := Set (Container, New_Key, New_Item);
   end Aggr_Include;

   -----------------
   -- All_Default --
   -----------------

   function All_Default (Container : Map) return Boolean is
   begin
      for S in Maps.Iterate (Container.Content) loop
         pragma
           Loop_Invariant
             (Static =>
                (for all K of Container.Content =>
                   Maps.Has_Key (S, K)
                   or else
                     Element_Logic_Equal
                       (Get (Container, K), Copy_Element (Default_Element))));
         declare
            K : constant Key_Type := Maps.Choose (S);
         begin
            if not Element_Logic_Equal
                     (Get (Container, K), Copy_Element (Default_Element))
            then
               return False;
            end if;
         end;
      end loop;
      return True;
   end All_Default;

   -----------------
   -- Default_Map --
   -----------------

   function Default_Map return Map is
   begin
      return (Content => Maps.Empty_Map);
   end Default_Map;

   -------------------------
   -- Element_Logic_Equal --
   -------------------------

   function Element_Logic_Equal (Left, Right : Element_Type) return Boolean is
   begin
      return Left = Right;
   end Element_Logic_Equal;

   ---------------------------
   -- Elements_Equal_Except --
   ---------------------------

   function Elements_Equal_Except
     (Left : Map; Right : Map; New_Key : Key_Type) return Boolean is
   begin
      for S in Maps.Iterate (Left.Content) loop
         pragma
           Loop_Invariant
             (Static =>
                (for all K of Left.Content =>
                   Maps.Has_Key (S, K)
                   or else
                     (if not Equivalent_Keys (K, New_Key)
                      then
                        Element_Logic_Equal (Get (Left, K), Get (Right, K)))));
         declare
            K : constant Key_Type := Maps.Choose (S);
         begin
            if not Equivalent_Keys (K, New_Key)
              and then not Element_Logic_Equal (Get (Left, K), Get (Right, K))
            then
               return False;
            end if;
         end;
      end loop;

      for S in Maps.Iterate (Right.Content) loop
         pragma
           Loop_Invariant
             (Static =>
                (for all K of Right.Content =>
                   Maps.Has_Key (S, K)
                   or else
                     (if not Maps.Has_Key (Left.Content, K)
                        and then not Equivalent_Keys (K, New_Key)
                      then
                        Element_Logic_Equal (Get (Left, K), Get (Right, K)))));
         declare
            K : constant Key_Type := Maps.Choose (S);
         begin
            if not Maps.Has_Key (Left.Content, K)
              and then not Equivalent_Keys (K, New_Key)
              and then not Element_Logic_Equal (Get (Left, K), Get (Right, K))
            then
               return False;
            end if;
         end;
      end loop;

      return True;
   end Elements_Equal_Except;

   function Elements_Equal_Except
     (Left : Map; Right : Map; X : Key_Type; Y : Key_Type) return Boolean is
   begin
      for S in Maps.Iterate (Left.Content) loop
         pragma
           Loop_Invariant
             (Static =>
                (for all K of Left.Content =>
                   Maps.Has_Key (S, K)
                   or else
                     (if not Equivalent_Keys (K, X)
                        and then not Equivalent_Keys (K, Y)
                      then
                        Element_Logic_Equal (Get (Left, K), Get (Right, K)))));
         declare
            K : constant Key_Type := Maps.Choose (S);
         begin
            if not Equivalent_Keys (K, X)
              and then not Equivalent_Keys (K, Y)
              and then not Element_Logic_Equal (Get (Left, K), Get (Right, K))
            then
               return False;
            end if;
         end;
      end loop;

      for S in Maps.Iterate (Right.Content) loop
         pragma
           Loop_Invariant
             (Static =>
                (for all K of Right.Content =>
                   Maps.Has_Key (S, K)
                   or else
                     (if not Maps.Has_Key (Left.Content, K)
                        and then not Equivalent_Keys (K, X)
                        and then not Equivalent_Keys (K, Y)
                      then
                        Element_Logic_Equal (Get (Left, K), Get (Right, K)))));
         declare
            K : constant Key_Type := Maps.Choose (S);
         begin
            if not Maps.Has_Key (Left.Content, K)
              and then not Equivalent_Keys (K, X)
              and then not Equivalent_Keys (K, Y)
              and then not Element_Logic_Equal (Get (Left, K), Get (Right, K))
            then
               return False;
            end if;
         end;
      end loop;

      return True;
   end Elements_Equal_Except;

   ---------------------
   -- Equivalent_Maps --
   ---------------------

   function Equivalent_Maps (Left : Map; Right : Map) return Boolean is
   begin
      for S in Maps.Iterate (Left.Content) loop
         pragma
           Loop_Invariant
             (Static =>
                (for all K of Left.Content =>
                   Maps.Has_Key (S, K)
                   or else
                     Equivalent_Elements (Get (Left, K), Get (Right, K))));
         declare
            K : constant Key_Type := Maps.Choose (S);
         begin
            if not Equivalent_Elements (Get (Left, K), Get (Right, K)) then
               return False;
            end if;
         end;
      end loop;

      for S in Maps.Iterate (Right.Content) loop
         pragma
           Loop_Invariant
             (Static =>
                (for all K of Right.Content =>
                   Maps.Has_Key (S, K)
                   or else
                     (if not Maps.Has_Key (Left.Content, K)
                      then
                        Equivalent_Elements (Get (Left, K), Get (Right, K)))));
         declare
            K : constant Key_Type := Maps.Choose (S);
         begin
            if not Maps.Has_Key (Left.Content, K)
              and then not Equivalent_Elements (Get (Left, K), Get (Right, K))
            then
               return False;
            end if;
         end;
      end loop;

      return True;
   end Equivalent_Maps;

   ------------------
   -- Iter_Element --
   ------------------

   function Iter_Element
     (Unused_Container : Map; Unused_Key : Private_Key) return Key_Type is
   begin
      return raise Program_Error;
   end Iter_Element;

   ----------------
   -- Iter_First --
   ----------------

   function Iter_First (Unused_Container : Map) return Private_Key is
   begin
      return (null record);
   end Iter_First;

   ----------------------
   -- Iter_Has_Element --
   ----------------------

   function Iter_Has_Element
     (Unused_Container : Map; Unused_Key : Private_Key) return Boolean
   is (False);

   ---------------
   -- Iter_Next --
   ---------------

   function Iter_Next
     (Unused_Container : Map; Unused_Key : Private_Key) return Private_Key is
   begin
      return (null record);
   end Iter_Next;

   --------------------------
   -- Lemma_Eq_Extensional --
   --------------------------

   procedure Lemma_Eq_Extensional (Left : Map; Right : Map)
   is null
   with SPARK_Mode => Off;

   --------------------------
   -- Lemma_Get_Equivalent --
   --------------------------

   procedure Lemma_Get_Equivalent (Container : Map; Key_1, Key_2 : Key_Type)
   is null;

   ----------------
   -- Logical_Eq --
   ----------------

   function Logical_Eq (Left, Right : Map) return Boolean
   with SPARK_Mode => Off
   is
   begin
      return Left = Right;
   end Logical_Eq;

   ---------
   -- Set --
   ---------

   function Set
     (Container : Map; Key : Key_Type; New_Item : Element_Type) return Map is
   begin
      if Maps.Has_Key (Container.Content, Key) then
         return (Content => Maps.Set (Container.Content, Key, New_Item));
      else
         return (Content => Maps.Add (Container.Content, Key, New_Item));
      end if;
   end Set;

end SPARK.Containers.Functional.Total_Maps;
