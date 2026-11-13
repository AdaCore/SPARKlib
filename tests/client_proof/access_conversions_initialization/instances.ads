with Interfaces;
with SPARK.Conversions.Access_Conversions;

package Instances with SPARK_Mode is
   subtype Word is Interfaces.Unsigned_32;
   type Positive_Word is range 1 .. 2 ** 31 - 1 with Size => 32;
   type Relaxed is record
      Value : Word;
   end record with Relaxed_Initialization, Size => 32, Alignment => 4;
   for Relaxed use record
      Value at 0 range 0 .. 31;
   end record;

   function Is_Initialized (X : Relaxed) return Boolean
   is (X'Initialized)
   with Ghost => Static;

   package Constant_Checked is new
     SPARK.Conversions.Access_Conversions.Access_Constant_Conversions
       (Relaxed, Word, Is_Initialized);
   package Variable_Checked is new
     SPARK.Conversions.Access_Conversions.Access_Variable_Conversions
       (Relaxed, Word, Is_Initialized);
   package Constant_Invalid_Checked is new
     SPARK.Conversions.Access_Conversions
       .Access_Constant_Conversions_Potentially_Invalid
         (Relaxed, Positive_Word, Is_Initialized);
   package Variable_Invalid_Checked is new
     SPARK.Conversions.Access_Conversions
       .Access_Variable_Conversions_Potentially_Invalid
         (Relaxed, Positive_Word, Is_Initialized);

   --  The default predicate does not guarantee initialization of relaxed data.

   package Constant_Bad is new
     SPARK.Conversions.Access_Conversions.Access_Constant_Conversions
       (Relaxed, Word);
   package Variable_Bad is new
     SPARK.Conversions.Access_Conversions.Access_Variable_Conversions
       (Relaxed, Word);
   package Reverse_Bad is new
     SPARK.Conversions.Access_Conversions.Access_Variable_Conversions
       (Word, Relaxed);
   package Constant_Invalid_Bad is new
     SPARK.Conversions.Access_Conversions
       .Access_Constant_Conversions_Potentially_Invalid (Relaxed, Positive_Word);
   package Variable_Invalid_Bad is new
     SPARK.Conversions.Access_Conversions
       .Access_Variable_Conversions_Potentially_Invalid (Relaxed, Positive_Word);
end Instances;
