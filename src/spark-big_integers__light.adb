--
--  Copyright (C) 2022-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This body is provided as a work-around for a GNAT compiler bug, as GNAT
--  currently does not compile instantiations of the spec with imported ghost
--  generics for packages Signed_Conversions and Unsigned_Conversions.

package body SPARK.Big_Integers with
   SPARK_Mode => Off
is

   package body Signed_Conversions with
     SPARK_Mode => Off
   is

      function From_Big_Integer (Arg : Valid_Big_Integer) return Int is
      begin
         raise Program_Error;
         return 0;
      end From_Big_Integer;

      function To_Big_Integer (Arg : Int) return Valid_Big_Integer is
      begin
         raise Program_Error;
         return (null record);
      end To_Big_Integer;

   end Signed_Conversions;

   package body Unsigned_Conversions with
     SPARK_Mode => Off
   is

      function From_Big_Integer (Arg : Valid_Big_Integer) return Int is
      begin
         raise Program_Error;
         return 0;
      end From_Big_Integer;

      function To_Big_Integer (Arg : Int) return Valid_Big_Integer is
      begin
         raise Program_Error;
         return (null record);
      end To_Big_Integer;

   end Unsigned_Conversions;

end SPARK.Big_Integers;
