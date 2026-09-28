--
--  Copyright (C) 2022-2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Ada.Unchecked_Conversion;
with Ada.Unchecked_Deallocation;

package body SPARK.Pointers.Explicit_Reclamation.Separate_Memory
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

      procedure Assign (Memory : in out Memory_Type; P : Pointer; O : Object)
      is
         pragma Unreferenced (Memory);
      begin
         To_Access (P).all := Copy (O);
      end Assign;

      -----------------
      -- Create_Copy --
      -----------------

      procedure Create_Copy
        (Memory : in out Memory_Type; O : Object; P : out Pointer)
      is
         pragma Unreferenced (Memory);
      begin
         P := Allocate (Copy (O));
      end Create_Copy;

      -----------
      -- Deref --
      -----------

      function Deref (Memory : Memory_Type; P : Pointer) return Object
      is (Copy (To_Access (P).all));

   end Copy_Operations;

   ------------
   -- Create --
   ------------

   procedure Create (Memory : in out Memory_Type; X : Input; P : out Pointer)
   with SPARK_Mode => Off
   is
      pragma Unreferenced (Memory);
   begin
      P := Allocate (Create_Object (X));
   end Create;

   -------------
   -- Dealloc --
   -------------

   procedure Dealloc (Memory : in out Memory_Type; P : in out Pointer) is
      pragma Unreferenced (Memory);
   begin
      Deallocate (P);
   end Dealloc;

   -----------------
   -- Move_Memory --
   -----------------

   procedure Move_Memory (Source, Target : in out Memory_Type; F : Footprint)
   is null;

   ---------------
   -- Reference --
   ---------------

   function Reference
     (Memory : Memory_Type; P : Pointer) return not null access Object
   is (To_Access (P));

end SPARK.Pointers.Explicit_Reclamation.Separate_Memory;
