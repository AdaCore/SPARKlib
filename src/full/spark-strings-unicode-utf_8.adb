--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package body SPARK.Strings.Unicode.UTF_8
  with SPARK_Mode => SPARKlib_Config.Body_Mode
is

   --  Recursive ghost functions provide inductive definitions for the proofs.
   --  Executable traversal uses loops so that stack usage does not grow with
   --  the input length.

   function Recursive_Valid_From
     (S : String; Byte_Offset : Natural) return Boolean
   with
     Ghost              => Static,
     Pre                => Byte_Offset <= S'Length,
     Subprogram_Variant => (Decreases => S'Length - Byte_Offset);

   function Valid_From (S : String; Byte_Offset : Natural) return Boolean
   with
     Pre  => Byte_Offset <= S'Length,
     Post =>
       (Static => Valid_From'Result = Recursive_Valid_From (S, Byte_Offset));

   function Model_From (S : String; Byte_Offset : Natural) return Text
   with
     Ghost              => Static,
     Pre                =>
       Byte_Offset <= S'Length and then Valid_From (S, Byte_Offset),
     Post               =>
       (Static =>
          Scalar_Sequences.Length (Model_From'Result)
          <= To_Big_Integer (S'Length - Byte_Offset)),
     Subprogram_Variant => (Decreases => S'Length - Byte_Offset);

   function Recursive_Length_From
     (S : String; Byte_Offset : Natural) return Natural
   with
     Ghost              => Static,
     Pre                =>
       Byte_Offset <= S'Length and then Valid_From (S, Byte_Offset),
     Post               =>
       (Runtime => Recursive_Length_From'Result <= S'Length - Byte_Offset,
        Static  =>
          To_Big_Integer (Recursive_Length_From'Result)
          = Scalar_Sequences.Length (Model_From (S, Byte_Offset))
          and then
            To_Big_Integer (S'Length - Byte_Offset)
            <= 4 * To_Big_Integer (Recursive_Length_From'Result)),
     Subprogram_Variant => (Decreases => S'Length - Byte_Offset);

   function Length_From (S : String; Byte_Offset : Natural) return Natural
   with
     Pre  => Byte_Offset <= S'Length and then Valid_From (S, Byte_Offset),
     Post =>
       (Runtime => Length_From'Result <= S'Length - Byte_Offset,
        Static  =>
          Length_From'Result = Recursive_Length_From (S, Byte_Offset)
          and then
            To_Big_Integer (Length_From'Result)
            = Scalar_Sequences.Length (Model_From (S, Byte_Offset))
          and then
            To_Big_Integer (S'Length - Byte_Offset)
            <= 4 * To_Big_Integer (Length_From'Result));

   function Recursive_Element_From
     (S : String; Byte_Offset : Natural; Index : Positive) return Scalar_Value
   with
     Ghost              => Static,
     Pre                =>
       Byte_Offset < S'Length
       and then Valid_From (S, Byte_Offset)
       and then Index <= Length_From (S, Byte_Offset),
     Post               =>
       (Static =>
          Recursive_Element_From'Result
          = Scalar_Sequences.Get
              (Model_From (S, Byte_Offset), To_Big_Integer (Index))),
     Subprogram_Variant => (Decreases => Index);

   function Element_From
     (S : String; Byte_Offset : Natural; Index : Positive) return Scalar_Value
   with
     Pre  =>
       Byte_Offset < S'Length
       and then Valid_From (S, Byte_Offset)
       and then Index <= Length_From (S, Byte_Offset),
     Post =>
       (Static =>
          Element_From'Result = Recursive_Element_From (S, Byte_Offset, Index)
          and then
            Element_From'Result
            = Scalar_Sequences.Get
                (Model_From (S, Byte_Offset), To_Big_Integer (Index)));

   function Recursive_Is_Valid_Range
     (S : String; First, Past_Last : Natural) return Boolean
   with
     Ghost              => Static,
     Pre                => First <= Past_Last and then Past_Last <= S'Length,
     Subprogram_Variant => (Decreases => Past_Last - First);

   function Is_Valid_Range
     (S : String; First, Past_Last : Natural) return Boolean
   with
     Pre  => First <= Past_Last and then Past_Last <= S'Length,
     Post =>
       (Static =>
          Is_Valid_Range'Result
          = Recursive_Is_Valid_Range (S, First, Past_Last));

   function Recursive_Valid_Range_Length
     (S : String; First, Past_Last : Natural) return Natural
   with
     Ghost              => Static,
     Pre                =>
       First <= Past_Last
       and then Past_Last <= S'Length
       and then Is_Valid_Range (S, First, Past_Last),
     Post               =>
       Recursive_Valid_Range_Length'Result <= Past_Last - First,
     Subprogram_Variant => (Decreases => Past_Last - First);

   function Valid_Range_Length
     (S : String; First, Past_Last : Natural) return Natural
   with
     Pre  =>
       First <= Past_Last
       and then Past_Last <= S'Length
       and then Is_Valid_Range (S, First, Past_Last),
     Post =>
       (Runtime => Valid_Range_Length'Result <= Past_Last - First,
        Static  =>
          Valid_Range_Length'Result
          = Recursive_Valid_Range_Length (S, First, Past_Last));

   function Range_Model (S : String; First, Past_Last : Natural) return Text
   with
     Ghost              => Static,
     Pre                =>
       First <= Past_Last
       and then Past_Last <= S'Length
       and then Is_Valid_Range (S, First, Past_Last),
     Post               =>
       Scalar_Sequences.Length (Range_Model'Result)
       = To_Big_Integer (Valid_Range_Length (S, First, Past_Last)),
     Subprogram_Variant => (Decreases => Past_Last - First);

   function Cursor_At_Index (S : String; Index : Positive) return Cursor_Type
   with
     Pre  => Is_Valid_UTF_8 (S) and then Index - 1 <= Code_Point_Length (S),
     Post =>
       (Runtime =>
          Scalar_Index (Cursor_At_Index'Result) = Cursor_Index (Index),
        Static  => Is_Valid_Cursor (S, Cursor_At_Index'Result));

   --  Proof lemmas

   procedure Lemma_Extend_Valid_Range
     (S : String; First, Old_Past_Last, New_Past_Last : Natural)
   with
     Ghost              => Static,
     Global             => null,
     Pre                =>
       First <= Old_Past_Last
       and then Old_Past_Last < New_Past_Last
       and then New_Past_Last <= S'Length
       and then Is_Valid_Range (S, First, Old_Past_Last)
       and then Valid_At (S, Old_Past_Last)
       and then
         New_Past_Last = Old_Past_Last + Sequence_Width_At (S, Old_Past_Last),
     Post               =>
       Is_Valid_Range (S, First, New_Past_Last)
       and then
         Valid_Range_Length (S, First, New_Past_Last)
         = Valid_Range_Length (S, First, Old_Past_Last) + 1
       and then
         Is_Concatenation
           (Range_Model (S, First, Old_Past_Last),
            [Decode_One (S, Old_Past_Last).Value],
            Range_Model (S, First, New_Past_Last)),
     Subprogram_Variant => (Decreases => Old_Past_Last - First);

   procedure Lemma_Rebased_Valid_Range
     (Left         : String;
      Left_Offset  : Natural;
      Right        : String;
      Right_Offset : Natural;
      Count        : Natural)
   with
     Ghost              => Static,
     Global             => null,
     Pre                =>
       Left_Offset <= Left'Length
       and then Count <= Left'Length - Left_Offset
       and then Right_Offset <= Right'Length
       and then Count = Right'Length - Right_Offset
       and then Same_Bytes (Left, Left_Offset, Right, Right_Offset, Count)
       and then Is_Valid_Range (Left, Left_Offset, Left_Offset + Count),
     Post               =>
       Valid_From (Right, Right_Offset)
       and then
         Scalar_Sequences.Length (Model_From (Right, Right_Offset))
         = To_Big_Integer
             (Valid_Range_Length (Left, Left_Offset, Left_Offset + Count))
       and then
         Model_From (Right, Right_Offset)
         = Range_Model (Left, Left_Offset, Left_Offset + Count),
     Subprogram_Variant => (Decreases => Count);

   -----------------------
   -- Code_Point_Length --
   -----------------------

   function Code_Point_Length (S : String) return Natural
   is (Length_From (S, 0));

   -----------------------
   -- Code_Point_Length --
   -----------------------

   function Code_Point_Length (S : String; Span : Byte_Span) return Natural
   is (Valid_Range_Length (S, Span.First, Span.Past_Last));

   -------------
   -- Compare --
   -------------

   function Compare (Left, Right : String) return Comparison_Result is
      Left_Cursor  : Cursor_Type := First (Left);
      Right_Cursor : Cursor_Type := First (Right);
      Left_Value   : Scalar_Value;
      Right_Value  : Scalar_Value;
   begin
      while Has_Element (Left, Left_Cursor)
        and then Has_Element (Right, Right_Cursor)
      loop
         pragma Loop_Invariant (Static => Is_Valid_Cursor (Left, Left_Cursor));
         pragma
           Loop_Invariant (Static => Is_Valid_Cursor (Right, Right_Cursor));
         pragma
           Loop_Invariant
             (Scalar_Index (Left_Cursor) = Scalar_Index (Right_Cursor));
         pragma
           Loop_Invariant
             (Static =>
                (for all I in Model (Left) =>
                   (if I
                      < Cursor_Index_Conversions.To_Big_Integer
                          (Scalar_Index (Left_Cursor))
                    then
                      Scalar_Sequences.Get (Model (Left), I)
                      = Scalar_Sequences.Get (Model (Right), I))));
         pragma
           Loop_Variant (Decreases => Left'Length - Byte_Offset (Left_Cursor));

         declare
            Current_Index : constant Big_Positive :=
              Cursor_Index_Conversions.To_Big_Integer
                (Scalar_Index (Left_Cursor))
            with Ghost => Static;
         begin
            Next (Left, Left_Cursor, Left_Value);
            Next (Right, Right_Cursor, Right_Value);
            if Left_Value < Right_Value then
               pragma
                 Assert
                   (Static =>
                      (for all J in Model (Left) =>
                         (if J < Current_Index
                          then
                            Scalar_Sequences.Get (Model (Left), J)
                            = Scalar_Sequences.Get (Model (Right), J))));
               pragma
                 Assert
                   (Static =>
                      Scalar_Sequences.Get (Model (Left), Current_Index)
                      < Scalar_Sequences.Get (Model (Right), Current_Index));
               pragma
                 Assert
                   (Static =>
                      Is_Lexicographically_Less (Model (Left), Model (Right)));
               return Less;
            elsif Left_Value > Right_Value then
               pragma
                 Assert
                   (Static =>
                      Is_Lexicographically_Less (Model (Right), Model (Left)));
               return Greater;
            end if;
         end;
      end loop;

      if Has_Element (Right, Right_Cursor) then
         pragma
           Assert
             (Static =>
                SPARK.Strings.Unicode.Models.Is_Prefix
                  (Model (Left), Model (Right)));
         pragma
           Assert
             (Static =>
                Scalar_Sequences.Length (Model (Left))
                < Scalar_Sequences.Length (Model (Right)));
         pragma
           Assert
             (Static =>
                Is_Lexicographically_Less (Model (Left), Model (Right)));
         return Less;
      elsif Has_Element (Left, Left_Cursor) then
         pragma
           Assert
             (Static =>
                Is_Lexicographically_Less (Model (Right), Model (Left)));
         return Greater;
      else
         return Equal;
      end if;
   end Compare;

   ---------------------
   -- Cursor_At_Index --
   ---------------------

   function Cursor_At_Index (S : String; Index : Positive) return Cursor_Type
   is
      Cursor : Cursor_Type := First (S);
      Value  : Scalar_Value;
   begin
      for Position in 1 .. Index - 1 loop
         pragma Loop_Invariant (Static => Is_Valid_Cursor (S, Cursor));
         pragma
           Loop_Invariant (Scalar_Index (Cursor) = Cursor_Index (Position));
         Next (S, Cursor, Value);
         pragma Assert (Value in Scalar_Value);
      end loop;
      return Cursor;
   end Cursor_At_Index;

   ----------------
   -- Decode_One --
   ----------------

   function Decode_One (S : String; Byte_Offset : Natural) return Decoded_Unit
   is
      B0    : constant Octet := Octet_At (S, Byte_Offset);
      Width : constant Natural := Sequence_Width_At (S, Byte_Offset);
   begin
      if Width = 1 then
         return (Value => Scalar_Value (B0), Width => 1);
      elsif Width = 2 then
         declare
            B1 : constant Octet := Octet_At (S, Byte_Offset + 1);
            V  : constant Natural := (B0 - 16#C0#) * 64 + (B1 - 16#80#);
         begin
            pragma Assert (V in 16#80# .. 16#7FF#);
            return (Value => Scalar_Value (V), Width => 2);
         end;
      elsif Width = 3 then
         declare
            B1 : constant Octet := Octet_At (S, Byte_Offset + 1);
            B2 : constant Octet := Octet_At (S, Byte_Offset + 2);
            V  : constant Natural :=
              (B0 - 16#E0#) * 4_096 + (B1 - 16#80#) * 64 + (B2 - 16#80#);
         begin
            pragma Assert (V in 16#800# .. 16#D7FF# | 16#E000# .. 16#FFFF#);
            return (Value => Scalar_Value (V), Width => 3);
         end;
      else
         declare
            B1 : constant Octet := Octet_At (S, Byte_Offset + 1);
            B2 : constant Octet := Octet_At (S, Byte_Offset + 2);
            B3 : constant Octet := Octet_At (S, Byte_Offset + 3);
            V  : constant Natural :=
              (B0 - 16#F0#) * 262_144 + (B1 - 16#80#) * 4_096
              + (B2 - 16#80#) * 64
              + (B3 - 16#80#);
         begin
            pragma Assert (V in 16#1_0000# .. 16#10_FFFF#);
            return (Value => Scalar_Value (V), Width => 4);
         end;
      end if;
   end Decode_One;

   -------------
   -- Element --
   -------------

   function Element (S : String; Index : Positive) return Scalar_Value
   is (Element_From (S, 0, Index));

   ------------------
   -- Element_From --
   ------------------

   function Element_From
     (S : String; Byte_Offset : Natural; Index : Positive) return Scalar_Value
   is
      Offset    : Natural := Byte_Offset;
      Remaining : Positive := Index;
   begin
      while Remaining > 1 loop
         pragma
           Loop_Invariant (Static => Offset in Byte_Offset .. S'Length - 1);
         pragma Loop_Invariant (Static => Valid_From (S, Offset));
         pragma
           Loop_Invariant (Static => Remaining <= Length_From (S, Offset));
         pragma
           Loop_Invariant
             (Static =>
                Recursive_Element_From (S, Byte_Offset, Index)
                = Recursive_Element_From (S, Offset, Remaining));
         pragma Loop_Variant (Decreases => Remaining);
         Offset := Offset + Sequence_Width_At (S, Offset);
         Remaining := Remaining - 1;
      end loop;
      return Decode_One (S, Offset).Value;
   end Element_From;

   ----------------
   -- Encode_One --
   ----------------

   function Encode_One (Value : Scalar_Value) return String is
   begin
      if Value <= 16#007F# then
         return [1 => Character'Val (Value)];
      elsif Value <= 16#07FF# then
         return
           [Character'Val (16#C0# + Value / 64),
            Character'Val (16#80# + Value mod 64)];
      elsif Value <= 16#FFFF# then
         return
           [Character'Val (16#E0# + Value / 4_096),
            Character'Val (16#80# + (Value / 64) mod 64),
            Character'Val (16#80# + Value mod 64)];
      else
         return
           [Character'Val (16#F0# + Value / 262_144),
            Character'Val (16#80# + (Value / 4_096) mod 64),
            Character'Val (16#80# + (Value / 64) mod 64),
            Character'Val (16#80# + Value mod 64)];
      end if;
   end Encode_One;

   -----------
   -- First --
   -----------

   function First (S : String) return Cursor_Type
   is ((Offset => 0, Index => 1));

   -----------------
   -- Has_Element --
   -----------------

   function Has_Element (S : String; Cursor : Cursor_Type) return Boolean is
   begin
      if Cursor.Offset < S'Length then
         pragma Assert (Valid_At (S, Cursor.Offset));
         pragma
           Assert
             (Static =>
                Scalar_Sequences.Length (Model_From (S, Cursor.Offset)) > 0);
         pragma
           Assert
             (Static =>
                Cursor_Index_Conversions.To_Big_Integer (Cursor.Index)
                <= Scalar_Sequences.Length (Model (S)));
         return True;
      else
         pragma Assert (Cursor.Offset = S'Length);
         pragma
           Assert
             (Static =>
                Scalar_Sequences.Length (Model_From (S, Cursor.Offset)) = 0);
         pragma
           Assert
             (Static =>
                Cursor_Index_Conversions.To_Big_Integer (Cursor.Index)
                = Scalar_Sequences.Length (Model (S)) + 1);
         return False;
      end if;
   end Has_Element;

   -----------------
   -- Is_Encoding --
   -----------------

   function Is_Encoding (S : String; Value : Text) return Boolean
   is (Value = Model_From (S, 0));

   ---------------
   -- Is_Prefix --
   ---------------

   function Is_Prefix (Prefix, Whole : String) return Boolean is
      Prefix_Length : constant Natural := Code_Point_Length (Prefix);
      Whole_Length  : constant Natural := Code_Point_Length (Whole);
   begin
      if Prefix_Length > Whole_Length then
         return False;
      end if;

      declare
         Prefix_Cursor : Cursor_Type := First (Prefix);
         Whole_Cursor  : Cursor_Type := First (Whole);
         Prefix_Value  : Scalar_Value;
         Whole_Value   : Scalar_Value;
      begin
         while Has_Element (Prefix, Prefix_Cursor) loop
            pragma
              Loop_Invariant
                (Static => Is_Valid_Cursor (Prefix, Prefix_Cursor));
            pragma
              Loop_Invariant (Static => Is_Valid_Cursor (Whole, Whole_Cursor));
            pragma
              Loop_Invariant
                (Scalar_Index (Prefix_Cursor) = Scalar_Index (Whole_Cursor));
            pragma
              Loop_Invariant
                (Static =>
                   (for all I in Model (Prefix) =>
                      (if I
                         < Cursor_Index_Conversions.To_Big_Integer
                             (Scalar_Index (Prefix_Cursor))
                       then
                         Scalar_Sequences.Get (Model (Prefix), I)
                         = Scalar_Sequences.Get (Model (Whole), I))));
            pragma
              Loop_Variant
                (Decreases => Prefix'Length - Byte_Offset (Prefix_Cursor));

            Next (Prefix, Prefix_Cursor, Prefix_Value);
            Next (Whole, Whole_Cursor, Whole_Value);
            if Prefix_Value /= Whole_Value then
               return False;
            end if;
         end loop;
         return True;
      end;
   end Is_Prefix;

   ---------------
   -- Is_Suffix --
   ---------------

   function Is_Suffix (Suffix, Whole : String) return Boolean is
      Suffix_Length : constant Natural := Code_Point_Length (Suffix);
      Whole_Length  : constant Natural := Code_Point_Length (Whole);
   begin
      if Suffix_Length > Whole_Length then
         return False;
      end if;

      declare
         Difference    : constant Natural := Whole_Length - Suffix_Length;
         Suffix_Cursor : Cursor_Type := First (Suffix);
         Whole_Cursor  : Cursor_Type := First (Whole);
         Suffix_Value  : Scalar_Value;
         Whole_Value   : Scalar_Value;
      begin
         if Difference > 0 then
            for Ignored in 1 .. Difference loop
               pragma
                 Loop_Invariant
                   (Static => Is_Valid_Cursor (Whole, Whole_Cursor));
               pragma
                 Loop_Invariant
                   (Scalar_Index (Whole_Cursor) = Cursor_Index (Ignored));
               declare
                  Ignored_Value : Scalar_Value;
               begin
                  Next (Whole, Whole_Cursor, Ignored_Value);
                  pragma Assert (Ignored_Value in Scalar_Value);
               end;
            end loop;
         end if;

         while Has_Element (Suffix, Suffix_Cursor) loop
            pragma
              Loop_Invariant
                (Static => Is_Valid_Cursor (Suffix, Suffix_Cursor));
            pragma
              Loop_Invariant (Static => Is_Valid_Cursor (Whole, Whole_Cursor));
            pragma
              Loop_Invariant
                (Static =>
                   Cursor_Index_Conversions.To_Big_Integer
                     (Scalar_Index (Whole_Cursor))
                   = Cursor_Index_Conversions.To_Big_Integer
                       (Scalar_Index (Suffix_Cursor))
                     + To_Big_Integer (Difference));
            pragma
              Loop_Invariant
                (Static =>
                   (for all I in Model (Suffix) =>
                      (if I
                         < Cursor_Index_Conversions.To_Big_Integer
                             (Scalar_Index (Suffix_Cursor))
                       then
                         Scalar_Sequences.Get (Model (Suffix), I)
                         = Scalar_Sequences.Get
                             (Model (Whole),
                              To_Big_Integer (Difference) + I))));
            pragma
              Loop_Variant
                (Decreases => Suffix'Length - Byte_Offset (Suffix_Cursor));

            Next (Suffix, Suffix_Cursor, Suffix_Value);
            Next (Whole, Whole_Cursor, Whole_Value);
            if Suffix_Value /= Whole_Value then
               return False;
            end if;
         end loop;
         return True;
      end;
   end Is_Suffix;

   ------------------------
   -- Is_Valid_Byte_Span --
   ------------------------

   function Is_Valid_Byte_Span (S : String; Span : Byte_Span) return Boolean
   is (Is_Valid_UTF_8 (S)
       and then Span.First <= Span.Past_Last
       and then Span.Past_Last <= S'Length
       and then (Span.First = S'Length or else Valid_At (S, Span.First))
       and then Is_Valid_Range (S, Span.First, Span.Past_Last));

   ---------------------
   -- Is_Valid_Cursor --
   ---------------------

   function Is_Valid_Cursor (S : String; Cursor : Cursor_Type) return Boolean
   is (Is_Valid_UTF_8 (S)
       and then Cursor.Offset <= S'Length
       and then Valid_From (S, Cursor.Offset)
       and then
         Cursor_Index_Conversions.To_Big_Integer (Cursor.Index)
         <= Scalar_Sequences.Length (Model (S)) + 1
       and then
         Scalar_Sequences.Length (Model_From (S, Cursor.Offset))
         = Scalar_Sequences.Length (Model (S))
           - (Cursor_Index_Conversions.To_Big_Integer (Cursor.Index) - 1)
       and then
         Is_Slice
           (Source => Model (S),
            First  => Cursor_Index_Conversions.To_Big_Integer (Cursor.Index),
            Count  => Scalar_Sequences.Length (Model_From (S, Cursor.Offset)),
            Result => Model_From (S, Cursor.Offset)));

   --------------------
   -- Is_Valid_Range --
   --------------------

   function Is_Valid_Range
     (S : String; First, Past_Last : Natural) return Boolean
   is
      Offset : Natural := First;
   begin
      while Offset < Past_Last loop
         pragma Loop_Invariant (Static => Offset in First .. Past_Last);
         pragma
           Loop_Invariant
             (Static =>
                Recursive_Is_Valid_Range (S, First, Past_Last)
                = Recursive_Is_Valid_Range (S, Offset, Past_Last));
         pragma Loop_Variant (Decreases => Past_Last - Offset);
         if not Valid_At (S, Offset)
           or else Sequence_Width_At (S, Offset) > Past_Last - Offset
         then
            return False;
         end if;
         Offset := Offset + Sequence_Width_At (S, Offset);
      end loop;
      return True;
   end Is_Valid_Range;

   --------------------
   -- Is_Valid_UTF_8 --
   --------------------

   function Is_Valid_UTF_8 (S : String) return Boolean
   is (Valid_From (S, 0));

   ------------------
   -- Lemma_Append --
   ------------------

   procedure Lemma_Append
     (Prefix : String; Value : Scalar_Value; Result : String)
   is
      procedure Prove_From (Offset : Natural)
      with
        Pre                =>
          Offset <= Prefix'Length
          and then Valid_From (Prefix, Offset)
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
        Post               =>
          Valid_From (Result, Offset)
          and then
            Is_Concatenation
              (Model_From (Prefix, Offset),
               [Value],
               Model_From (Result, Offset)),
        Subprogram_Variant => (Decreases => Prefix'Length - Offset);

      ----------------
      -- Prove_From --
      ----------------

      procedure Prove_From (Offset : Natural) is
      begin
         if Offset = Prefix'Length then
            pragma
              Assert
                (Static =>
                   Valid_At (Result, Offset)
                   and then
                     Sequence_Width_At (Result, Offset)
                     = Natural (Encoding_Width (Value))
                   and then
                     Decode_One (Result, Offset)
                     = (Value => Value, Width => Encoding_Width (Value)));
         else
            pragma
              Assert
                (Static =>
                   Valid_At (Result, Offset)
                   and then
                     Sequence_Width_At (Result, Offset)
                     = Sequence_Width_At (Prefix, Offset)
                   and then
                     Decode_One (Result, Offset)
                     = Decode_One (Prefix, Offset));
            Prove_From (Offset + Sequence_Width_At (Prefix, Offset));
         end if;
      end Prove_From;

   begin
      Prove_From (0);
   end Lemma_Append;

   ------------------------------
   -- Lemma_Extend_Valid_Range --
   ------------------------------

   procedure Lemma_Extend_Valid_Range
     (S : String; First, Old_Past_Last, New_Past_Last : Natural) is
   begin
      if First < Old_Past_Last then
         declare
            Width : constant Natural := Sequence_Width_At (S, First)
            with Ghost => Static;
         begin
            Lemma_Extend_Valid_Range
              (S, First + Width, Old_Past_Last, New_Past_Last);
         end;
      end if;
   end Lemma_Extend_Valid_Range;

   -------------------------------
   -- Lemma_Rebased_Valid_Range --
   -------------------------------

   procedure Lemma_Rebased_Valid_Range
     (Left         : String;
      Left_Offset  : Natural;
      Right        : String;
      Right_Offset : Natural;
      Count        : Natural) is
   begin
      if Count > 0 then
         declare
            Width : constant Natural := Sequence_Width_At (Left, Left_Offset)
            with Ghost => Static;
         begin
            pragma
              Assert
                (Static =>
                   Valid_At (Right, Right_Offset)
                   and then Sequence_Width_At (Right, Right_Offset) = Width
                   and then
                     Decode_One (Left, Left_Offset)
                     = Decode_One (Right, Right_Offset));
            pragma
              Assert
                (Static =>
                   (for all I in Natural range 0 .. Count - Width - 1 =>
                      Octet_At (Left, Left_Offset + (Width + I))
                      = Octet_At (Right, Right_Offset + (Width + I))));
            Lemma_Rebased_Valid_Range
              (Left,
               Left_Offset + Width,
               Right,
               Right_Offset + Width,
               Count - Width);
         end;
      end if;
   end Lemma_Rebased_Valid_Range;

   -----------------
   -- Length_From --
   -----------------

   function Length_From (S : String; Byte_Offset : Natural) return Natural is
      Offset : Natural := Byte_Offset;
      Count  : Natural := 0;
   begin
      while Offset < S'Length loop
         pragma Loop_Invariant (Static => Offset in Byte_Offset .. S'Length);
         pragma Loop_Invariant (Static => Count <= Offset - Byte_Offset);
         pragma Loop_Invariant (Static => Valid_From (S, Offset));
         pragma
           Loop_Invariant
             (Static =>
                Recursive_Length_From (S, Byte_Offset)
                = Count + Recursive_Length_From (S, Offset));
         pragma Loop_Variant (Decreases => S'Length - Offset);
         Offset := Offset + Sequence_Width_At (S, Offset);
         Count := Count + 1;
      end loop;
      return Count;
   end Length_From;

   -----------
   -- Model --
   -----------

   function Model (S : String; Span : Byte_Span) return Text
   is (Range_Model (S, Span.First, Span.Past_Last));

   -----------
   -- Model --
   -----------

   function Model (S : String) return Text is
   begin
      return Model_From (S, 0);
   end Model;

   ----------------
   -- Model_From --
   ----------------

   function Model_From (S : String; Byte_Offset : Natural) return Text
   is (if Byte_Offset = S'Length
       then Scalar_Sequences.Empty_Sequence
       else
         Scalar_Sequences.Add
           (Model_From
              (S, Byte_Offset + Natural (Decode_One (S, Byte_Offset).Width)),
            1,
            Decode_One (S, Byte_Offset).Value));

   ----------
   -- Next --
   ----------

   procedure Next
     (S : String; Cursor : in out Cursor_Type; Value : out Scalar_Value)
   is
      Unit : constant Decoded_Unit := Decode_One (S, Cursor.Offset);
   begin
      Value := Unit.Value;
      Cursor.Offset := Cursor.Offset + Natural (Unit.Width);
      Cursor.Index := Cursor.Index + 1;
   end Next;

   -----------------
   -- Range_Model --
   -----------------

   function Range_Model (S : String; First, Past_Last : Natural) return Text
   is (if First = Past_Last
       then Scalar_Sequences.Empty_Sequence
       else
         Scalar_Sequences.Add
           (Range_Model (S, First + Sequence_Width_At (S, First), Past_Last),
            1,
            Decode_One (S, First).Value));

   ----------------------------
   -- Recursive_Element_From --
   ----------------------------

   function Recursive_Element_From
     (S : String; Byte_Offset : Natural; Index : Positive) return Scalar_Value
   is (if Index = 1
       then Decode_One (S, Byte_Offset).Value
       else
         Recursive_Element_From
           (S, Byte_Offset + Sequence_Width_At (S, Byte_Offset), Index - 1));

   ------------------------------
   -- Recursive_Is_Valid_Range --
   ------------------------------

   function Recursive_Is_Valid_Range
     (S : String; First, Past_Last : Natural) return Boolean
   is (First = Past_Last
       or else
         (Valid_At (S, First)
          and then Sequence_Width_At (S, First) <= Past_Last - First
          and then
            Recursive_Is_Valid_Range
              (S, First + Sequence_Width_At (S, First), Past_Last)));

   ---------------------------
   -- Recursive_Length_From --
   ---------------------------

   function Recursive_Length_From
     (S : String; Byte_Offset : Natural) return Natural
   is (if Byte_Offset = S'Length
       then 0
       else
         1
         + Recursive_Length_From
             (S, Byte_Offset + Sequence_Width_At (S, Byte_Offset)));

   --------------------------
   -- Recursive_Valid_From --
   --------------------------

   function Recursive_Valid_From
     (S : String; Byte_Offset : Natural) return Boolean
   is (Byte_Offset = S'Length
       or else
         (Valid_At (S, Byte_Offset)
          and then
            Recursive_Valid_From
              (S, Byte_Offset + Sequence_Width_At (S, Byte_Offset))));

   ----------------------------------
   -- Recursive_Valid_Range_Length --
   ----------------------------------

   function Recursive_Valid_Range_Length
     (S : String; First, Past_Last : Natural) return Natural
   is (if First = Past_Last
       then 0
       else
         1
         + Recursive_Valid_Range_Length
             (S, First + Sequence_Width_At (S, First), Past_Last));

   -----------
   -- Slice --
   -----------

   function Slice (S : String; Span : Byte_Span) return String is
   begin
      if Span.First = Span.Past_Last then
         return "";
      else
         declare
            First_Index : constant Positive :=
              S'Last - (S'Length - Span.First) + 1;
            Last_Index  : constant Positive :=
              S'Last - (S'Length - Span.Past_Last);
            Result      : String (1 .. Span.Past_Last - Span.First);
         begin
            Result := S (First_Index .. Last_Index);
            pragma
              Assert
                (Static =>
                   (for all I in Natural range 0 .. Result'Length - 1 =>
                      Octet_At (S, Span.First + I) = Octet_At (Result, I)));
            Lemma_Rebased_Valid_Range
              (S, Span.First, Result, 0, Result'Length);
            return Result;
         end;
      end if;
   end Slice;

   -----------
   -- Slice --
   -----------

   function Slice (S : String; First : Positive; Count : Natural) return String
   is (Slice (S, To_Byte_Span (S, First, Count)));

   ------------------
   -- To_Byte_Span --
   ------------------

   function To_Byte_Span
     (S : String; First : Positive; Count : Natural) return Byte_Span
   is
      Start_Cursor : constant Cursor_Type := Cursor_At_Index (S, First);
      End_Cursor   : Cursor_Type := Start_Cursor;
      Value        : Scalar_Value;
   begin
      for Position in 1 .. Count loop
         pragma Loop_Invariant (Static => Is_Valid_Cursor (S, End_Cursor));
         pragma
           Loop_Invariant
             (Byte_Offset (Start_Cursor) <= Byte_Offset (End_Cursor));
         pragma
           Loop_Invariant
             (Static =>
                Is_Valid_Range
                  (S, Byte_Offset (Start_Cursor), Byte_Offset (End_Cursor)));
         pragma
           Loop_Invariant
             (Static =>
                Valid_Range_Length
                  (S, Byte_Offset (Start_Cursor), Byte_Offset (End_Cursor))
                = Position - 1);
         pragma
           Loop_Invariant
             (Static =>
                Is_Slice
                  (Source => Model (S),
                   First  => To_Big_Integer (First),
                   Count  => To_Big_Integer (Position - 1),
                   Result =>
                     Range_Model
                       (S,
                        Byte_Offset (Start_Cursor),
                        Byte_Offset (End_Cursor))));
         pragma
           Loop_Invariant
             (Static =>
                Cursor_Index_Conversions.To_Big_Integer
                  (Scalar_Index (End_Cursor))
                = To_Big_Integer (First) + To_Big_Integer (Position) - 1);
         declare
            Old_End : constant Natural := Byte_Offset (End_Cursor)
            with Ghost => Static;
         begin
            pragma Assert (Static => Valid_At (S, Old_End));
            Next (S, End_Cursor, Value);
            pragma Assert (Value in Scalar_Value);
            Lemma_Extend_Valid_Range
              (S,
               Byte_Offset (Start_Cursor),
               Old_End,
               Byte_Offset (End_Cursor));
         end;
      end loop;

      return
        (First     => Byte_Offset (Start_Cursor),
         Past_Last => Byte_Offset (End_Cursor));
   end To_Byte_Span;

   ----------------
   -- Valid_From --
   ----------------

   function Valid_From (S : String; Byte_Offset : Natural) return Boolean is
      Offset : Natural := Byte_Offset;
   begin
      while Offset < S'Length loop
         pragma Loop_Invariant (Static => Offset in Byte_Offset .. S'Length);
         pragma
           Loop_Invariant
             (Static =>
                Recursive_Valid_From (S, Byte_Offset)
                = Recursive_Valid_From (S, Offset));
         pragma Loop_Variant (Decreases => S'Length - Offset);
         if not Valid_At (S, Offset) then
            return False;
         end if;
         Offset := Offset + Sequence_Width_At (S, Offset);
      end loop;
      return True;
   end Valid_From;

   ------------------------
   -- Valid_Range_Length --
   ------------------------

   function Valid_Range_Length
     (S : String; First, Past_Last : Natural) return Natural
   is
      Offset : Natural := First;
      Count  : Natural := 0;
   begin
      while Offset < Past_Last loop
         pragma Loop_Invariant (Static => Offset in First .. Past_Last);
         pragma Loop_Invariant (Static => Count <= Offset - First);
         pragma
           Loop_Invariant (Static => Is_Valid_Range (S, Offset, Past_Last));
         pragma
           Loop_Invariant
             (Static =>
                Recursive_Valid_Range_Length (S, First, Past_Last)
                = Count + Recursive_Valid_Range_Length (S, Offset, Past_Last));
         pragma Loop_Variant (Decreases => Past_Last - Offset);
         Offset := Offset + Sequence_Width_At (S, Offset);
         Count := Count + 1;
      end loop;
      return Count;
   end Valid_Range_Length;

   --------------
   -- Validate --
   --------------

   function Validate (S : String) return Validation_Result is
      Offset : Natural := 0;
   begin
      while Offset < S'Length loop
         pragma Loop_Invariant (Offset <= S'Length);
         pragma Loop_Invariant (Static => Is_Valid_Range (S, 0, Offset));
         pragma
           Loop_Invariant
             (Static => Valid_From (S, 0) = Valid_From (S, Offset));
         pragma Loop_Variant (Decreases => S'Length - Offset);
         exit when not Valid_At (S, Offset);
         declare
            Width : constant Natural := Sequence_Width_At (S, Offset);
         begin
            Lemma_Extend_Valid_Range (S, 0, Offset, Offset + Width);
            Offset := Offset + Width;
         end;
      end loop;
      Lemma_Rebased_Valid_Range
        (S, 0, S (S'First .. S'Last - (S'Length - Offset)), 0, Offset);
      return (Valid => Offset = S'Length, Error_Offset => Offset);
   end Validate;
end SPARK.Strings.Unicode.UTF_8;
