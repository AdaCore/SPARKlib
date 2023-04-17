--
--  Copyright (C) 2022-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package body SPARK.Cut_Operations with SPARK_Mode => Off is

   function By (Consequence, Premise : Boolean) return Boolean is
     (Premise and then Consequence);

   function So (Premise, Consequence : Boolean) return Boolean is
     (Premise and then Consequence);

end SPARK.Cut_Operations;
