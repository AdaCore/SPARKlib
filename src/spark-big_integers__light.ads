--
--  Copyright (C) 2022-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This unit is provided as a replacement for the standard unit
--  Ada.Numerics.Big_Numbers.Big_Integers when only proof with SPARK is
--  intended. It cannot be used for execution, as all subprograms are marked
--  imported with no definition.

--  Contrary to Ada.Numerics.Big_Numbers.Big_Integers, this unit does not
--  depend on System or Ada.Finalization, which makes it more convenient for
--  use in run-time units.

package SPARK.Big_Integers with
   SPARK_Mode,
   Ghost,
   Pure,
   Always_Terminates
is

   type Big_Integer is private
     with Integer_Literal => From_Universal_Image;

   function Is_Valid (Arg : Big_Integer) return Boolean
   with
     Global => null;

   subtype Valid_Big_Integer is Big_Integer
     with Dynamic_Predicate => Is_Valid (Valid_Big_Integer),
          Predicate_Failure => raise Program_Error;

   function "=" (L, R : Valid_Big_Integer) return Boolean with
      Global => null;

   function "<" (L, R : Valid_Big_Integer) return Boolean with
      Global => null;

   function "<=" (L, R : Valid_Big_Integer) return Boolean with
      Global => null;

   function ">" (L, R : Valid_Big_Integer) return Boolean with
      Global => null;

   function ">=" (L, R : Valid_Big_Integer) return Boolean with
      Global => null;

   function To_Big_Integer (Arg : Integer) return Valid_Big_Integer
     with
       Global => null;

   subtype Big_Positive is Big_Integer
     with Dynamic_Predicate =>
            (if Is_Valid (Big_Positive)
             then Big_Positive > To_Big_Integer (0)),
          Predicate_Failure => raise Constraint_Error;

   subtype Big_Natural is Big_Integer
     with Dynamic_Predicate =>
            (if Is_Valid (Big_Natural)
             then Big_Natural >= To_Big_Integer (0)),
          Predicate_Failure => raise Constraint_Error;

   function In_Range
     (Arg : Valid_Big_Integer; Low, High : Big_Integer) return Boolean
   is (Low <= Arg and Arg <= High)
   with
     Global => null;

   function To_Integer (Arg : Valid_Big_Integer) return Integer
   with
     Pre    => In_Range (Arg,
                         Low  => To_Big_Integer (Integer'First),
                         High => To_Big_Integer (Integer'Last))
                or else raise Constraint_Error,
     Global => null;

   generic
      type Int is range <>;
   package Signed_Conversions is

      function To_Big_Integer (Arg : Int) return Valid_Big_Integer
      with
        Global => null;

      function From_Big_Integer (Arg : Valid_Big_Integer) return Int
      with
        Pre    => In_Range (Arg,
                            Low  => To_Big_Integer (Int'First),
                            High => To_Big_Integer (Int'Last))
                   or else raise Constraint_Error,
        Global => null;
   end Signed_Conversions;

   generic
      type Int is mod <>;
   package Unsigned_Conversions is

      function To_Big_Integer (Arg : Int) return Valid_Big_Integer
      with
        Global => null;

      function From_Big_Integer (Arg : Valid_Big_Integer) return Int
      with
        Pre    => In_Range (Arg,
                            Low  => To_Big_Integer (Int'First),
                            High => To_Big_Integer (Int'Last))
                   or else raise Constraint_Error,
        Global => null;

   end Unsigned_Conversions;

   function From_String (Arg : String) return Valid_Big_Integer
   with
     Global => null;

   function From_Universal_Image (Arg : String) return Valid_Big_Integer
     renames From_String;

   function "+" (L : Valid_Big_Integer) return Valid_Big_Integer
   with
     Global => null;

   function "-" (L : Valid_Big_Integer) return Valid_Big_Integer
   with
     Global => null;

   function "abs" (L : Valid_Big_Integer) return Valid_Big_Integer
   with
     Global => null;

   function "+" (L, R : Valid_Big_Integer) return Valid_Big_Integer
   with
     Global => null;

   function "-" (L, R : Valid_Big_Integer) return Valid_Big_Integer
   with
     Global => null;

   function "*" (L, R : Valid_Big_Integer) return Valid_Big_Integer
   with
     Global => null;

   function "/" (L, R : Valid_Big_Integer) return Valid_Big_Integer
   with
     Global => null;

   function "mod" (L, R : Valid_Big_Integer) return Valid_Big_Integer
   with
     Global => null;

   function "rem" (L, R : Valid_Big_Integer) return Valid_Big_Integer
   with
     Global => null;

   function "**" (L : Valid_Big_Integer; R : Natural) return Valid_Big_Integer
   with
     Global => null;

   function Min (L, R : Valid_Big_Integer) return Valid_Big_Integer
   with
     Global => null;

   function Max (L, R : Valid_Big_Integer) return Valid_Big_Integer
   with
     Global => null;

   function Greatest_Common_Divisor
     (L, R : Valid_Big_Integer) return Big_Positive
   with
     Pre    => (L /= To_Big_Integer (0) and R /= To_Big_Integer (0))
               or else raise Constraint_Error,
     Global => null;

private
   pragma SPARK_Mode (Off);

   type Big_Integer is record
      V : Long_Long_Long_Integer;
   end record;

end SPARK.Big_Integers;
