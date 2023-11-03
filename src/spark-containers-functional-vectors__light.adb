--
--  Copyright (C) 2016-2023, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This body is provided as a work-around for a GNAT compiler bug, as GNAT
--  currently does not compile instantiations of the spec with imported ghost
--  generics.

pragma Ada_2012;
with SPARK.Containers.Types; use SPARK.Containers.Types;

package body SPARK.Containers.Functional.Vectors with SPARK_Mode => Off is
   use Containers;

   package Count_Conversions is new Signed_Conversions (Int => Count_Type);

   ---------
   -- "<" --
   ---------

   function "<" (Left : Sequence; Right : Sequence) return Boolean is
     (raise Program_Error);

   ----------
   -- "<=" --
   ----------

   function "<=" (Left : Sequence; Right : Sequence) return Boolean is
     (raise Program_Error);

   ---------
   -- "=" --
   ---------

   function "=" (Left : Sequence; Right : Sequence) return Boolean is
     (raise Program_Error);

   ---------
   -- Add --
   ---------

   function Add
     (Container : Sequence;
      New_Item  : Element_Type) return Sequence
   is
     (raise Program_Error);

   function Add
     (Container : Sequence;
      Position  : Index_Type;
      New_Item  : Element_Type) return Sequence
   is
     (raise Program_Error);

   -----------------
   -- Aggr_Append --
   -----------------

   procedure Aggr_Append
     (Container : in out Sequence;
      New_Item  : Element_Type)
   is
   begin
      raise Program_Error;
   end Aggr_Append;

   --------------------
   -- Constant_Range --
   --------------------

   function Constant_Range
     (Container : Sequence;
      Fst       : Index_Type;
      Lst       : Extended_Index;
      Item      : Element_Type) return Boolean
   is
     (raise Program_Error);

   --------------
   -- Contains --
   --------------

   function Contains
     (Container : Sequence;
      Fst       : Index_Type;
      Lst       : Extended_Index;
      Item      : Element_Type) return Boolean
   is
     (raise Program_Error);

   -------------------------
   -- Element_Logic_Equal --
   -------------------------

   function Element_Logic_Equal (Left, Right : Element_Type) return Boolean is
     (raise Program_Error);

   --------------------
   -- Empty_Sequence --
   --------------------

   function Empty_Sequence return Sequence is
     (raise Program_Error);

   ------------------
   -- Equal_Except --
   ------------------

   function Equal_Except
     (Left     : Sequence;
      Right    : Sequence;
      Position : Index_Type) return Boolean
   is
     (raise Program_Error);

   function Equal_Except
     (Left  : Sequence;
      Right : Sequence;
      X     : Index_Type;
      Y     : Index_Type) return Boolean
   is
     (raise Program_Error);

   ------------------
   -- Equal_Prefix --
   ------------------

   function Equal_Prefix (Left, Right : Sequence) return Boolean is
     (raise Program_Error);

   --------------------------
   -- Equivalent_Sequences --
   --------------------------

   function Equivalent_Sequences (Left, Right : Sequence) return Boolean is
     (raise Program_Error);

   ----------
   -- Find --
   ----------

   function Find
     (Container : Sequence;
      Item      : Element_Type) return Extended_Index
   is
     (raise Program_Error);

   ---------
   -- Get --
   ---------

   function Get (Container : Sequence;
                 Position  : Extended_Index) return Element_Type
   is
     (raise Program_Error);

   ----------
   -- Last --
   ----------

   function Last (Container : Sequence) return Extended_Index is
     (raise Program_Error);

   ------------
   -- Length --
   ------------

   function Length (Container : Sequence) return Big_Natural is
     (raise Program_Error);

   -----------------
   -- Range_Equal --
   -----------------

   function Range_Equal
     (Left  : Sequence;
      Right : Sequence;
      Fst   : Index_Type;
      Lst   : Extended_Index) return Boolean
   is
     (raise Program_Error);

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
     (raise Program_Error);

   ------------
   -- Remove --
   ------------

   function Remove
     (Container : Sequence;
      Position : Index_Type) return Sequence
   is
     (raise Program_Error);

   ---------
   -- Set --
   ---------

   function Set
     (Container : Sequence;
      Position  : Index_Type;
      New_Item  : Element_Type) return Sequence
   is
     (raise Program_Error);

end SPARK.Containers.Functional.Vectors;
