--
--  Copyright (C) 2024-2025, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

pragma Assertion_Policy (Ignore);

with Ada.Unchecked_Conversion;

package body SPARK.C.Constant_Strings with
  SPARK_Mode => Off
is

   ----------
   -- Free --
   ----------

   procedure Free (Item : in out chars_ptr) is
      Str : Interfaces.C.Strings.chars_ptr :=
        Interfaces.C.Strings.chars_ptr (Item);
   begin
      Interfaces.C.Strings.Free (Str);
      Item := chars_ptr (Str);
   end Free;

   --------------------
   -- From_Chars_Ptr --
   --------------------

   function From_Chars_Ptr
     (Item : chars_ptr) return Interfaces.C.Strings.chars_ptr
   is
     (Interfaces.C.Strings.chars_ptr (Item));

   --------------------
   -- New_Char_Array --
   --------------------

   function New_Char_Array (Chars : char_array) return chars_ptr is
      (chars_ptr (Interfaces.C.Strings.New_Char_Array (Chars)));

   ----------------
   -- New_String --
   ----------------

   function New_String (Str : String) return chars_ptr is
      (chars_ptr (Interfaces.C.Strings.New_String (Str)));

   ------------
   -- Strlen --
   ------------

   function Strlen (Item : chars_ptr) return size_t is
      (Interfaces.C.Strings.Strlen (Interfaces.C.Strings.chars_ptr (Item)));

   ------------------
   -- To_Chars_Ptr --
   ------------------

   function To_Chars_Ptr
     (Item      : Interfaces.C.Strings.char_array_access;
      Nul_Check : Boolean := False) return chars_ptr
   is
     (chars_ptr (Interfaces.C.Strings.To_Chars_Ptr (Item, Nul_Check)));

   function To_Chars_Ptr
     (Item      : const_char_array_access;
      Nul_Check : Boolean := False) return chars_ptr
   is
      function Conv is new Ada.Unchecked_Conversion
        (const_char_array_access, Interfaces.C.Strings.char_array_access);
   begin
      return chars_ptr (Interfaces.C.Strings.To_Chars_Ptr
                        (Conv (Item), Nul_Check));
   end To_Chars_Ptr;

   function To_Chars_Ptr
     (Item : Interfaces.C.Strings.chars_ptr) return chars_ptr
   is
     (chars_ptr (Item));

   -----------
   -- Value --
   -----------

   function Value (Item : chars_ptr) return char_array is
      (Interfaces.C.Strings.Value (Interfaces.C.Strings.chars_ptr (Item)));

   function Value
     (Item   : chars_ptr;
      Length : size_t) return char_array
   is
     (Interfaces.C.Strings.Value
       (Interfaces.C.Strings.chars_ptr (Item), Length));

   function Value (Item : chars_ptr) return String is
      (Interfaces.C.Strings.Value (Interfaces.C.Strings.chars_ptr (Item)));

   function Value (Item : chars_ptr; Length : size_t) return String is
     (Interfaces.C.Strings.Value
       (Interfaces.C.Strings.chars_ptr (Item), Length));

end SPARK.C.Constant_Strings;
