--
--  Copyright (C) 2016-2024, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

package body SPARK.Containers.Functional.Sets with SPARK_Mode => Off is
   use Containers;

   package Conversions is new Signed_Conversions (Int => Count_Type);
   use Conversions;

   ---------
   -- "=" --
   ---------

   function "=" (Left : Set; Right : Set) return Boolean is
     (Length (Right) = Length (Left) and then Left.Content <= Right.Content);

   ----------
   -- "<=" --
   ----------

   function "<=" (Left : Set; Right : Set) return Boolean is
     (Left.Content <= Right.Content);

   ---------
   -- Add --
   ---------

   function Add (Container : Set; Item : Element_Type) return Set is
     (Content =>
       Add (Container.Content, Length (Container.Content) + 1, Item));

   ------------------
   -- Aggr_Include --
   ------------------

   procedure Aggr_Include (Container : in out Set; Item : Element_Type) is
   begin
      Container := Add (Container, Item);
   end Aggr_Include;

   --------------
   -- Contains --
   --------------

   function Contains (Container : Set; Item : Element_Type) return Boolean is
     (Find_Rev (Container.Content, Item) > 0);

   ------------
   -- Choose --
   ------------

   function Choose (Container : Set) return Element_Type is
     (Get (Container.Content, Length (Container.Content)));

   ---------------
   -- Empty_Set --
   ---------------

   function Empty_Set return Set is
      ((others => <>));

   ---------------------
   -- Included_Except --
   ---------------------

   function Included_Except
     (Left  : Set;
      Right : Set;
      Item  : Element_Type) return Boolean
   is
   begin
      for I in 1 .. Length (Left.Content) loop
         if not Equivalent_Elements (Get (Left.Content, I), Item)
           and then Find (Right.Content, Get (Left.Content, I)) = 0
         then
            return False;
         end if;
      end loop;

      return True;
   end Included_Except;

   -----------------------
   -- Included_In_Union --
   -----------------------

   function Included_In_Union
     (Container : Set;
      Left      : Set;
      Right     : Set) return Boolean
   is
   begin
      for I in 1 .. Length (Container.Content) loop
         if Find (Left.Content, Get (Container.Content, I)) = 0
           and then Find (Right.Content, Get (Container.Content, I)) = 0
         then
            return False;
         end if;
      end loop;

      return True;
   end Included_In_Union;

   ---------------------------
   -- Includes_Intersection --
   ---------------------------

   function Includes_Intersection
     (Container : Set;
      Left      : Set;
      Right     : Set) return Boolean
   is
   begin
      for I in 1 .. Length (Left.Content) loop
         if Find (Right.Content, Get (Left.Content, I)) /= 0
           and then Find (Container.Content, Get (Left.Content, I)) = 0
         then
            return False;
         end if;
      end loop;

      return True;
   end Includes_Intersection;

   ------------------
   -- Intersection --
   ------------------

   function Intersection (Left : Set; Right : Set) return Set is
     (Content => Intersection (Left.Content, Right.Content));

   --------------
   -- Is_Empty --
   --------------

   function Is_Empty (Container : Set) return Boolean is
     (Length (Container.Content) = 0);

   ------------------
   -- Is_Singleton --
   ------------------

   function Is_Singleton
     (Container : Set;
      New_Item  : Element_Type) return Boolean
   is
     (Length (Container.Content) = 1
        and then New_Item = Get (Container.Content, 1));

   ------------------
   -- Iter_Element --
   ------------------

   function Iter_Element
     (Container : Set;
      Key       : Private_Key) return Element_Type
   is
   begin
      Check_Or_Fail;
      return Containers.Get (Container.Content, Count_Type (Key));
   end Iter_Element;

   ----------------
   -- Iter_First --
   ----------------

   function Iter_First (Container : Set) return Private_Key is
      pragma Unreferenced (Container);
   begin
      Check_Or_Fail;
      return 1;
   end Iter_First;

   ----------------------
   -- Iter_Has_Element --
   ----------------------

   function Iter_Has_Element
     (Container : Set;
      Key       : Private_Key) return Boolean
   is
   begin
      Check_Or_Fail;
      return  Count_Type (Key) in 1 .. Containers.Length (Container.Content);
   end Iter_Has_Element;

   ---------------
   -- Iter_Next --
   ---------------

   function Iter_Next
     (Container : Set;
      Key       : Private_Key) return Private_Key
   is
      pragma Unreferenced (Container);
   begin
      Check_Or_Fail;
      return (if Key = Private_Key'Last then 0 else Key + 1);
   end Iter_Next;

   -------------------------------
   -- Lemma_Contains_Equivalent --
   -------------------------------

   procedure Lemma_Contains_Equivalent
     (Container : Set;
      Item      : Element_Type)
   is null;

   ------------
   -- Length --
   ------------

   function Length (Container : Set) return Big_Natural is
     (To_Big_Integer (Length (Container.Content)));

   -----------------
   -- Not_In_Both --
   -----------------

   function Not_In_Both
     (Container : Set;
      Left      : Set;
      Right     : Set) return Boolean
   is
   begin
      for I in 1 .. Length (Container.Content) loop
         if Find (Left.Content, Get (Container.Content, I)) /= 0
           and then Find (Right.Content, Get (Container.Content, I)) /= 0
         then
            return False;
         end if;
      end loop;

      return True;
   end Not_In_Both;

   ----------------
   -- No_Overlap --
   ----------------

   function No_Overlap (Left : Set; Right : Set) return Boolean is
     (Num_Overlaps (Left.Content, Right.Content) = 0);

   ------------------
   -- Num_Overlaps --
   ------------------

   function Num_Overlaps (Left : Set; Right : Set) return Big_Natural is
     (To_Big_Integer (Num_Overlaps (Left.Content, Right.Content)));

   ------------
   -- Remove --
   ------------

   function Remove (Container : Set; Item : Element_Type) return Set is
     (Content =>
         Remove (Container.Content, Find_Rev (Container.Content, Item)));

   -----------
   -- Union --
   -----------

   function Union (Left : Set; Right : Set) return Set is
     (Content => Union (Left.Content, Right.Content));

end SPARK.Containers.Functional.Sets;
