--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with SPARK.Strings.Unicode;       use SPARK.Strings.Unicode;
with SPARK.Strings.Unicode.UTF_8; use SPARK.Strings.Unicode.UTF_8;

procedure Test is
   function Bytes (A, B : Natural) return String
   is (Character'Val (A) & Character'Val (B));
   function Bytes (A, B, C : Natural) return String
   is (Bytes (A, B) & Character'Val (C));
   function Bytes (A, B, C, D : Natural) return String
   is (Bytes (A, B, C) & Character'Val (D));

   procedure Check_Encoding (Value : Scalar_Value; Expected : String) is
      Encoded : constant String := Encode_One (Value);
      Decoded : constant Decoded_Unit := Decode_One (Encoded, 0);
   begin
      pragma Assert (Encoded = Expected);
      pragma Assert (Is_Valid_UTF_8 (Encoded));
      pragma Assert (Decoded.Value = Value);
      pragma Assert (Natural (Decoded.Width) = Expected'Length);
   end Check_Encoding;

   procedure Check_Text_Operations is
      Two   : constant String := Bytes (16#C3#, 16#A9#);
      Three : constant String := Bytes (16#E2#, 16#82#, 16#AC#);
      Four  : constant String := Bytes (16#F0#, 16#9D#, 16#84#, 16#9E#);
      S     : constant String (17 .. 27) := "a" & Two & Three & Four & "z";
      High  : constant String (Positive'Last - 1 .. Positive'Last) := Two;
      Empty : constant String (23 .. 22) := "";
      C     : Cursor_Type := First (S);
      V     : Scalar_Value;
      Span  : Byte_Span;
   begin
      pragma Assert (Is_Valid_UTF_8 (S));
      pragma Assert (Validate (S) = (True, S'Length));
      pragma Assert (Is_ASCII ("abc") and then Is_ASCII (Empty));
      pragma Assert (not Is_ASCII (Two));
      pragma Assert (Code_Point_Length (S) = 5);
      pragma Assert (Element (S, 2) = 16#E9#);
      pragma Assert (Element (S, 3) = 16#20AC#);
      pragma Assert (Element (S, 4) = 16#1D11E#);
      pragma Assert (Decode_One (High, 0).Value = 16#E9#);
      Span := To_Byte_Span (S, 2, 3);
      pragma Assert (Span = (1, 10));
      pragma Assert (Code_Point_Length (S, Span) = 3);
      pragma Assert (Slice (S, Span) = Two & Three & Four);
      pragma Assert (Slice (S, 2, 3) = Two & Three & Four);
      pragma Assert (Slice (S, 6, 0) = "");
      pragma Assert (Slice (Empty, 1, 0) = "");
      pragma Assert (Slice (High, (0, 2)) = Two);
      pragma Assert (Is_Valid_Byte_Span (Two, (0, 0)));
      pragma Assert (Is_Valid_Byte_Span (Two, (2, 2)));
      pragma Assert (not Is_Valid_Byte_Span (Two, (1, 1)));
      pragma Assert (not Is_Valid_Byte_Span (S, (2, 3)));
      pragma Assert (not Is_Valid_Byte_Span (S, (1, 2)));
      pragma Assert (not Is_Valid_Byte_Span (S, (4, 3)));
      pragma Assert (not Is_Valid_Byte_Span (S, (0, 12)));
      pragma Assert (not Is_Valid_Byte_Span (Bytes (16#C0#, 16#AF#), (0, 2)));
      declare
         Values : constant array (Positive range <>) of Scalar_Value :=
           [97, 16#E9#, 16#20AC#, 16#1D11E#, 122];
      begin
         for Expected of Values loop
            pragma Assert (Has_Element (S, C));
            Next (S, C, V);
            pragma Assert (V = Expected);
         end loop;
      end;
      pragma Assert (not Has_Element (S, C));
      pragma Assert (not Has_Element (Empty, First (Empty)));
      pragma Assert (Is_Prefix ("a" & Two, S));
      pragma Assert (not Is_Prefix (Two, S));
      pragma Assert (not Is_Prefix (S, Two));
      pragma Assert (Is_Prefix (Empty, S));
      pragma Assert (Is_Suffix (Four & "z", S));
      pragma Assert (not Is_Suffix (Four, S));
      pragma Assert (not Is_Suffix (S, Four));
      pragma Assert (Is_Suffix (Empty, S));
      pragma Assert (Compare (Two, High) = Equal);
      pragma Assert (Compare (Two, Three) = Less);
      pragma Assert (Compare (Three, Two) = Greater);
      pragma Assert (Compare ("a", "aa") = Less);
      pragma Assert (Compare ("aa", "a") = Greater);
      pragma Assert (Compare (Empty, "") = Equal);
   end Check_Text_Operations;

   procedure Check_Long_Input is
      S      : String (1 .. 100_000) := [others => 'a'];
      Cursor : Cursor_Type := First (S);
      Value  : Scalar_Value;
   begin
      pragma Assert (Is_Valid_UTF_8 (S));
      pragma Assert (Code_Point_Length (S) = S'Length);
      pragma Assert (Element (S, S'Last) = Character'Pos ('a'));
      pragma Assert (Code_Point_Length (S, (0, S'Length)) = S'Length);
      while Has_Element (S, Cursor) loop
         Next (S, Cursor, Value);
         pragma Assert (Value = Character'Pos ('a'));
      end loop;
      pragma Assert (Byte_Offset (Cursor) = S'Length);
      S (S'Last) := Character'Val (16#80#);
      pragma Assert (not Is_Valid_UTF_8 (S));
      pragma Assert (Validate (S).Error_Offset = S'Length - 1);
   end Check_Long_Input;

   procedure Check_Invalid (S : String; Offset : Natural := 0) is
      Result : constant Validation_Result := Validate (S);
   begin
      pragma Assert (not Result.Valid);
      pragma Assert (Result.Error_Offset = Offset);
      pragma
        Assert
          (Is_Valid_UTF_8
             (S (S'First .. S'Last - (S'Length - Result.Error_Offset))));
   end Check_Invalid;
begin
   Check_Text_Operations;
   Check_Long_Input;
   pragma Assert (Validate ("").Valid);
   Check_Encoding (16#00#, String'(1 => Character'Val (0)));
   Check_Encoding (16#7F#, String'(1 => Character'Val (16#7F#)));
   Check_Encoding (16#80#, Bytes (16#C2#, 16#80#));
   Check_Encoding (16#7FF#, Bytes (16#DF#, 16#BF#));
   Check_Encoding (16#800#, Bytes (16#E0#, 16#A0#, 16#80#));
   Check_Encoding (16#D7FF#, Bytes (16#ED#, 16#9F#, 16#BF#));
   Check_Encoding (16#E000#, Bytes (16#EE#, 16#80#, 16#80#));
   Check_Encoding (16#FFFF#, Bytes (16#EF#, 16#BF#, 16#BF#));
   Check_Encoding (16#10000#, Bytes (16#F0#, 16#90#, 16#80#, 16#80#));
   Check_Encoding (16#E9#, Bytes (16#C3#, 16#A9#));
   Check_Encoding (16#20AC#, Bytes (16#E2#, 16#82#, 16#AC#));
   Check_Encoding (16#1D11E#, Bytes (16#F0#, 16#9D#, 16#84#, 16#9E#));
   Check_Encoding (16#10FFFF#, Bytes (16#F4#, 16#8F#, 16#BF#, 16#BF#));
   Check_Invalid (String'(1 => Character'Val (16#80#)));
   Check_Invalid (Bytes (16#C0#, 16#AF#));
   Check_Invalid (Bytes (16#E0#, 16#80#, 16#80#));
   Check_Invalid (Bytes (16#F0#, 16#80#, 16#80#, 16#80#));
   Check_Invalid (Bytes (16#ED#, 16#A0#, 16#80#));
   Check_Invalid (Bytes (16#F4#, 16#90#, 16#80#, 16#80#));
   Check_Invalid (String'(1 => Character'Val (16#C2#)));
   Check_Invalid (Bytes (16#E2#, 16#82#));
   Check_Invalid (Bytes (16#F0#, 16#9F#, 16#98#));
   Check_Invalid (Bytes (16#C2#, 16#61#));
   Check_Invalid (Bytes (16#E2#, 16#82#, 16#61#));
   Check_Invalid (Bytes (16#F0#, 16#90#, 16#80#, 16#61#));
   Check_Invalid (Bytes (16#C3#, 16#A9#) & Character'Val (16#FF#), 2);
   for C in Character loop
      pragma
        Assert (Is_Valid_UTF_8 (String'(1 => C)) = (Character'Pos (C) < 128));
   end loop;
   Check_Invalid ("abc" & Character'Val (16#80#), 3);
end Test;
