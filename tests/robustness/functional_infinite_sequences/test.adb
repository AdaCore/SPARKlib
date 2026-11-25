pragma Check_Policy (SPARKlib_Defensive => Disable);

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with SPARK.Big_Integers; use SPARK.Big_Integers;
with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Containers.Functional.Infinite_Sequences;

procedure Test is
   Last_Label    : Unbounded_String := Null_Unbounded_String;
   First_Failure : Unbounded_String := Null_Unbounded_String;
   Failure_Count : Natural := 0;

   procedure Set_Label (Label : String) is
   begin
      Last_Label := To_Unbounded_String (Label);
   end Set_Label;

   procedure Record_Failure is
   begin
      Failure_Count := Failure_Count + 1;
      if Failure_Count = 1 then
         First_Failure := Last_Label;
      end if;
   end Record_Failure;

   procedure Check_Results is
   begin
      if Failure_Count /= 0 then
         raise Program_Error with
           Natural'Image (Failure_Count)
           & " defensive checks failed; first: "
           & To_String (First_Failure);
      end if;
   end Check_Results;

   package Int_Sequences is new
     SPARK.Containers.Functional.Infinite_Sequences (Integer);
   use Int_Sequences;

   procedure Test_Get is
      package Count_Conversions is new Signed_Conversions (Int => Count_Type);
      Too_Large : constant Big_Integer :=
        Count_Conversions.To_Big_Integer (Count_Type'Last) + 1;
      X : Sequence;
      Value : Integer;
   begin
      Set_Label ("Get with oversized index: ");
      begin
         Value := Get (X, Too_Large);
      exception
         when Program_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Get;

begin
   Test_Get;
   Check_Results;
end Test;
