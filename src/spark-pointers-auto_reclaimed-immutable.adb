--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Ada.Unchecked_Conversion;
with Ada.Unchecked_Deallocation;

package body SPARK.Pointers.Auto_Reclaimed.Immutable
  with SPARK_Mode => Off
is

   procedure Free is new Ada.Unchecked_Deallocation (Object, Object_Access);

   ------------------------
   -- Constant_Reference --
   ------------------------

   function Constant_Reference
     (P : Pointer) return not null access constant Object
   is (P.Data.Shared_Data.Data);

   ---------------------
   -- Copy_Operations --
   ---------------------

   package body Copy_Operations
     with SPARK_Mode => Off
   is

      -----------------
      -- Create_Copy --
      -----------------

      function Create_Copy (O : Object) return Pointer
      is (Data =>
            (Shared_Data =>
               new Single_Count_And_Data'
                 (Count => 1, Data => new Object'(Copy (O))),
             Extra_Data  => (null record)));

      -----------
      -- Deref --
      -----------

      function Deref (P : Pointer) return Object
      is (Copy (P.Data.Shared_Data.Data.all));

   end Copy_Operations;

   ------------
   -- Create --
   ------------

   function Create (X : Input) return Pointer with SPARK_Mode => Off is
   begin
      return
        (Data =>
           (Shared_Data =>
              new Single_Count_And_Data'
                (Count => 1, Data => new Object'(Create_Object (X))),
            Extra_Data  => (null record)));
   end Create;

   -----------------------
   -- Handle_Operations --
   -----------------------

   package body Handle_Operations
     with SPARK_Mode => Off
   is

      ---------------
      -- Of_Handle --
      ---------------

      function Of_Handle (H : Handle) return Pointer is
         type Handle_Access is access constant Handle;
         type Pointer_Access is access constant Pointer;
         function From_Handle is new
           Ada.Unchecked_Conversion (Handle_Access, Pointer_Access);

         Local : aliased constant Handle := H;
      begin
         return From_Handle (Local'Access).all;
      end Of_Handle;

      -------------
      -- Reclaim --
      -------------

      procedure Reclaim (X : in out Data_Placeholder_Access) is
         Y : Object_Access
         with Import, Address => X'Address;
      begin
         Reclaim (Y, (null record));
      end Reclaim;

      ---------------
      -- To_Handle --
      ---------------

      function To_Handle (P : Pointer) return Handle is
         type Handle_Access is access all Handle;
         type Pointer_Access is access all Pointer;
         function From_Handle is new
           Ada.Unchecked_Conversion (Handle_Access, Pointer_Access);

         H : aliased Handle := Null_Handle (Reclamation_Access);
         Q : constant Pointer_Access := From_Handle (H'Access);
      begin
         Q.all := P;
         return H;
      end To_Handle;

      ------------------
      -- Valid_Handle --
      ------------------

      function Valid_Handle (H : Handle) return Boolean
      is (Check_Reclamation (H, Reclamation_Access));

   end Handle_Operations;

   -------------
   -- Reclaim --
   -------------

   procedure Reclaim (D : in out Object_Access; P : No_Extra_Data) is
      pragma Unreferenced (P);
   begin
      if D /= null then
         Reclaim (D.all);
         Free (D);
      end if;
   end Reclaim;

end SPARK.Pointers.Auto_Reclaimed.Immutable;
