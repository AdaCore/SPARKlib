with SPARK.Big_Integers;           use SPARK.Big_Integers;
with SPARK.Strings.Unicode.Models; use SPARK.Strings.Unicode.Models;

package body Clients
  with SPARK_Mode
is
   use type Scalar_Sequences.Sequence;

   ------------
   -- Append --
   ------------

   procedure Append (Prefix : String; Value : Scalar_Value) is
      Empty   : constant String (7 .. 6) := "";
      Rebased : constant String (1 .. Prefix'Length) := Prefix;
      Encoded : constant String := Encode_One (Value);
      Result  : constant String (7 .. 6 + Prefix'Length + Encoded'Length) :=
        Rebased & Encoded;
   begin
      pragma Assert (Is_Valid_UTF_8 (Empty));
      Lemma_Append (Empty, Value, Encoded);
      pragma
        Assert (Is_Concatenation (Model (Empty), [Value], Model (Encoded)));
      Lemma_Append (Prefix, Value, Result);
      pragma Assert (Is_Valid_UTF_8 (Result));
      pragma
        Assert (Is_Concatenation (Model (Prefix), [Value], Model (Result)));
   end Append;

   ----------------
   -- Round_Trip --
   ----------------

   procedure Round_Trip (Value : Scalar_Value) is
      S : constant String := Encode_One (Value);
      U : constant Decoded_Unit := Decode_One (S, 0);
   begin
      pragma Assert (Is_Valid_UTF_8 (S));
      pragma Assert (U.Value = Value);
      pragma Assert (Natural (U.Width) = S'Length);
      pragma Assert (Model (S) = [Value]);
   end Round_Trip;

   ------------------------
   -- Count_By_Traversal --
   ------------------------

   function Count_By_Traversal (S : String) return Natural is
      Length : constant Natural := Code_Point_Length (S);
      C      : Cursor_Type := First (S);
      Count  : Natural := 0;
      V      : Scalar_Value;
   begin
      while Has_Element (S, C) loop
         pragma Loop_Invariant (Static => Is_Valid_Cursor (S, C));
         pragma Loop_Invariant (Count <= Length);
         pragma
           Loop_Invariant
             (Static => Big_Scalar_Index (C) = To_Big_Integer (Count) + 1);
         pragma Loop_Variant (Decreases => Length - Count);
         Next (S, C, V);
         Count := Count + 1;
         pragma
           Assert
             (Static =>
                V = Scalar_Sequences.Get (Model (S), To_Big_Integer (Count)));
      end loop;
      return Count;
   end Count_By_Traversal;

   -------------
   -- Extract --
   -------------

   procedure Extract (S : String; Start : Positive; Count : Natural) is
      Span : constant Byte_Span := To_Byte_Span (S, Start, Count);
      Part : constant String := Slice (S, Span);
   begin
      pragma Assert (Part'First = 1);
      pragma Assert (Is_Valid_UTF_8 (Part));
      pragma Assert (Code_Point_Length (Part) = Count);
      pragma
        Assert
          (Static =>
             Is_Slice
               (Model (S),
                To_Big_Integer (Start),
                To_Big_Integer (Count),
                Model (Part)));
   end Extract;
   ------------------------
   -- Valid_Prefix_Bytes --
   ------------------------

   function Valid_Prefix_Bytes (S : String) return Natural is
      Result : constant Validation_Result := Validate (S);
   begin
      return Result.Error_Offset;
   end Valid_Prefix_Bytes;
end Clients;
