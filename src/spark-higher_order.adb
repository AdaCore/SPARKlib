--
--  Copyright (C) 2018-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package body SPARK.Higher_Order with SPARK_Mode is

   ---------
   -- Map --
   ---------

   function Map (A : Array_In) return Array_Out is
      pragma Annotate
        (GNATprove, False_Positive,
         """R"" might not be initialized", "Array initialized in loop");
   begin
      return R : Array_Out (A'Range) do
         for I in A'Range loop
            R (I) := F (A (I));
            pragma Loop_Invariant (for all K in A'First .. I =>
                                     R (K) = F (A (K)));
         end loop;
      end return;
   end Map;

   -----------
   -- Map_I --
   -----------

   function Map_I (A : Array_In) return Array_Out is
      pragma Annotate
        (GNATprove, False_Positive,
         """R"" might not be initialized", "Array initialized in loop");
   begin
      return R : Array_Out (A'Range) do
         for I in A'Range loop
            R (I) := F (I, A (I));
            pragma Loop_Invariant (for all K in A'First .. I =>
                                     R (K) = F (K, A (K)));
         end loop;
      end return;
   end Map_I;

   ----------------
   -- Map_I_Proc --
   ----------------

   procedure Map_I_Proc (A : in out Array_Type) is
   begin
      for I in A'Range loop
         A (I) := F (I, A (I));
         pragma Loop_Invariant (for all K in A'First .. I =>
                                  A (K) = F (K, A'Loop_Entry (K)));
      end loop;
   end Map_I_Proc;

   --------------
   -- Map_Proc --
   --------------

   procedure Map_Proc (A : in out Array_Type) is
   begin
      for I in A'Range loop
         A (I) := F (A (I));
         pragma Loop_Invariant (for all K in A'First .. I =>
                                  A (K) = F (A'Loop_Entry (K)));
      end loop;
   end Map_Proc;

end SPARK.Higher_Order;
