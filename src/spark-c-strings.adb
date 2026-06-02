--
--  Copyright (C) 2024-2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

pragma Assertion_Policy (Ignore);

package body SPARK.C.Strings
  with SPARK_Mode => Off
is

   --------------------
   -- C_Length_Ghost --
   --------------------

   function C_Length_Ghost (Item : char_array) return size_t is
   begin
      for J in Item'Range loop
         if Item (J) = nul then
            return J - Item'First;
         end if;
      end loop;

      raise Program_Error;
   end C_Length_Ghost;

   function C_Length_Ghost (Item : String) return Natural is
   begin
      for J in Item'Range loop
         if Item (J) = Character'First then
            return J - Item'First;
         end if;
      end loop;

      raise Program_Error;
   end C_Length_Ghost;

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
   is (Interfaces.C.Strings.chars_ptr (Item));

   -----------------------------
   -- Is_Nul_Terminated_Ghost --
   -----------------------------

   function Is_Nul_Terminated_Ghost (Item : String) return Boolean is
   begin
      for J in Item'Range loop
         if Item (J) = Character'First then
            return True;
         end if;
      end loop;

      return False;
   end Is_Nul_Terminated_Ghost;

   --------------------
   -- New_Char_Array --
   --------------------

   function New_Char_Array (Chars : char_array) return chars_ptr
   is (chars_ptr (Interfaces.C.Strings.New_Char_Array (Chars)));

   ----------------
   -- New_String --
   ----------------

   function New_String (Str : String) return chars_ptr
   is (chars_ptr (Interfaces.C.Strings.New_String (Str)));

   ------------
   -- Strlen --
   ------------

   function Strlen (Item : chars_ptr) return size_t
   is (Interfaces.C.Strings.Strlen (Interfaces.C.Strings.chars_ptr (Item)));

   ------------------
   -- To_Chars_Ptr --
   ------------------

   function To_Chars_Ptr
     (Item      : Interfaces.C.Strings.char_array_access;
      Nul_Check : Boolean := False) return chars_ptr
   is (chars_ptr (Interfaces.C.Strings.To_Chars_Ptr (Item, Nul_Check)));

   function To_Chars_Ptr
     (Item : Interfaces.C.Strings.chars_ptr) return chars_ptr
   is (chars_ptr (Item));

   ------------
   -- Update --
   ------------

   procedure Update
     (Item   : in out chars_ptr;
      Offset : size_t;
      Chars  : char_array;
      Check  : Boolean := True) is
   begin
      Interfaces.C.Strings.Update
        (Item   => Interfaces.C.Strings.chars_ptr (Item),
         Offset => Offset,
         Chars  => Chars,
         Check  => Check);
   end Update;

   procedure Update
     (Item   : in out chars_ptr;
      Offset : size_t;
      Str    : String;
      Check  : Boolean := True) is
   begin
      Interfaces.C.Strings.Update
        (Item   => Interfaces.C.Strings.chars_ptr (Item),
         Offset => Offset,
         Str    => Str,
         Check  => Check);
   end Update;

   -----------
   -- Value --
   -----------

   function Value (Item : chars_ptr) return char_array
   is (Interfaces.C.Strings.Value (Interfaces.C.Strings.chars_ptr (Item)));

   function Value (Item : chars_ptr; Length : size_t) return char_array
   is (Interfaces.C.Strings.Value
         (Interfaces.C.Strings.chars_ptr (Item), Length));

   function Value (Item : chars_ptr) return String
   is (Interfaces.C.Strings.Value (Interfaces.C.Strings.chars_ptr (Item)));

   function Value (Item : chars_ptr; Length : size_t) return String
   is (Interfaces.C.Strings.Value
         (Interfaces.C.Strings.chars_ptr (Item), Length));

end SPARK.C.Strings;
