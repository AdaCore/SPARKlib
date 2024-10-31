--
--  Copyright (C) 2016-2024, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package body SPARK.Big_Integers with
   SPARK_Mode => Off
is

   ------------------------
   -- Signed_Conversions --
   ------------------------

   package body Signed_Conversions with
     SPARK_Mode => Off
   is

      ----------------------
      -- From_Big_Integer --
      ----------------------

      function From_Big_Integer (Arg : Valid_Big_Integer) return Int is
      begin
         Check_Or_Fail;
         return Int (Arg.V);
      end From_Big_Integer;

      --------------------
      -- To_Big_Integer --
      --------------------

      function To_Big_Integer (Arg : Int) return Valid_Big_Integer is
      begin
         Check_Or_Fail;
         return (V => Long_Long_Long_Integer (Arg));
      end To_Big_Integer;

   end Signed_Conversions;

   --------------------------
   -- Unsigned_Conversions --
   --------------------------

   package body Unsigned_Conversions with
     SPARK_Mode => Off
   is

      ----------------------
      -- From_Big_Integer --
      ----------------------

      function From_Big_Integer (Arg : Valid_Big_Integer) return Int is
      begin
         Check_Or_Fail;
         return Int (Arg.V);
      end From_Big_Integer;

      --------------------
      -- To_Big_Integer --
      --------------------

      function To_Big_Integer (Arg : Int) return Valid_Big_Integer is
      begin
         Check_Or_Fail;
         return (V => Long_Long_Long_Integer (Arg));
      end To_Big_Integer;

   end Unsigned_Conversions;

   ---------
   -- "*" --
   ---------

   function "*" (L, R : Valid_Big_Integer) return Valid_Big_Integer is
   begin
      Check_Or_Fail;
      return (V => L.V * R.V);
   end "*";

   ----------
   -- "**" --
   ----------

   function "**"
     (L : Valid_Big_Integer; R : Natural) return Valid_Big_Integer is
   begin
      Check_Or_Fail;
      return (V => L.V ** R);
   end "**";

   ---------
   -- "+" --
   ---------

   function "+" (L : Valid_Big_Integer) return Valid_Big_Integer is
   begin
      Check_Or_Fail;
      return L;
   end "+";

   function "+" (L, R : Valid_Big_Integer) return Valid_Big_Integer is
   begin
      Check_Or_Fail;
      return (V => L.V + R.V);
   end "+";

   ---------
   -- "-" --
   ---------

   function "-" (L : Valid_Big_Integer) return Valid_Big_Integer is
   begin
      Check_Or_Fail;
      return (V => -L.V);
   end "-";

   function "-" (L, R : Valid_Big_Integer) return Valid_Big_Integer is
   begin
      Check_Or_Fail;
      return (V => L.V - R.V);
   end "-";

   ---------
   -- "/" --
   ---------

   function "/" (L, R : Valid_Big_Integer) return Valid_Big_Integer is
   begin
      Check_Or_Fail;
      return (V => L.V / R.V);
   end "/";

   ---------
   -- "<" --
   ---------

   function "<" (L, R : Valid_Big_Integer) return Boolean is
   begin
      Check_Or_Fail;
      return L.V < R.V;
   end "<";

   ----------
   -- "<=" --
   ----------

   function "<=" (L, R : Valid_Big_Integer) return Boolean is
   begin
      Check_Or_Fail;
      return L.V <= R.V;
   end "<=";

   ---------
   -- "=" --
   ---------

   function "=" (L, R : Valid_Big_Integer) return Boolean is
   begin
      Check_Or_Fail;
      return L.V = R.V;
   end "=";

   ---------
   -- ">" --
   ---------

   function ">" (L, R : Valid_Big_Integer) return Boolean is
   begin
      Check_Or_Fail;
      return L.V > R.V;
   end ">";

   ----------
   -- ">=" --
   ----------

   function ">=" (L, R : Valid_Big_Integer) return Boolean is
   begin
      Check_Or_Fail;
      return L.V >= R.V;
   end ">=";

   -----------
   -- "abs" --
   -----------

   function "abs" (L : Valid_Big_Integer) return Valid_Big_Integer is
   begin
      Check_Or_Fail;
      return (V => abs L.V);
   end "abs";

   -----------
   -- "mod" --
   -----------

   function "mod" (L, R : Valid_Big_Integer) return Valid_Big_Integer is
   begin
      Check_Or_Fail;
      return (V => L.V mod R.V);
   end "mod";

   -----------
   -- "rem" --
   -----------

   function "rem" (L, R : Valid_Big_Integer) return Valid_Big_Integer is
   begin
      Check_Or_Fail;
      return (V => L.V rem R.V);
   end "rem";

   -----------------
   -- From_String --
   -----------------

   function From_String (Arg : String) return Valid_Big_Integer is
   begin
      Check_Or_Fail;
      return (V => Long_Long_Long_Integer'Value (Arg));
   end From_String;

   -----------------------------
   -- Greatest_Common_Divisor --
   -----------------------------

   function Greatest_Common_Divisor
     (L, R : Valid_Big_Integer) return Big_Positive
   is
   begin
      Check_Or_Fail;
      return (raise Program_Error);
   end Greatest_Common_Divisor;

   --------------
   -- Is_Valid --
   --------------

   function Is_Valid (Arg : Big_Integer) return Boolean is
     (True);

   ---------
   -- Max --
   ---------

   function Max (L, R : Valid_Big_Integer) return Valid_Big_Integer is
     (if L > R then L else R);

   ---------
   -- Min --
   ---------

   function Min (L, R : Valid_Big_Integer) return Valid_Big_Integer is
     (if L < R then L else R);

   --------------------
   -- To_Big_Integer --
   --------------------

   function To_Big_Integer (Arg : Integer) return Valid_Big_Integer is
   begin
      Check_Or_Fail;
      return (V => Long_Long_Long_Integer (Arg));
   end To_Big_Integer;

   ----------------
   -- To_Integer --
   ----------------

   function To_Integer (Arg : Valid_Big_Integer) return Integer is
   begin
      Check_Or_Fail;
      return Integer (Arg.V);
   end To_Integer;

end SPARK.Big_Integers;
