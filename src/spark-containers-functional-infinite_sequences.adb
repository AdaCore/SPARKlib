--
--  Copyright (C) 2022-2024, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

package body SPARK.Containers.Functional.Infinite_Sequences
with SPARK_Mode => Off
is
   use Containers;

   -----------------------
   -- Local Subprograms --
   -----------------------

   package Big_From_Count is new Signed_Conversions
     (Int => Count_Type);

   function Big (C : Count_Type) return Big_Integer renames
     Big_From_Count.To_Big_Integer;

   --  Store Count_Type'Last as a Big Natural because it is often used

   Count_Type_Big_Last : constant Big_Natural := Big (Count_Type'Last);

   function To_Count (C : Big_Natural) return Count_Type;
   --  Convert Big_Natural to Count_Type

   ---------
   -- "<" --
   ---------

   function "<" (Left : Sequence; Right : Sequence) return Boolean is
     (Length (Left) < Length (Right)
      and then
        (Ptr_Eq (Left.Content, Right.Content)
         or else
           (for all N in Left =>
                     Get (Left, N) = Get (Right, N))));

   ----------
   -- "<=" --
   ----------

   function "<=" (Left : Sequence; Right : Sequence) return Boolean is
     (Length (Left) <= Length (Right)
      and then
        (Ptr_Eq (Left.Content, Right.Content)
         or else
            (for all N in Left =>
                     Get (Left, N) = Get (Right, N))));

   ---------
   -- "=" --
   ---------

   function "=" (Left : Sequence; Right : Sequence) return Boolean is
     (Left.Content = Right.Content);

   ---------
   -- Add --
   ---------

   function Add (Container : Sequence; New_Item : Element_Type) return Sequence
   is
     (Add (Container, Last (Container) + 1, New_Item));

   function Add
     (Container : Sequence;
      Position  : Big_Positive;
      New_Item  : Element_Type) return Sequence is
     (Content => Add (Container.Content, To_Count (Position), New_Item));

   -----------------
   -- Aggr_Append --
   -----------------

   procedure Aggr_Append
     (Container : in out Sequence;
      New_Item  : Element_Type)
   is
   begin
      Container := Add (Container, New_Item);
   end Aggr_Append;

   --------------------
   -- Constant_Range --
   --------------------

   function Constant_Range
     (Container : Sequence;
      Fst       : Big_Positive;
      Lst       : Big_Natural;
      Item      : Element_Type) return Boolean
   is
      Count_Fst : constant Count_Type := To_Count (Fst);
      Count_Lst : constant Count_Type := To_Count (Lst);

   begin
      for J in Count_Fst .. Count_Lst loop
         if Get (Container.Content, J) /= Item then
            return False;
         end if;
      end loop;

      return True;
   end Constant_Range;

   --------------
   -- Contains --
   --------------

   function Contains
     (Container : Sequence;
      Fst       : Big_Positive;
      Lst       : Big_Natural;
      Item      : Element_Type) return Boolean
   is
      Count_Fst : constant Count_Type := To_Count (Fst);
      Count_Lst : constant Count_Type := To_Count (Lst);

   begin
      for J in Count_Fst .. Count_Lst loop
         if Equivalent_Elements (Get (Container.Content, J), Item) then
            return True;
         end if;
      end loop;

      return False;
   end Contains;

   -------------------------
   -- Element_Logic_Equal --
   -------------------------

   function Element_Logic_Equal (Left, Right : Element_Type) return Boolean is
   begin
      Check_Or_Fail;
      return Left = Right;
   end Element_Logic_Equal;

   --------------------
   -- Empty_Sequence --
   --------------------

   function Empty_Sequence return Sequence is
      (Content => <>);

   ------------------
   -- Equal_Except --
   ------------------

   function Equal_Except
     (Left     : Sequence;
      Right    : Sequence;
      Position : Big_Positive) return Boolean
   is
      Count_Pos : constant Count_Type := To_Count (Position);
      Count_Lst : constant Count_Type := To_Count (Last (Left));

   begin
      if Length (Left) /= Length (Right) then
         return False;
      elsif Ptr_Eq (Left.Content, Right.Content) then
         return True;
      end if;

      for J in 1 .. Count_Lst loop
         if J /= Count_Pos
              and then not Element_Logic_Equal
               (Get (Left.Content, J), Get (Right.Content, J))
         then
            return False;
         end if;
      end loop;

      return True;
   end Equal_Except;

   function Equal_Except
     (Left  : Sequence;
      Right : Sequence;
      X     : Big_Positive;
      Y     : Big_Positive) return Boolean
   is
      Count_X   : constant Count_Type := To_Count (X);
      Count_Y   : constant Count_Type := To_Count (Y);
      Count_Lst : constant Count_Type := To_Count (Last (Left));

   begin
      if Length (Left) /= Length (Right) then
         return False;
      elsif Ptr_Eq (Left.Content, Right.Content) then
         return True;
      end if;

      for J in 1 .. Count_Lst loop
         if J /= Count_X
              and then J /= Count_Y
              and then not Element_Logic_Equal
                  (Get (Left.Content, J), Get (Right.Content, J))
         then
            return False;
         end if;
      end loop;

      return True;
   end Equal_Except;

   ------------------
   -- Equal_Prefix --
   ------------------

   function Equal_Prefix (Left, Right : Sequence) return Boolean is
     (Length (Left) <= Length (Right)
      and then
        (Ptr_Eq (Left.Content, Right.Content)
         or else
            (for all N in Left =>
                  Element_Logic_Equal (Get (Left, N), Get (Right, N)))));

   --------------------------
   -- Equivalent_Sequences --
   --------------------------

   function Equivalent_Sequences (Left, Right : Sequence) return Boolean
   is
     (Length (Left) = Length (Right)
      and then
        (Ptr_Eq (Left.Content, Right.Content)
         or else
            (for all N in Left =>
               Equivalent_Elements (Get (Left, N), Get (Right, N)))));

   ----------
   -- Find --
   ----------

   function Find
     (Container : Sequence;
      Item      : Element_Type) return Big_Natural
   is
      Count_Lst : constant Count_Type := To_Count (Last (Container));

   begin
      for J in 1 .. Count_Lst loop
         if Equivalent_Elements (Get (Container.Content, J), Item) then
            return Big (J);
         end if;
      end loop;

      return 0;
   end Find;

   ---------
   -- Get --
   ---------

   function Get
     (Container : Sequence;
      Position  : Big_Integer) return Element_Type is
     (Get (Container.Content, To_Count (Position)));

   ----------
   -- Last --
   ----------

   function Last (Container : Sequence) return Big_Natural is
      (Length (Container));

   ------------
   -- Length --
   ------------

   function Length (Container : Sequence) return Big_Natural is
     (Big (Length (Container.Content)));

   -----------------
   -- Range_Equal --
   -----------------

   function Range_Equal
     (Left  : Sequence;
      Right : Sequence;
      Fst   : Big_Positive;
      Lst   : Big_Natural) return Boolean
   is
      Count_Fst : constant Count_Type := To_Count (Fst);
      Count_Lst : constant Count_Type := To_Count (Lst);

   begin
      if Ptr_Eq (Left.Content, Right.Content) then
         return True;
      end if;

      for J in Count_Fst .. Count_Lst loop
         if Get (Left.Content, J) /= Get (Right.Content, J) then
            return False;
         end if;
      end loop;

      return True;
   end Range_Equal;

   -------------------
   -- Range_Shifted --
   -------------------

   function Range_Shifted
     (Left   : Sequence;
      Right  : Sequence;
      Fst    : Big_Positive;
      Lst    : Big_Natural;
      Offset : Big_Integer) return Boolean
   is
      Count_Fst : constant Count_Type := To_Count (Fst);
      Count_Lst : constant Count_Type := To_Count (Lst);

   begin
      for J in Count_Fst .. Count_Lst loop
         if Get (Left.Content, J) /= Get (Right, Big (J) + Offset) then
            return False;
         end if;
      end loop;

      return True;
   end Range_Shifted;

   ------------
   -- Remove --
   ------------

   function Remove
     (Container : Sequence;
      Position : Big_Positive) return Sequence is
     (Content => Remove (Container.Content, To_Count (Position)));

   ---------
   -- Set --
   ---------

   function Set
     (Container : Sequence;
      Position  : Big_Positive;
      New_Item  : Element_Type) return Sequence is
     (Content => Set (Container.Content, To_Count (Position), New_Item));

   --------------
   -- To_Count --
   --------------

   function To_Count (C : Big_Natural) return Count_Type is
   begin
      if C > Count_Type_Big_Last then
         raise Program_Error with "Big_Integer too large for Count_Type";
      end if;
      return Big_From_Count.From_Big_Integer (C);
   end To_Count;

end SPARK.Containers.Functional.Infinite_Sequences;
