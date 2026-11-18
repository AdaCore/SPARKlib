--
--  Copyright (C) 2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

package body SPARK.Containers.Formal.Generic_List_Storage
  with SPARK_Mode
is

   ----------------------
   -- Structural_Model --
   ----------------------

   package body Structural_Model is

      -------------------------------
      -- Lemma_Free_List_Preserved --
      -------------------------------

      procedure Lemma_Free_List_Preserved
        (X : Count_Type'Base; M1, M2 : Nodes_Type_Base) is
      begin
         if X >= 0 then
            Lemma_Reachable_Preserved (X, M1, M2);
            Lemma_Is_Acyclic_Preserved (X, M1, M2);
         end if;
      end Lemma_Free_List_Preserved;

   end Structural_Model;

end SPARK.Containers.Formal.Generic_List_Storage;
