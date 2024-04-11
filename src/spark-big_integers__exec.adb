--
--  Copyright (C) 2016-2024, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package body SPARK.Big_Integers with
   SPARK_Mode => Off
is

   --------------
   -- Is_Valid --
   --------------

   function Is_Valid (Arg : Big_Integer) return Boolean is
     (True);

   ---------
   -- "=" --
   ---------

   function "=" (L, R : Valid_Big_Integer) return Boolean is
     (L.V = R.V);

   ---------
   -- "<" --
   ---------

   function "<" (L, R : Valid_Big_Integer) return Boolean is
     (L.V < R.V);

   ----------
   -- "<=" --
   ----------

   function "<=" (L, R : Valid_Big_Integer) return Boolean is
     (L.V <= R.V);

   ---------
   -- ">" --
   ---------

   function ">" (L, R : Valid_Big_Integer) return Boolean is
     (L.V > R.V);

   ----------
   -- ">=" --
   ----------

   function ">=" (L, R : Valid_Big_Integer) return Boolean is
     (L.V >= R.V);

   --------------------
   -- To_Big_Integer --
   --------------------

   function To_Big_Integer (Arg : Integer) return Valid_Big_Integer is
      ((V => Long_Long_Long_Integer (Arg)));

   ----------------
   -- To_Integer --
   ----------------

   function To_Integer (Arg : Valid_Big_Integer) return Integer is
     (Integer (Arg.V));

   ------------------------
   -- Signed_Conversions --
   ------------------------

   package body Signed_Conversions is

      --------------------
      -- To_Big_Integer --
      --------------------

      function To_Big_Integer (Arg : Int) return Valid_Big_Integer is
        ((V => Long_Long_Long_Integer (Arg)));

      ----------------------
      -- From_Big_Integer --
      ----------------------

      function From_Big_Integer (Arg : Valid_Big_Integer) return Int is
        (Int (Arg.V));

   end Signed_Conversions;

   --------------------------
   -- Unsigned_Conversions --
   --------------------------

   package body Unsigned_Conversions is

      --------------------
      -- To_Big_Integer --
      --------------------

      function To_Big_Integer (Arg : Int) return Valid_Big_Integer is
        ((V => Long_Long_Long_Integer (Arg)));

      ----------------------
      -- From_Big_Integer --
      ----------------------

      function From_Big_Integer (Arg : Valid_Big_Integer) return Int is
        (Int (Arg.V));

   end Unsigned_Conversions;

   -----------------
   -- From_String --
   -----------------

   function From_String (Arg : String) return Valid_Big_Integer is
     ((V => Long_Long_Long_Integer'Value (Arg)));

   ---------
   -- "+" --
   ---------

   function "+" (L : Valid_Big_Integer) return Valid_Big_Integer is
     (L);

   ---------
   -- "-" --
   ---------

   function "-" (L : Valid_Big_Integer) return Valid_Big_Integer is
     ((V => -L.V));

   -----------
   -- "abs" --
   -----------

   function "abs" (L : Valid_Big_Integer) return Valid_Big_Integer is
     ((V => abs L.V));

   ---------
   -- "+" --
   ---------

   function "+" (L, R : Valid_Big_Integer) return Valid_Big_Integer is
     ((V => L.V + R.V));

   ---------
   -- "-" --
   ---------

   function "-" (L, R : Valid_Big_Integer) return Valid_Big_Integer is
     ((V => L.V - R.V));

   ---------
   -- "*" --
   ---------

   function "*" (L, R : Valid_Big_Integer) return Valid_Big_Integer is
     ((V => L.V * R.V));

   ---------
   -- "/" --
   ---------

   function "/" (L, R : Valid_Big_Integer) return Valid_Big_Integer is
     ((V => L.V / R.V));

   -----------
   -- "mod" --
   -----------

   function "mod" (L, R : Valid_Big_Integer) return Valid_Big_Integer is
     ((V => L.V mod R.V));

   -----------
   -- "rem" --
   -----------

   function "rem" (L, R : Valid_Big_Integer) return Valid_Big_Integer is
     ((V => L.V rem R.V));

   ----------
   -- "**" --
   ----------

   function "**"
     (L : Valid_Big_Integer; R : Natural) return Valid_Big_Integer is
     ((V => L.V ** R));

   -----------------------------
   -- Greatest_Common_Divisor --
   -----------------------------

   function Greatest_Common_Divisor
     (L, R : Valid_Big_Integer) return Big_Positive
   is (raise Program_Error);

   ---------
   -- Min --
   ---------

   function Min (L, R : Valid_Big_Integer) return Valid_Big_Integer is
     (if L < R then L else R);

   ---------
   -- Max --
   ---------

   function Max (L, R : Valid_Big_Integer) return Valid_Big_Integer is
     (if L > R then L else R);

end SPARK.Big_Integers;
