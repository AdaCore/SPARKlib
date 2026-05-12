--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package body SPARK.Conversions.Access_Conversions
  with SPARK_Mode
is

   ---------------------------------
   -- Access_Constant_Conversions --
   ---------------------------------

   package body Access_Constant_Conversions
     with SPARK_Mode => Off
   is

      -----------------------------
      -- Convert_Constant_Access --
      -----------------------------

      function Convert_Constant_Access
        (Source : not null access constant Source_Type)
         return not null access constant Target_Type
      is
         type Source_Access is access constant Source_Type;
         type Target_Access is access constant Target_Type;
         function Conv is new
           Ada.Unchecked_Conversion (Source_Access, Target_Access);
      begin
         return Conv (Source_Access (Source)).all'Unchecked_Access;
      end Convert_Constant_Access;

      --------------------------
      -- Target_Logical_Equal --
      --------------------------

      function Target_Logical_Equal (X, Y : Target_Type) return Boolean
      is (X = Y);

   end Access_Constant_Conversions;

   -----------------------------------------------------
   -- Access_Constant_Conversions_Potentially_Invalid --
   -----------------------------------------------------

   package body Access_Constant_Conversions_Potentially_Invalid
     with SPARK_Mode => Off
   is

      -----------------------------
      -- Convert_Constant_Access --
      -----------------------------

      function Convert_Constant_Access
        (Source : not null access constant Source_Type)
         return not null access constant Target_Type
      is
         type Source_Access is access constant Source_Type;
         type Target_Access is access constant Target_Type;
         function Conv is new
           Ada.Unchecked_Conversion (Source_Access, Target_Access);
      begin
         return Conv (Source_Access (Source)).all'Unchecked_Access;
      end Convert_Constant_Access;

      --------------------------
      -- Target_Logical_Equal --
      --------------------------

      function Target_Logical_Equal (X, Y : Target_Type) return Boolean
      is (X = Y);

   end Access_Constant_Conversions_Potentially_Invalid;

   ---------------------------------
   -- Access_Variable_Conversions --
   ---------------------------------

   package body Access_Variable_Conversions
     with SPARK_Mode => Off
   is

      --------------------
      -- Convert_Access --
      --------------------

      function Convert_Access
        (Source : not null access Source_Type)
         return not null access Target_Type
      is
         type Source_Access is access all Source_Type;
         type Target_Access is access all Target_Type;
         function Conv is new
           Ada.Unchecked_Conversion (Source_Access, Target_Access);
      begin
         return Conv (Source_Access (Source)).all'Unchecked_Access;
      end Convert_Access;

      -----------------------------
      -- Convert_Constant_Access --
      -----------------------------

      function Convert_Constant_Access
        (Source : not null access constant Source_Type)
         return not null access constant Target_Type
      is
         type Source_Access is access constant Source_Type;
         type Target_Access is access constant Target_Type;
         function Conv is new
           Ada.Unchecked_Conversion (Source_Access, Target_Access);
      begin
         return Conv (Source_Access (Source)).all'Unchecked_Access;
      end Convert_Constant_Access;

      --------------------------
      -- Target_Logical_Equal --
      --------------------------

      function Target_Logical_Equal (X, Y : Target_Type) return Boolean
      is (X = Y);

   end Access_Variable_Conversions;

   -----------------------------------------------------
   -- Access_Variable_Conversions_Potentially_Invalid --
   -----------------------------------------------------

   package body Access_Variable_Conversions_Potentially_Invalid
     with SPARK_Mode => Off
   is

      --------------------
      -- Convert_Access --
      --------------------

      function Convert_Access
        (Source : not null access Source_Type)
         return not null access Target_Type
      is
         type Source_Access is access all Source_Type;
         type Target_Access is access all Target_Type;
         function Conv is new
           Ada.Unchecked_Conversion (Source_Access, Target_Access);
      begin
         return Conv (Source_Access (Source)).all'Unchecked_Access;
      end Convert_Access;

      -----------------------------
      -- Convert_Constant_Access --
      -----------------------------

      function Convert_Constant_Access
        (Source : not null access constant Source_Type)
         return not null access constant Target_Type
      is
         type Source_Access is access constant Source_Type;
         type Target_Access is access constant Target_Type;
         function Conv is new
           Ada.Unchecked_Conversion (Source_Access, Target_Access);
      begin
         return Conv (Source_Access (Source)).all'Unchecked_Access;
      end Convert_Constant_Access;

      --------------------------
      -- Target_Logical_Equal --
      --------------------------

      function Target_Logical_Equal (X, Y : Target_Type) return Boolean
      is (X = Y);

   end Access_Variable_Conversions_Potentially_Invalid;

end SPARK.Conversions.Access_Conversions;
