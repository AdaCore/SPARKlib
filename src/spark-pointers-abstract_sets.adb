--
--  Copyright (C) 2023-2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package body SPARK.Pointers.Abstract_Sets
  with SPARK_Mode => Off
is

   function Elements
     (Choose : not null access function (E : Element_Type) return Boolean)
      return Set
   is ((null record));

   procedure All_Elements_Chosen
     (Choose : not null access function (E : Element_Type) return Boolean;
      E      : Element_Type)
   is null;

end SPARK.Pointers.Abstract_Sets;
