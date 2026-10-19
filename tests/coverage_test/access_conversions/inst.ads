with SPARK.Conversions.Access_Conversions;

--  Instances of the four access-conversion generics, exercised at run time by
--  Test and proved by no_crash on this unit.
--
--  All types are records of discrete components with the same representation,
--  so GNATprove handles the forced Unchecked_Conversion of each generic
--  precisely (run gnatprove with --info to confirm no imprecise handling).
--
--  The non-potentially-invalid flavours use records whose every bit pattern is
--  a valid value. The potentially-invalid flavours target a record of Code, an
--  enumeration stored on 8 bits: only the byte values 0 .. 3 denote a valid
--  Code, which keeps their 'Valid_Scalars contracts non-vacuous.

package Inst with SPARK_Mode is

   type Byte is mod 2**8 with Size => 8;
   type Code is (C0, C1, C2, C3) with Size => 8;

   --  Explicit representation clauses pin the component offsets, so GNATprove
   --  handles the Unchecked_Conversions precisely rather than treating the
   --  layout as unknown.

   type Src_Valid is record
      A : Short_Integer;
      B : Short_Integer;
   end record;
   for Src_Valid use record
      A at 0 range 0 .. 15;
      B at 2 range 0 .. 15;
   end record;

   type Tgt_Valid is record
      X : Short_Integer;
      Y : Short_Integer;
   end record;
   for Tgt_Valid use record
      X at 0 range 0 .. 15;
      Y at 2 range 0 .. 15;
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
       (Source_Type => Src_Valid, Target_Type => Tgt_Valid);

   package Variable_Conversions is new
     SPARK.Conversions.Access_Conversions.Access_Variable_Conversions
       (Source_Type => Src_Valid, Target_Type => Tgt_Valid);

   package Constant_Conversions_PI is new
     SPARK.Conversions.Access_Conversions
       .Access_Constant_Conversions_Potentially_Invalid
       (Source_Type => Src_PI, Target_Type => Tgt_PI);

   package Variable_Conversions_PI is new
     SPARK.Conversions.Access_Conversions
       .Access_Variable_Conversions_Potentially_Invalid
       (Source_Type => Src_PI, Target_Type => Tgt_PI);

end Inst;
