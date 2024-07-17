with Ada.Text_IO;
with Interfaces.C;                  use Interfaces.C;
with SPARK.C.Strings;      use SPARK.C.Strings;

procedure Test_String with SPARK_Mode is

   procedure Assert (B : Boolean; S : String) with
     Pre => B;
   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   procedure Test_New_Char_Array is
   begin

      --  Call on nul terminated string
      declare
         F : Char_Array := "foo_bar" & Nul & "bar";
         X : Chars_Ptr := New_Char_Array (F);
      begin
         Assert (Strlen (X) = 7 and Value (X) = "foo_bar" & Nul, "New_Char_Array stops at the first index before nul");
         Free (X);
      end;

      --  Call on non nul terminated string
      declare
         F : Char_Array := "foo_bar";
         X : Chars_Ptr := New_Char_Array (F);
      begin
         Assert (Strlen (X) = 7 and Value (X) = "foo_bar" & Nul, "New_Char_Array stops at the last index");
         Free (X);
      end;
   end Test_New_Char_Array;

   procedure Test_New_String is
   begin

      --  Call on nul terminated string
      declare
         F : String := "foo_bar" & Character'First & "bar";
         X : Chars_Ptr := New_String (F);
      begin
         Assert (Strlen (X) = 7 and Value (X) = String'("foo_bar"), "New_String stops at the first index before nul");
         Free (X);
      end;

      --  Call on non nul terminated string
      declare
         F : String := "foo_bar";
         X : Chars_Ptr := New_String (F);
      begin
         Assert (Strlen (X) = 7 and Value (X) = String'("foo_bar"), "New_String stops at the last index");
         Free (X);
      end;
   end Test_New_String;

   procedure Test_Free is
      F : Char_Array := "foo_bar" & Nul & "bar";
      X : Chars_Ptr := New_Char_Array (F);
   begin
      Free (X);
      Assert (X = Null_Ptr, "Free sets its parameter to Null_Ptr");
   end Test_Free;

   procedure Test_Value is
      F : Char_Array := "foo" & Nul & "bar" & Nul & "bar";
      X : Chars_Ptr := New_Char_Array (F);
      V : Char_Array := Value (X);
   begin
      Assert (V'First = 0, "Value lower bound is 0");
      Assert (V = "foo" & nul, "Value returns the prefix of the array of chars pointed to by Item, up to and including the first nul");
      Free (X);
   end Test_Value;

   procedure Test_Value_Length is
      F : Char_Array := "foo_bar" & Nul & "bar";
      X : Chars_Ptr := New_Char_Array (F);
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
      Free (X);
   end Test_Value_Length;

   procedure Test_Value_String is
      F : String := "foo" & Character'First & "bar" & Character'First & "bar";
      X : Chars_Ptr := New_String (F);
      V : String := Value (X);
   begin
      Assert (V'First = 1, "Value lower bound is 1");
      Assert (V = "foo", "Equivalent to To_Ada (Value(Item), Trim_Nul=>True)");
      Free (X);
   end Test_Value_String;

   procedure Test_Value_String_Length is
      F : String := "foo_bar" & Character'First & "bar";
      X : Chars_Ptr := New_String (F);
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
      Free (X);
   end Test_Value_String_Length;

   procedure Test_Strlen is
      F : Char_Array := "foo" & Nul & "bar" & Nul & "bar";
      X : Chars_Ptr := New_Char_Array (F);
   begin
      Assert (Strlen (X) = 3, "Strlen returns Value(Item)'Length - 1");
      Free (X);
   end Test_Strlen;

   procedure Test_Update is
      F : Char_Array := "foo_bar_bar" & Nul;
   begin
      --  Call Update with a null terminated value
      declare
         G : Char_Array := "foo" & Nul;
         X : Chars_Ptr := New_Char_Array (F);
      begin
         Update (X, 4, G);
         Assert (Strlen (X) = 7 and then Value (X) = "foo_foo" & Nul,
                 "Update with null terminated value");
         Free (X);
      end;

      --  Call Update with a non null terminated value
      declare
         G : Char_Array := "foo";
         X : Chars_Ptr := New_Char_Array (F);
      begin
         Update (X, 4, G);
         Assert (Strlen (X) = 11 and then Value (X) = "foo_foo_bar" & Nul,
                 "Update with non null terminated value");
         Free (X);
      end;
   end Test_Update;

   procedure Test_Update_String is
      F : String := "foo_bar_bar";
   begin
      --  Call Update with a null terminated value
      declare
         G : String := "foo" & Character'First;
         X : Chars_Ptr := New_String (F);
      begin
         Update (X, 4, G);
         Assert (Strlen (X) = 7 and then Value (X) = String'("foo_foo"),
                 "Update with null terminated value");
         Free (X);
      end;

      --  Call Update with a non null terminated value
      declare
         G : String := "foo";
         X : Chars_Ptr := New_String (F);
      begin
         Update (X, 4, G);
         Assert (Strlen (X) = 11 and then Value (X) = String'("foo_foo_bar"),
                 "Update with non null terminated value");
         Free (X);
      end;
   end Test_Update_String;

begin
   Test_New_Char_Array;
   Test_New_String;
   Test_Free;
   Test_Value;
   Test_Value_Length;
   Test_Value_String;
   Test_Value_String_Length;
   Test_Strlen;
   Test_Update;
   Test_Update_String;
end Test_String;
