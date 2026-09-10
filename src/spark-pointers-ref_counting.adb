--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
with Ada.Unchecked_Deallocation;

package body SPARK.Pointers.Ref_Counting
  with SPARK_Mode => Off
is

   procedure Free is new
     Ada.Unchecked_Deallocation
       (Single_Count_And_Data,
        Single_Count_And_Data_Access);

   procedure Free is new
     Ada.Unchecked_Deallocation
       (Dual_Count_And_Data,
        Dual_Count_And_Data_Access);

   ------------
   -- Adjust --
   ------------

   procedure Adjust (P : in out Shared_Ref) is
   begin
      if P.Shared_Data /= null then
         P.Shared_Data.Count := P.Shared_Data.Count + 1;
      end if;
   end Adjust;

   procedure Adjust (P : in out Strong_Ref) is
   begin
      if P.Counter.Shared_Data /= null then
         P.Counter.Shared_Data.Strong_Count :=
           P.Counter.Shared_Data.Strong_Count + 1;
      end if;
   end Adjust;

   procedure Adjust (P : in out Weak_Ref) is
   begin
      if P.Counter.Shared_Data /= null then
         P.Counter.Shared_Data.Weak_Count :=
           P.Counter.Shared_Data.Weak_Count + 1;
      end if;
   end Adjust;

   ---------------
   -- Downgrade --
   ---------------

   procedure Downgrade (P : Strong_Ref; R : out Weak_Ref) is
   begin
      R.Counter := P.Counter;
      --  Dual_Ref is not finalizable, so this copies the designation
      --  without moving any count. The weak reference is recorded below.

      if R.Counter.Shared_Data /= null then
         R.Counter.Shared_Data.Weak_Count :=
           R.Counter.Shared_Data.Weak_Count + 1;
      end if;
   end Downgrade;

   --------------
   -- Finalize --
   --------------

   procedure Finalize (P : in out Shared_Ref) is
      Block : Single_Count_And_Data_Access := P.Shared_Data;
   begin
      if Block /= null then

         --  Detach P before reclaiming, as in Finalize for Strong_Ref below.
         --  Reclaim is user code and should not find P still designating the
         --  cell being reclaimed.

         P.Shared_Data := null;
         Block.Count := Block.Count - 1;

         if Block.Count = 0 then
            Reclaim (Block.Data, P.Extra_Data);
            Free (Block);
         end if;
      end if;
   end Finalize;

   procedure Finalize (P : in out Strong_Ref) is
      Block : Dual_Count_And_Data_Access := P.Counter.Shared_Data;
   begin
      if Block /= null then
         P.Counter.Shared_Data := null;
         Block.Strong_Count := Block.Strong_Count - 1;

         if Block.Strong_Count = 0 then

            --  Hold a weak reference across Reclaim. The reclaimed value may
            --  store a weak handle to this cell. Dropping it would take
            --  Weak_Count to zero with Strong_Count already zero, so the block
            --  would be freed here and the test below would read it after it
            --  was gone.

            Block.Weak_Count := Block.Weak_Count + 1;
            Reclaim (Block.Data, P.Counter.Extra_Data);
            Block.Weak_Count := Block.Weak_Count - 1;

            if Block.Weak_Count = 0 then
               Free (Block);
            end if;
         end if;
      end if;
   end Finalize;

   procedure Finalize (P : in out Weak_Ref) is
   begin
      if P.Counter.Shared_Data /= null then
         P.Counter.Shared_Data.Weak_Count :=
           P.Counter.Shared_Data.Weak_Count - 1;

         if P.Counter.Shared_Data.Weak_Count = 0
           and P.Counter.Shared_Data.Strong_Count = 0
         then
            Free (P.Counter.Shared_Data);
         end if;

         P.Counter.Shared_Data := null;
      end if;
   end Finalize;

   -------------
   -- Upgrade --
   -------------

   procedure Upgrade (P : Weak_Ref; R : out Strong_Ref; Success : out Boolean)
   is
   begin
      Success :=
        P.Counter.Shared_Data /= null
        and then P.Counter.Shared_Data.Strong_Count /= 0;

      if not Success then

         --  The cell is gone. Keep Extra_Data, which identifies the
         --  reclamation procedure.

         R.Counter :=
           (Shared_Data => null, Extra_Data => P.Counter.Extra_Data);

      else
         R.Counter := P.Counter;
         R.Counter.Shared_Data.Strong_Count :=
           R.Counter.Shared_Data.Strong_Count + 1;
      end if;
   end Upgrade;

end SPARK.Pointers.Ref_Counting;
