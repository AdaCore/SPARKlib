--
--  Copyright (C) 2022-2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package SPARK.Lemmas
  with SPARK_Mode, Pure
is

   --  Constants for floating point arithmetic lemmas

   Float_Max_Int : constant := 2**24;
   Float_Epsilon : constant := 2.0**(-24);
   Float_Eta     : constant := 2.0**(-150);

   Long_Float_Max_Int : constant := 2**53;
   Long_Float_Epsilon : constant := 2.0**(-53);
   --  The declaration of Eta produces a spurious warning on aarch64. The
   --  number is indeed not representable as a floating-point value, but we
   --  only use it as a Big_Real.
   --  See eng/spark/spark2014#966
   pragma Warnings (Off, "floating-point value underflows to 0.0");
   Long_Float_Eta     : constant := 2.0**(-1075);
   pragma Warnings (On, "floating-point value underflows to 0.0");
end SPARK.Lemmas;
