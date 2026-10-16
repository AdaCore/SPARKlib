with Ada.Text_IO;
with Interfaces.C;                  use Interfaces.C;
with SPARK.C.Constant_Strings;      use SPARK.C.Constant_Strings;

procedure Test_Constant_String with SPARK_Mode is

   procedure Assert (B : Boolean; S : String) with
     Pre => B;
   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   procedure Test_To_Chars_Ptr is
   begin
      --  Call on a null pointer
      declare
         S : Const_Char_Array_Access := null;
         X : Chars_Ptr := To_Chars_Ptr (S);
      begin
         Assert (X = Null_Ptr, "To_Chars_Ptr on null pointer");
      end;

      --  Call on empty nul terminated string
      declare
         S : Const_Char_Array_Access := new char_array'((0 => nul));
         X : Chars_Ptr := To_Chars_Ptr (S);
      begin
         Assert (Strlen (X) = 0, "To_Chars_Ptr on empty nul terminated string");
      end;

      --  Call on non-empty nul terminated string
      declare
         F : Char_Array := "foo";
         S : Const_Char_Array_Access := new char_array'(F & nul);
         X : Chars_Ptr := To_Chars_Ptr (S);
      begin
         Assert (Strlen (X) /= 0 and Value (X) = F & nul, "To_Chars_Ptr on non-empty nul terminated string");
      end;
   end Test_To_Chars_Ptr;

   procedure Test_Value is
      F : Char_Array := "foo" & Nul & "bar" & Nul & "bar";
      S : Const_Char_Array_Access := new Char_Array'(F);
      X : Chars_Ptr := To_Chars_Ptr (S);
      V : Char_Array := Value (X);
   begin
      Assert (V'First = 0, "Value lower bound is 0");
      Assert (V = "foo" & nul, "Value returns the prefix of the array of chars pointed to by Item, up to and including the first nul");
   end Test_Value;

   procedure Test_Value_Length is
      F : Char_Array := "foo_bar" & Nul & "bar";
      S : Const_Char_Array_Access := new Char_Array'(F);
      X : Chars_Ptr := To_Chars_Ptr (S);
   begin

      --  Call with a length shorter than Strlen (X)
      declare
         V : Char_Array := Value (X, 3);
      begin
         Assert (V'First = 0, "Value lower bound is 0");
         Assert (V = "foo", "Value stops at length");
      end;

      --  Call with a length larger than Strlen (X)
      declare
         V : Char_Array := Value (X, 10);
      begin
         Assert (V'First = 0, "Value lower bound is 0");
         Assert (V = "foo_bar" & Nul, "Value stops at nul");
      end;
   end Test_Value_Length;

   procedure Test_Value_String is
      F : Char_Array := "foo" & Nul & "bar" & Nul & "bar";
      S : Const_Char_Array_Access := new Char_Array'(F);
      X : Chars_Ptr := To_Chars_Ptr (S);
      V : String := Value (X);
   begin
      Assert (V'First = 1, "Value lower bound is 1");
      Assert (V = "foo", "Equivalent to To_Ada (Value(Item), Trim_Nul=>True)");
   end Test_Value_String;

   procedure Test_Value_String_Length is
      F : Char_Array := "foo_bar" & Nul & "bar";
      S : Const_Char_Array_Access := new Char_Array'(F);
      X : Chars_Ptr := To_Chars_Ptr (S);
   begin

      --  Call with a length shorter than Strlen (X)
      declare
         V : String := Value (X, 3);
      begin
         Assert (V'First = 1, "Value lower bound is 1");
         Assert (V = "foo", "Value stops at length");
      end;

      --  Call with a length larger than Strlen (X)
      declare
         V : String := Value (X, 10);
      begin
         Assert (V'First = 1, "Value lower bound is 1");
         Assert (V = "foo_bar", "Value stops at nul");
      end;
   end Test_Value_String_Length;

   procedure Test_Strlen is
      F : Char_Array := "foo" & Nul & "bar" & Nul & "bar";
      S : Const_Char_Array_Access := new Char_Array'(F);
      X : Chars_Ptr := To_Chars_Ptr (S);
   begin
      Assert (Strlen (X) = 3, "Strlen returns Value(Item)'Length - 1");
   end Test_Strlen;

begin
   Test_To_Chars_Ptr;
   Test_Value;
   Test_Value_Length;
   Test_Value_String;
   Test_Value_String_Length;
   Test_Strlen;
end Test_Constant_String;
