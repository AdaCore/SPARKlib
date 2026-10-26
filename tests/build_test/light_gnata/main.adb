with Ada.Text_IO;
with SPARK.Conversions.Access_Conversions;
with SPARK.Lemmas.Float_Arithmetic;
with SPARK.Lemmas.Integer_Arithmetic;
with SPARK.Lemmas.Mod32_Arithmetic;
with Containers_Inst; use Containers_Inst;
with Pointers_Inst;

procedure Main with SPARK_Mode is

   --  Instances of the access-conversion generics. All types are records of
   --  discrete components with the same representation, so the forced
   --  Unchecked_Conversions are handled precisely. The potentially-invalid
   --  flavours target a record of Code, an enumeration stored on 8 bits, so
   --  their 'Valid_Scalars contracts are non-vacuous (only bytes 0 .. 3 denote
   --  a valid Code).

   type Byte is mod 2**8 with Size => 8;
   type Code is (C0, C1, C2, C3) with Size => 8;

   type Src_Valid is record
      A : Integer;
      B : Integer;
   end record;
   for Src_Valid use record
      A at 0 range 0 .. 31;
      B at 4 range 0 .. 31;
   end record;

   type Tgt_Valid is record
      X : Integer;
      Y : Integer;
   end record;
   for Tgt_Valid use record
      X at 0 range 0 .. 31;
      Y at 4 range 0 .. 31;
   end record;

   type Src_PI is record
      A : Byte;
      B : Byte;
   end record;
   for Src_PI use record
      A at 0 range 0 .. 7;
      B at 1 range 0 .. 7;
   end record;

   type Tgt_PI is record
      X : Code;
      Y : Code;
   end record;
   for Tgt_PI use record
      X at 0 range 0 .. 7;
      Y at 1 range 0 .. 7;
   end record;

   package Constant_Conversions is new
     SPARK.Conversions.Access_Conversions.Access_Constant_Conversions
       (Src_Valid, Tgt_Valid);
   package Variable_Conversions is new
     SPARK.Conversions.Access_Conversions.Access_Variable_Conversions
       (Src_Valid, Tgt_Valid);
   package Constant_Conversions_PI is new
     SPARK.Conversions.Access_Conversions
       .Access_Constant_Conversions_Potentially_Invalid
       (Src_PI, Tgt_PI);
   package Variable_Conversions_PI is new
     SPARK.Conversions.Access_Conversions
       .Access_Variable_Conversions_Potentially_Invalid
       (Src_PI, Tgt_PI);

   --  Test whether SPARKlib_Defensive is enabled

   procedure Test_Defensive with Global => null;

   procedure Test_Defensive with SPARK_Mode => Off is
     L : Lists.List (10);
     E : Integer;
   begin
     Ada.Text_IO.Put_Line ("Assert_Failure should be raised if SPARKlib_Defensive is enabled and Constraint_Error should be raised otherwise");
     E := Lists.First_Element (L);
   end;
begin
   Test_Defensive;
end Main;
