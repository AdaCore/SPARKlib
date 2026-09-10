--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Ada.Unchecked_Conversion;
with Ada.Unchecked_Deallocation;

package body SPARK.Pointers.Auto_Reclaimed.Global_Memory
  with SPARK_Mode => Off, Refined_State => (Memory => null)
is

   use Definitions;

   procedure Free is new Ada.Unchecked_Deallocation (Object, Object_Access);

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
         Old_Value : Object_Access := Get_Object (P);
         New_Value : constant Object_Access := new Object'(Copy (O));
         --  Built before the old value is reclaimed, so that Copy cannot
         --  observe a reclaimed object
      begin
         --  Install the new value before reclaiming the old one. Reclaim is
         --  user code and may reach P again through a cycle; it would
         --  otherwise find P designating the value being reclaimed.

         Set_Object (P, New_Value);
         Reclaim_Object (Old_Value);
      end Assign;

      -----------------
      -- Create_Copy --
      -----------------

      procedure Create_Copy (O : Object; P : out Pointer) is
      begin
         Create_Cell (P, new Object'(Copy (O)));
      end Create_Copy;

      -----------
      -- Deref --
      -----------

      function Deref (P : Pointer) return Object
      is (Copy (Get_Object (P).all));

   end Copy_Operations;

   ------------
   -- Create --
   ------------

   procedure Create (X : Input; P : out Pointer) with SPARK_Mode => Off is
   begin
      Create_Cell (P, new Object'(Create_Object (X)));
   end Create;

   -----------------
   -- Definitions --
   -----------------

   package body Definitions is

      -----------------
      -- Create_Cell --
      -----------------

      procedure Create_Cell (P : out Pointer; O : Object_Access) is
      begin
         P :=
           (Data =>
              (Counter =>
                 (Shared_Data =>
                    new Ref_Counted_Data.Dual_Count_And_Data'
                      (Strong_Count => 1, Weak_Count => 0, Data => O),
                  Extra_Data  => (null record))));
      end Create_Cell;

      -------------
      -- Reclaim --
      -------------

      procedure Reclaim (D : in out Object_Access; P : No_Extra_Data) is
         pragma Unreferenced (P);
      begin
         Reclaim_Object (D);
      end Reclaim;

      --------------------
      -- Reclaim_Object --
      --------------------

      procedure Reclaim_Object (D : in out Object_Access) is
      begin
         if D /= null then
            Reclaim (D.all);
            Free (D);
         end if;
      end Reclaim_Object;

      ----------------
      -- Set_Object --
      ----------------

      procedure Set_Object (P : Pointer; O : Object_Access) is
      begin
         P.Data.Counter.Shared_Data.Data := O;
      end Set_Object;

   end Definitions;

   -----------------------
   -- Handle_Operations --
   -----------------------

   package body Handle_Operations
     with SPARK_Mode => Off
   is

      ---------
      -- "=" --
      ---------

      function "=" (X, Y : Strong_Handle) return Boolean
      is (Same_Pointer (X, Y));

      function "=" (X, Y : Weak_Handle) return Boolean
      is (Same_Pointer (X, Y));

      ----------------------
      -- Of_Strong_Handle --
      ----------------------

      function Of_Strong_Handle (H : Strong_Handle) return Pointer is
         type Handle_Access is access constant Strong_Handle;
         type Pointer_Access is access constant Pointer;
         function From_Handle is new
           Ada.Unchecked_Conversion (Handle_Access, Pointer_Access);

         Local : aliased constant Strong_Handle := H;
         --  The local is declared at the handle type, which is the larger of
         --  the two: Extra_Data is a Reclamation_Procedure here and an empty
         --  record in Pointer. Writing a handle into Pointer-sized storage
         --  would overrun it.
      begin
         return From_Handle (Local'Access).all;
      end Of_Strong_Handle;

      --------------------
      -- Of_Weak_Handle --
      --------------------

      function Of_Weak_Handle (H : Weak_Handle) return Pointer is
         S       : Strong_Handle;
         Success : Boolean;
      begin
         Upgrade (H, S, Success);

         if not Success then
            return Null_Pointer;
         end if;

         return Of_Strong_Handle (S);
      end Of_Weak_Handle;

      -------------
      -- Reclaim --
      -------------

      procedure Reclaim (X : in out Data_Placeholder_Access) is
         Y : Object_Access
         with Import, Address => X'Address;
      begin
         Reclaim_Object (Y);
      end Reclaim;

      ----------------------
      -- To_Strong_Handle --
      ----------------------

      function To_Strong_Handle (H : Weak_Handle) return Strong_Handle is
         S       : Strong_Handle;
         Success : Boolean;
      begin
         Upgrade (H, S, Success);

         if not Success then
            return Null_Strong_Handle (Reclamation_Access);
         end if;

         return S;
      end To_Strong_Handle;

      function To_Strong_Handle (P : Pointer) return Strong_Handle is
         type Handle_Access is access all Strong_Handle;
         type Pointer_Access is access all Pointer;
         function From_Handle is new
           Ada.Unchecked_Conversion (Handle_Access, Pointer_Access);

         H : aliased Strong_Handle := Null_Strong_Handle (Reclamation_Access);
         Q : constant Pointer_Access := From_Handle (H'Access);
      begin
         Q.all := P;
         return H;
      end To_Strong_Handle;

      --------------------
      -- To_Weak_Handle --
      --------------------

      function To_Weak_Handle (H : Strong_Handle) return Weak_Handle is
         W : Weak_Handle;
      begin
         Downgrade (H, W);
         return W;
      end To_Weak_Handle;

      function To_Weak_Handle (P : Pointer) return Weak_Handle is
      begin
         return To_Weak_Handle (To_Strong_Handle (P));
      end To_Weak_Handle;

      ------------------
      -- Valid_Handle --
      ------------------

      function Valid_Handle (H : Strong_Handle) return Boolean
      is (Check_Reclamation (H, Reclamation_Access));

      function Valid_Handle (H : Weak_Handle) return Boolean
      is (Check_Reclamation (H, Reclamation_Access));

      ---------------------------
      -- Witnessed_Conversions --
      ---------------------------

      package body Witnessed_Conversions
        with SPARK_Mode => Off
      is

         --------------------
         -- Of_Weak_Handle --
         --------------------

         function Of_Weak_Handle (H : Weak_Handle; X : Input) return Pointer is
            pragma Unreferenced (X);
         begin
            return Of_Strong_Handle (To_Strong_Handle (H));
         end Of_Weak_Handle;

         ----------------------
         -- To_Strong_Handle --
         ----------------------

         function To_Strong_Handle
           (H : Weak_Handle; X : Input) return Strong_Handle
         is
            pragma Unreferenced (X);
         begin
            return Handle_Operations.To_Strong_Handle (H);
         end To_Strong_Handle;

      end Witnessed_Conversions;

   end Handle_Operations;

end SPARK.Pointers.Auto_Reclaimed.Global_Memory;
