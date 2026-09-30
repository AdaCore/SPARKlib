--
--  Copyright (C) 2022-2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Ada.Unchecked_Conversion;
with Ada.Unchecked_Deallocation;

package body SPARK.Pointers.Explicit_Reclamation.Global_Memory
  with SPARK_Mode => Off
is
   use Definitions;

   -----------------
   -- Definitions --
   -----------------

   package body Definitions is

      procedure Dealloc_Obj is new
        Ada.Unchecked_Deallocation (Object, Object_Access);

      ----------------
      -- Deallocate --
      ----------------

      procedure Deallocate (P : in out Pointer) is
      begin
         Dealloc_Obj (P.P);
         P := Null_Pointer;
      end Deallocate;

   end Definitions;

   -----------------------
   -- Handle_Operations --
   -----------------------

   package body Handle_Operations is

      function Pointer_To_Handle is new
        Ada.Unchecked_Conversion (Pointer, Handle);
      function Handle_To_Pointer is new
        Ada.Unchecked_Conversion (Handle, Pointer);

      ---------
      -- "=" --
      ---------

      function "=" (X, Y : Handle) return Boolean
      is (Handle_To_Pointer (X) = Handle_To_Pointer (Y));

      -----------------
      -- Null_Handle --
      -----------------

      function Null_Handle return Handle
      is (To_Handle (Null_Pointer));

      ---------------
      -- Of_Handle --
      ---------------

      function Of_Handle (H : Handle) return Pointer
      is (Handle_To_Pointer (H));

      ---------------
      -- To_Handle --
      ---------------

      function To_Handle (P : Pointer) return Handle
      is (Pointer_To_Handle (P));

   end Handle_Operations;

   ------------------------
   -- Constant_Reference --
   ------------------------

   function Constant_Reference
     (Memory : Memory_Type; P : Pointer) return not null access constant Object
   is (To_Access (P));

   ---------------------
   -- Copy_Operations --
   ---------------------

   package body Copy_Operations
     with SPARK_Mode => Off
   is

      ------------
      -- Assign --
      ------------

      procedure Assign (P : Pointer; O : Object) is
      begin
         To_Access (P).all := Copy (O);
      end Assign;

      -----------------
      -- Create_Copy --
      -----------------

      procedure Create_Copy (O : Object; P : out Pointer) is
      begin
         P := Allocate (Copy (O));
      end Create_Copy;

      -----------
      -- Deref --
      -----------

      function Deref (P : Pointer) return Object
      is (Copy (To_Access (P).all));

   end Copy_Operations;

   ------------
   -- Create --
   ------------

   procedure Create (X : Input; P : out Pointer) with SPARK_Mode => Off is
   begin
      P := Allocate (Create_Object (X));
   end Create;

   -------------
   -- Dealloc --
   -------------

   procedure Dealloc (P : in out Pointer) is
   begin
      Deallocate (P);
   end Dealloc;

   ---------------
   -- Reference --
   ---------------

   function Reference
     (Memory : Memory_Type; P : Pointer) return not null access Object
   is (To_Access (P));

end SPARK.Pointers.Explicit_Reclamation.Global_Memory;
