--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with SPARKlib_Config;

with SPARK.Big_Integers;           use SPARK.Big_Integers;
with SPARK.Strings.Unicode.Models; use SPARK.Strings.Unicode.Models;

package SPARK.Strings.Unicode.UTF_8
  with SPARK_Mode, Always_Terminates
is

   --  UTF-8 encoding and decoding using ordinary String buffers. Each
   --  Character represents one byte. Byte offsets are zero based and
   --  independent of String bounds; scalar indices are one based. Text
   --  operations work on Unicode scalar values.

   use type Scalar_Sequences.Sequence;

   subtype Octet is Natural range 0 .. 255;

   type Encoded_Width is range 1 .. 4;

   type Decoded_Unit is record
      Value : Scalar_Value;
      Width : Encoded_Width;
   end record;

   type Validation_Result is record
      Valid        : Boolean;
      Error_Offset : Natural;
   end record;
   --  Error_Offset is zero based.  On success it is S'Length; on failure it
   --  identifies the start of the first malformed encoding encountered while
   --  decoding S. The bytes preceding Error_Offset form valid UTF-8.

   function To_Octet (Value : Character) return Octet
   is (Character'Pos (Value))
   with Global => null;

   function Octet_At (S : String; Byte_Offset : Natural) return Octet
   is (To_Octet (S (S'First + Byte_Offset)))
   with Global => null, Pre => Byte_Offset < S'Length;

   function Encoding_Width (Value : Scalar_Value) return Encoded_Width
   is (if Value <= 16#007F#
       then 1
       elsif Value <= 16#07FF#
       then 2
       elsif Value <= 16#FFFF#
       then 3
       else 4)
   with Global => null;

   function Sequence_Width_At
     (S : String; Byte_Offset : Natural) return Natural
   is (if Octet_At (S, Byte_Offset) <= 16#7F#
       then 1
       elsif Octet_At (S, Byte_Offset) in 16#C2# .. 16#DF#
         and then S'Length - Byte_Offset >= 2
         and then Octet_At (S, Byte_Offset + 1) in 16#80# .. 16#BF#
       then 2
       elsif Octet_At (S, Byte_Offset) = 16#E0#
         and then S'Length - Byte_Offset >= 3
         and then Octet_At (S, Byte_Offset + 1) in 16#A0# .. 16#BF#
         and then Octet_At (S, Byte_Offset + 2) in 16#80# .. 16#BF#
       then 3
       elsif Octet_At (S, Byte_Offset) in 16#E1# .. 16#EC# | 16#EE# .. 16#EF#
         and then S'Length - Byte_Offset >= 3
         and then Octet_At (S, Byte_Offset + 1) in 16#80# .. 16#BF#
         and then Octet_At (S, Byte_Offset + 2) in 16#80# .. 16#BF#
       then 3
       elsif Octet_At (S, Byte_Offset) = 16#ED#
         and then S'Length - Byte_Offset >= 3
         and then Octet_At (S, Byte_Offset + 1) in 16#80# .. 16#9F#
         and then Octet_At (S, Byte_Offset + 2) in 16#80# .. 16#BF#
       then 3
       elsif Octet_At (S, Byte_Offset) = 16#F0#
         and then S'Length - Byte_Offset >= 4
         and then Octet_At (S, Byte_Offset + 1) in 16#90# .. 16#BF#
         and then Octet_At (S, Byte_Offset + 2) in 16#80# .. 16#BF#
         and then Octet_At (S, Byte_Offset + 3) in 16#80# .. 16#BF#
       then 4
       elsif Octet_At (S, Byte_Offset) in 16#F1# .. 16#F3#
         and then S'Length - Byte_Offset >= 4
         and then Octet_At (S, Byte_Offset + 1) in 16#80# .. 16#BF#
         and then Octet_At (S, Byte_Offset + 2) in 16#80# .. 16#BF#
         and then Octet_At (S, Byte_Offset + 3) in 16#80# .. 16#BF#
       then 4
       elsif Octet_At (S, Byte_Offset) = 16#F4#
         and then S'Length - Byte_Offset >= 4
         and then Octet_At (S, Byte_Offset + 1) in 16#80# .. 16#8F#
         and then Octet_At (S, Byte_Offset + 2) in 16#80# .. 16#BF#
         and then Octet_At (S, Byte_Offset + 3) in 16#80# .. 16#BF#
       then 4
       else 0)
   with
     Global => null,
     Pre    => Byte_Offset < S'Length,
     Post   =>
       Sequence_Width_At'Result <= 4
       and then
         (if Sequence_Width_At'Result > 0
          then Sequence_Width_At'Result <= S'Length - Byte_Offset);
   --  Returns the width of the complete valid scalar encoding starting at
   --  Byte_Offset, or zero if the encoding is malformed or incomplete.
   --  Bytes outside that encoding are not validated.

   function Valid_At (S : String; Byte_Offset : Natural) return Boolean
   is (Sequence_Width_At (S, Byte_Offset) > 0)
   with Global => null, Pre => Byte_Offset < S'Length;

   function Decode_One (S : String; Byte_Offset : Natural) return Decoded_Unit
   with
     Global => null,
     Pre    => Byte_Offset < S'Length and then Valid_At (S, Byte_Offset),
     Post   =>
       Natural (Decode_One'Result.Width) = Sequence_Width_At (S, Byte_Offset)
       and then Natural (Decode_One'Result.Width) <= S'Length - Byte_Offset
       and then
         (case Decode_One'Result.Width is
            when 1 =>
              Natural (Decode_One'Result.Value) = Octet_At (S, Byte_Offset),
            when 2 =>
              Natural (Decode_One'Result.Value)
              = (Octet_At (S, Byte_Offset) - 16#C0#)
                * 64
                + (Octet_At (S, Byte_Offset + 1) - 16#80#),
            when 3 =>
              Natural (Decode_One'Result.Value)
              = (Octet_At (S, Byte_Offset) - 16#E0#) * 4_096
                + (Octet_At (S, Byte_Offset + 1) - 16#80#) * 64
                + (Octet_At (S, Byte_Offset + 2) - 16#80#),
            when 4 =>
              Natural (Decode_One'Result.Value)
              = (Octet_At (S, Byte_Offset) - 16#F0#) * 262_144
                + (Octet_At (S, Byte_Offset + 1) - 16#80#) * 4_096
                + (Octet_At (S, Byte_Offset + 2) - 16#80#) * 64
                + (Octet_At (S, Byte_Offset + 3) - 16#80#));

   function Is_Valid_UTF_8 (S : String) return Boolean
   with Global => null, Post => (if S'Length = 0 then Is_Valid_UTF_8'Result);

   function Is_ASCII (S : String) return Boolean
   is (S'Length = 0
       or else
         (for all Offset in Natural range 0 .. S'Length - 1 =>
            Octet_At (S, Offset) <= 16#7F#))
   with Global => null;

   function Is_Encoding (S : String; Value : Text) return Boolean
   with Global => null, Ghost => Static, Pre => Is_Valid_UTF_8 (S);
   --  Relates the complete byte sequence in S to the complete scalar sequence
   --  in Value.  It is independent of Ada array bounds.

   function Model (S : String) return Text
   with
     Global => null,
     Ghost  => Static,
     Pre    => Is_Valid_UTF_8 (S),
     Post   =>
       (Static =>
          Is_Encoding (S, Model'Result)
          and then
            Scalar_Sequences.Length (Model'Result)
            <= To_Big_Integer (S'Length));

   function Encode_One (Value : Scalar_Value) return String
   with
     Global => null,
     Post   =>
       (Runtime =>
          Encode_One'Result'First = 1
          and then Encode_One'Result'Length = Encoding_Width (Value)
          and then
            (case Encoding_Width (Value) is
               when 1 => Octet_At (Encode_One'Result, 0) = Natural (Value),
               when 2 =>
                 Octet_At (Encode_One'Result, 0)
                 = 16#C0# + Natural (Value) / 64
                 and then
                   Octet_At (Encode_One'Result, 1)
                   = 16#80# + Natural (Value) mod 64,
               when 3 =>
                 Octet_At (Encode_One'Result, 0)
                 = 16#E0# + Natural (Value) / 4_096
                 and then
                   Octet_At (Encode_One'Result, 1)
                   = 16#80# + (Natural (Value) / 64) mod 64
                 and then
                   Octet_At (Encode_One'Result, 2)
                   = 16#80# + Natural (Value) mod 64,
               when 4 =>
                 Octet_At (Encode_One'Result, 0)
                 = 16#F0# + Natural (Value) / 262_144
                 and then
                   Octet_At (Encode_One'Result, 1)
                   = 16#80# + (Natural (Value) / 4_096) mod 64
                 and then
                   Octet_At (Encode_One'Result, 2)
                   = 16#80# + (Natural (Value) / 64) mod 64
                 and then
                   Octet_At (Encode_One'Result, 3)
                   = 16#80# + Natural (Value) mod 64)
          and then Is_Valid_UTF_8 (Encode_One'Result)
          and then Valid_At (Encode_One'Result, 0)
          and then
            Decode_One (Encode_One'Result, 0)
            = (Value => Value, Width => Encoding_Width (Value)),
        Static  => Model (Encode_One'Result) = [Value]);

   function Same_Bytes
     (Left         : String;
      Left_Offset  : Natural;
      Right        : String;
      Right_Offset : Natural;
      Count        : Natural) return Boolean
   is (Count = 0
       or else
         (for all I in Natural range 0 .. Count - 1 =>
            Octet_At (Left, Left_Offset + I)
            = Octet_At (Right, Right_Offset + I)))
   with
     Global => null,
     Ghost  => Static,
     Pre    =>
       Left_Offset <= Left'Length
       and then Count <= Left'Length - Left_Offset
       and then Right_Offset <= Right'Length
       and then Count <= Right'Length - Right_Offset;
   --  Positional equality of two byte ranges.  The relation uses zero-based
   --  offsets and is independent of the Ada bounds of either string.

   procedure Lemma_Append
     (Prefix : String; Value : Scalar_Value; Result : String)
   with
     Ghost  => Static,
     Global => null,
     Pre    =>
       Is_Valid_UTF_8 (Prefix)
       and then
         Prefix'Length <= Natural'Last - Natural (Encoding_Width (Value))
       and then
         Result'Length = Prefix'Length + Natural (Encoding_Width (Value))
       and then Same_Bytes (Prefix, 0, Result, 0, Prefix'Length)
       and then
         Same_Bytes
           (Encode_One (Value),
            0,
            Result,
            Prefix'Length,
            Natural (Encoding_Width (Value))),
     Post   =>
       Is_Valid_UTF_8 (Result)
       and then Is_Concatenation (Model (Prefix), [Value], Model (Result));
   --  Appending the encoding of one scalar preserves validity and extends
   --  the model by that scalar. Result may have different Ada array bounds.

   function Code_Point_Length (S : String) return Natural
   with
     Global => null,
     Pre    => Is_Valid_UTF_8 (S),
     Post   =>
       (Runtime => Code_Point_Length'Result <= S'Length,
        Static  =>
          To_Big_Integer (Code_Point_Length'Result)
          = Scalar_Sequences.Length (Model (S))
          and then
            To_Big_Integer (S'Length)
            <= 4 * To_Big_Integer (Code_Point_Length'Result));

   function Element (S : String; Index : Positive) return Scalar_Value
   with
     Global => null,
     Pre    => Is_Valid_UTF_8 (S) and then Index <= Code_Point_Length (S),
     Post   =>
       (Static =>
          Element'Result
          = Scalar_Sequences.Get (Model (S), To_Big_Integer (Index)));
   --  Scans from the beginning of S. Use a cursor for sequential traversal
   --  to avoid repeated scans.

   type Byte_Span is record
      First     : Natural;
      Past_Last : Natural;
   end record;
   --  A byte interval including First and excluding Past_Last. Valid spans
   --  start and end at scalar boundaries, including empty spans.

   function Is_Valid_Byte_Span (S : String; Span : Byte_Span) return Boolean
   with
     Global => null,
     Post   =>
       (if Is_Valid_Byte_Span'Result
        then
          Is_Valid_UTF_8 (S)
          and then Span.First <= Span.Past_Last
          and then Span.Past_Last <= S'Length
          and then (Span.First = S'Length or else Valid_At (S, Span.First)));
   --  Returns False if any part of S is invalid UTF-8, even outside Span.
   --  Otherwise checks the bounds and scalar boundaries of Span.

   function Code_Point_Length (S : String; Span : Byte_Span) return Natural
   with
     Global => null,
     Pre    => Is_Valid_Byte_Span (S, Span),
     Post   => Code_Point_Length'Result <= Span.Past_Last - Span.First;

   function Model (S : String; Span : Byte_Span) return Text
   with
     Global => null,
     Ghost  => Static,
     Pre    => Is_Valid_Byte_Span (S, Span),
     Post   =>
       Scalar_Sequences.Length (Model'Result)
       = To_Big_Integer (Code_Point_Length (S, Span));

   function Slice (S : String; Span : Byte_Span) return String
   with
     Global => null,
     Pre    => Is_Valid_Byte_Span (S, Span),
     Post   =>
       (Runtime =>
          Slice'Result'First = 1
          and then Slice'Result'Length = Span.Past_Last - Span.First
          and then
            Code_Point_Length (Slice'Result) = Code_Point_Length (S, Span)
          and then Is_Valid_UTF_8 (Slice'Result),
        Static  =>
          Same_Bytes (S, Span.First, Slice'Result, 0, Slice'Result'Length)
          and then Model (Slice'Result) = Model (S, Span));
   --  Copies the selected bytes into a string with lower bound 1

   function To_Byte_Span
     (S : String; First : Positive; Count : Natural) return Byte_Span
   with
     Global => null,
     Pre    =>
       Is_Valid_UTF_8 (S)
       and then First - 1 <= Code_Point_Length (S)
       and then Count <= Code_Point_Length (S) - (First - 1),
     Post   =>
       (Runtime =>
          Is_Valid_Byte_Span (S, To_Byte_Span'Result)
          and then Code_Point_Length (S, To_Byte_Span'Result) = Count,
        Static  =>
          Is_Slice
            (Source => Model (S),
             First  => To_Big_Integer (First),
             Count  => To_Big_Integer (Count),
             Result => Model (Slice (S, To_Byte_Span'Result))));
   --  First and Count are measured in scalar values. An empty span may start
   --  immediately after the last scalar.

   function Slice (S : String; First : Positive; Count : Natural) return String
   with
     Global => null,
     Pre    =>
       Is_Valid_UTF_8 (S)
       and then First - 1 <= Code_Point_Length (S)
       and then Count <= Code_Point_Length (S) - (First - 1),
     Post   =>
       (Runtime =>
          Slice'Result'First = 1
          and then Slice'Result'Length <= S'Length
          and then Is_Valid_UTF_8 (Slice'Result),
        Static  =>
          Is_Slice
            (Source => Model (S),
             First  => To_Big_Integer (First),
             Count  => To_Big_Integer (Count),
             Result => Model (Slice'Result)));

   type Cursor_Index is range 1 .. Long_Long_Integer'Last;

   type Cursor_Type is private;
   --  Identifies the next scalar to read. Keep the source unchanged during
   --  traversal. At the end, Byte_Offset is the byte length and Scalar_Index
   --  is the scalar count plus one. Has_Element and Next take constant time,
   --  including when runtime assertions are enabled.

   function Byte_Offset (Cursor : Cursor_Type) return Natural
   with Global => null;

   function Scalar_Index (Cursor : Cursor_Type) return Cursor_Index
   with Global => null;

   function Big_Scalar_Index (Cursor : Cursor_Type) return Big_Positive
   with Global => null, Ghost => Static;

   function Is_Valid_Cursor (S : String; Cursor : Cursor_Type) return Boolean
   with Global => null, Ghost => Static;

   function First (S : String) return Cursor_Type
   with
     Global => null,
     Pre    => Is_Valid_UTF_8 (S),
     Post   =>
       (Runtime =>
          Is_Valid_UTF_8 (S)
          and then Byte_Offset (First'Result) = 0
          and then Scalar_Index (First'Result) = 1,
        Static  =>
          Is_Valid_Cursor (S, First'Result)
          and then Big_Scalar_Index (First'Result) = 1);

   function Has_Element (S : String; Cursor : Cursor_Type) return Boolean
   with
     Global => null,
     Pre    => (Static => Is_Valid_Cursor (S, Cursor)),
     Post   =>
       (Runtime =>
          Has_Element'Result = (Byte_Offset (Cursor) < S'Length)
          and then
            (if Has_Element'Result then Valid_At (S, Byte_Offset (Cursor))),
        Static  =>
          Has_Element'Result
          = (Big_Scalar_Index (Cursor)
             <= Scalar_Sequences.Length (Model (S))));

   procedure Next
     (S : String; Cursor : in out Cursor_Type; Value : out Scalar_Value)
   with
     Global => null,
     Pre    =>
       (Runtime =>
          Byte_Offset (Cursor) < S'Length
          and then Valid_At (S, Byte_Offset (Cursor)),
        Static  => Is_Valid_Cursor (S, Cursor)),
     Post   =>
       (Runtime =>
          Scalar_Index (Cursor) = Scalar_Index (Cursor'Old) + 1
          and then
            Byte_Offset (Cursor)
            = Byte_Offset (Cursor'Old) + Natural (Encoding_Width (Value))
          and then
            Byte_Offset (Cursor)
            = Byte_Offset (Cursor'Old)
              + Sequence_Width_At (S, Byte_Offset (Cursor'Old))
          and then Value = Decode_One (S, Byte_Offset (Cursor'Old)).Value
          and then Byte_Offset (Cursor) > Byte_Offset (Cursor'Old),
        Static  =>
          Is_Valid_Cursor (S, Cursor)
          and then
            Big_Scalar_Index (Cursor) = Big_Scalar_Index (Cursor'Old) + 1
          and then
            Value
            = Scalar_Sequences.Get (Model (S), Big_Scalar_Index (Cursor'Old)));
   --  Returns the scalar at Cursor in Value, then advances Cursor

   type Comparison_Result is (Less, Equal, Greater);

   function Is_Prefix (Prefix, Whole : String) return Boolean
   with
     Global => null,
     Pre    => Is_Valid_UTF_8 (Prefix) and then Is_Valid_UTF_8 (Whole),
     Post   =>
       (Static =>
          Is_Prefix'Result
          = SPARK.Strings.Unicode.Models.Is_Prefix
              (Model (Prefix), Model (Whole)));

   function Is_Suffix (Suffix, Whole : String) return Boolean
   with
     Global => null,
     Pre    => Is_Valid_UTF_8 (Suffix) and then Is_Valid_UTF_8 (Whole),
     Post   =>
       (Static =>
          Is_Suffix'Result
          = SPARK.Strings.Unicode.Models.Is_Suffix
              (Model (Suffix), Model (Whole)));

   function Compare (Left, Right : String) return Comparison_Result
   with
     Global => null,
     Pre    => Is_Valid_UTF_8 (Left) and then Is_Valid_UTF_8 (Right),
     Post   =>
       (Static =>
          (case Compare'Result is
             when Less    =>
               Is_Lexicographically_Less (Model (Left), Model (Right)),
             when Equal   => Model (Left) = Model (Right),
             when Greater =>
               Is_Lexicographically_Less (Model (Right), Model (Left))));
   --  Lexicographic comparison by scalar value, without normalization or
   --  locale-specific ordering.

   function Validate (S : String) return Validation_Result
   with
     Global => null,
     Post   =>
       (Runtime =>
          Validate'Result.Valid = Is_Valid_UTF_8 (S)
          and then
            (if Validate'Result.Valid
             then Validate'Result.Error_Offset = S'Length
             else
               Validate'Result.Error_Offset < S'Length
               and then not Valid_At (S, Validate'Result.Error_Offset)),
        Static  =>
          Is_Valid_UTF_8
            (S
               (S'First
                .. S'Last - (S'Length - Validate'Result.Error_Offset))));

private
   pragma SPARK_Mode (SPARKlib_Config.Body_Mode);

   package Cursor_Index_Conversions is new Signed_Conversions (Cursor_Index);

   type Cursor_Type is record
      Offset : Natural := 0;
      Index  : Cursor_Index := 1;
   end record;

   -----------------
   -- Byte_Offset --
   -----------------

   function Byte_Offset (Cursor : Cursor_Type) return Natural
   is (Cursor.Offset);

   ------------------
   -- Scalar_Index --
   ------------------

   function Scalar_Index (Cursor : Cursor_Type) return Cursor_Index
   is (Cursor.Index);

   ----------------------
   -- Big_Scalar_Index --
   ----------------------

   function Big_Scalar_Index (Cursor : Cursor_Type) return Big_Positive
   is (Cursor_Index_Conversions.To_Big_Integer (Cursor.Index));

end SPARK.Strings.Unicode.UTF_8;
