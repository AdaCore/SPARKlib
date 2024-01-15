--
--  Copyright (C) 2016-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package SPARK.Tests.Array_Lemmas
  with SPARK_Mode
is
   pragma Warnings
     (Off, "postcondition does not check the outcome of calling");

   type Index_Type is range 1 .. 10;
   type Arr_Int_Constrained is array (Index_Type) of Integer;
   type Arr_Float_Constrained is array (Index_Type) of Float;

   procedure Test_Transitive_Order_Int (Arr : Arr_Int_Constrained) with
     Global => null,
     Pre =>
       (for all I in Index_Type'First + 1 .. Index_Type'Last =>
          (Arr (I - 1) < Arr (I))),
     Post => (for all I in Arr'Range =>
                (for all J in Arr'Range =>
                     (if I < J then Arr (I) < Arr (J))));

   procedure Test_Transitive_Order_Float (Arr : Arr_Float_Constrained) with
     Global => null,
     Pre =>
       (for all I in Index_Type'First + 1 .. Index_Type'Last =>
          (Arr (I - 1) < Arr (I))),
     Post => (for all I in Arr'Range =>
                (for all J in Arr'Range =>
                     (if I < J then Arr (I) < Arr (J))));

   type Arr_Int_Unconstrained is array (Integer range <>) of Integer;
   type Arr_Float_Unconstrained is array (Integer range <>) of Float;

   procedure Test_Transitive_Order_Int (Arr : Arr_Int_Unconstrained) with
     Global => null,
     Pre =>
       (for all I in Arr'First .. Arr'Last =>
          (if I > Arr'First then Arr (I - 1) < Arr (I))),
     Post => (for all I in Arr'Range =>
                (for all J in Arr'Range =>
                     (if I < J then Arr (I) < Arr (J))));

   procedure Test_Transitive_Order_Float (Arr : Arr_Float_Unconstrained) with
     Global => null,
     Pre =>
       (for all I in Arr'First .. Arr'Last =>
          (if I > Arr'First then Arr (I - 1) < Arr (I))),
     Post => (for all I in Arr'Range =>
                (for all J in Arr'Range =>
                     (if I < J then Arr (I) < Arr (J))));

end SPARK.Tests.Array_Lemmas;
