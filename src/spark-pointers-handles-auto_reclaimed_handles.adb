--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package body SPARK.Pointers.Handles.Auto_Reclaimed_Handles
  with SPARK_Mode => Off
is

   -----------------------
   -- With_Weak_Handles --
   -----------------------

   package body With_Weak_Handles
     with SPARK_Mode => Off
   is

      -------------
      -- Reclaim --
      -------------

      procedure Reclaim
        (D : in out Data_Placeholder_Access; P : Reclamation_Procedure) is
      begin
         P (D);
      end Reclaim;

      --------------------
      -- Link_Utilities --
      --------------------

      package body Link_Utilities
        with SPARK_Mode => Off
      is
         use type Ref_Counted_Data.Dual_Count_And_Data_Access;

         -----------------------
         -- Check_Reclamation --
         -----------------------

         function Check_Reclamation
           (H : Strong_Handle; P : Reclamation_Procedure) return Boolean
         is (H.Data.Counter.Extra_Data = P);

         function Check_Reclamation
           (H : Weak_Handle; P : Reclamation_Procedure) return Boolean
         is (H.Data.Counter.Extra_Data = P);

         ---------------
         -- Downgrade --
         ---------------

         procedure Downgrade (H : Strong_Handle; W : out Weak_Handle) is
         begin
            Ref_Counted_Data.Downgrade (H.Data, W.Data);
         end Downgrade;

         ------------------------
         -- Null_Strong_Handle --
         ------------------------

         function Null_Strong_Handle
           (P : Reclamation_Procedure) return Strong_Handle
         is (Data => (Counter => (null, P)));

         ------------------
         -- Same_Pointer --
         ------------------

         function Same_Pointer (X, Y : Strong_Handle) return Boolean
         is (X.Data.Counter.Shared_Data = Y.Data.Counter.Shared_Data);

         function Same_Pointer (X, Y : Weak_Handle) return Boolean
         is (X.Data.Counter.Shared_Data = Y.Data.Counter.Shared_Data);

         -------------
         -- Upgrade --
         -------------

         procedure Upgrade
           (W : Weak_Handle; H : out Strong_Handle; Success : out Boolean) is
         begin
            Ref_Counted_Data.Upgrade (W.Data, H.Data, Success);
         end Upgrade;

      end Link_Utilities;

   end With_Weak_Handles;

   --------------------------
   -- Without_Weak_Handles --
   --------------------------

   package body Without_Weak_Handles
     with SPARK_Mode => Off
   is

      -------------
      -- Reclaim --
      -------------

      procedure Reclaim
        (D : in out Data_Placeholder_Access; P : Reclamation_Procedure) is
      begin
         P (D);
      end Reclaim;

      --------------------
      -- Link_Utilities --
      --------------------

      package body Link_Utilities
        with SPARK_Mode => Off
      is

         -----------------------
         -- Check_Reclamation --
         -----------------------

         function Check_Reclamation
           (H : Handle; P : Reclamation_Procedure) return Boolean
         is (H.Data.Extra_Data = P);

         -----------------
         -- Null_Handle --
         -----------------

         function Null_Handle (P : Reclamation_Procedure) return Handle
         is (Data => (null, P));

      end Link_Utilities;

   end Without_Weak_Handles;

end SPARK.Pointers.Handles.Auto_Reclaimed_Handles;
