--
--  Copyright (C) 2016-2023, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2012;
with SPARK.Containers.Types; use SPARK.Containers.Types;

package body SPARK.Containers.Functional.Vectors with SPARK_Mode => Off is
   use Containers;

   package Count_Conversions is new Signed_Conversions (Int => Count_Type);

   ---------
   -- "<" --
   ---------

   function "<" (Left : Sequence; Right : Sequence) return Boolean is
     (Length (Left.Content) < Length (Right.Content)
      and then
        (Ptr_Eq (Left.Content, Right.Content)
         or else
           (for all I in Index_Type'First .. Last (Left) =>
                 Get (Left.Content, I) = Get (Right.Content, I))));

   ----------
   -- "<=" --
   ----------

   function "<=" (Left : Sequence; Right : Sequence) return Boolean is
     (Length (Left.Content) <= Length (Right.Content)
       and then
        (Ptr_Eq (Left.Content, Right.Content)
         or else (for all I in Index_Type'First .. Last (Left) =>
              Get (Left.Content, I) = Get (Right.Content, I))));

   ---------
   -- "=" --
   ---------

   function "=" (Left : Sequence; Right : Sequence) return Boolean is
     (Left.Content = Right.Content);

   ---------
   -- Add --
   ---------

   function Add
     (Container : Sequence;
      New_Item  : Element_Type) return Sequence
   is
     (Content =>
       Add (Container.Content,
            Index_Type'Val (Index_Type'Pos (Index_Type'First) +
                            Length (Container.Content)),
            New_Item));

   function Add
     (Container : Sequence;
      Position  : Index_Type;
      New_Item  : Element_Type) return Sequence
   is
     (Content => Add (Container.Content, Position, New_Item));

   --------------------
   -- Constant_Range --
   --------------------

   function Constant_Range
     (Container : Sequence;
      Fst       : Index_Type;
      Lst       : Extended_Index;
      Item      : Element_Type) return Boolean is
   begin
      for I in Fst .. Lst loop
         if not Element_Logic_Equal (Get (Container.Content, I), Item) then
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
      Fst       : Index_Type;
      Lst       : Extended_Index;
      Item      : Element_Type) return Boolean
   is
   begin
      for I in Fst .. Lst loop
         if Equivalent_Elements (Get (Container.Content, I), Item) then
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
      ((others => <>));

   ------------------
   -- Equal_Except --
   ------------------

   function Equal_Except
     (Left     : Sequence;
      Right    : Sequence;
      Position : Index_Type) return Boolean
   is
   begin
      if Length (Left.Content) /= Length (Right.Content) then
         return False;
      elsif Ptr_Eq (Left.Content, Right.Content) then
         return True;
      end if;

      for I in Index_Type'First .. Last (Left) loop
         if I /= Position
           and then not
             Element_Logic_Equal
                (Get (Left.Content, I), Get (Right.Content, I))
         then
            return False;
         end if;
      end loop;

      return True;
   end Equal_Except;

   function Equal_Except
     (Left  : Sequence;
      Right : Sequence;
      X     : Index_Type;
      Y     : Index_Type) return Boolean
   is
   begin
      if Length (Left.Content) /= Length (Right.Content) then
         return False;
      elsif Ptr_Eq (Left.Content, Right.Content) then
         return True;
      end if;

      for I in Index_Type'First .. Last (Left) loop
         if I /= X and then I /= Y
           and then not
             Element_Logic_Equal
                (Get (Left.Content, I), Get (Right.Content, I))
         then
            return False;
         end if;
      end loop;

      return True;
   end Equal_Except;

   ------------------
   -- Equal_Prefix --
   ------------------

   function Equal_Prefix (Left : Sequence; Right : Sequence) return Boolean is
     (Length (Left.Content) <= Length (Right.Content)
       and then
        (Ptr_Eq (Left.Content, Right.Content)
         or else (for all I in Index_Type'First .. Last (Left) =>
              Element_Logic_Equal
                (Get (Left.Content, I), Get (Right.Content, I)))));

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
      Item      : Element_Type) return Extended_Index
   is
   begin
      for I in Index_Type'First .. Last (Container) loop
         if Equivalent_Elements (Get (Container.Content, I), Item) then
            return I;
         end if;
      end loop;

      return Extended_Index'First;
   end Find;

   ---------
   -- Get --
   ---------

   function Get (Container : Sequence;
                 Position  : Extended_Index) return Element_Type
   is
     (Get (Container.Content, Position));

   ----------
   -- Last --
   ----------

   function Last (Container : Sequence) return Extended_Index is
     (Of_Big ((Big (Index_Type'First) - 1) + Length (Container)));

   ------------
   -- Length --
   ------------

   function Length (Container : Sequence) return Big_Natural is
     (Count_Conversions.To_Big_Integer (Length (Container.Content)));

   -----------------
   -- Range_Equal --
   -----------------

   function Range_Equal
     (Left  : Sequence;
      Right : Sequence;
      Fst   : Index_Type;
      Lst   : Extended_Index) return Boolean
   is
   begin
      if Ptr_Eq (Left.Content, Right.Content) then
         return True;
      end if;

      for I in Fst .. Lst loop
         if not Element_Logic_Equal (Get (Left, I), Get (Right, I)) then
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
      Fst    : Index_Type;
      Lst    : Extended_Index;
      Offset : Big_Integer) return Boolean
   is
   begin
      for I in Fst .. Lst loop
         if not Element_Logic_Equal
           (Get (Left, I),
            Get (Right, Of_Big (Big (I) + Offset)))
         then
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
      Position : Index_Type) return Sequence
   is
     (Content => Remove (Container.Content, Position));

   ---------
   -- Set --
   ---------

   function Set
     (Container : Sequence;
      Position  : Index_Type;
      New_Item  : Element_Type) return Sequence
   is
     (Content => Set (Container.Content, Position, New_Item));

end SPARK.Containers.Functional.Vectors;
