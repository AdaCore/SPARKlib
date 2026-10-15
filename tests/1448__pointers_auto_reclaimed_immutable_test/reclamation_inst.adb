with Counters;

package body Reclamation_Inst
  with SPARK_Mode => Off
is

   procedure Reclaim (X : in out Owning_Object) is
   begin
      Free (X.D);
      Counters.Bump;
   end Reclaim;

end Reclamation_Inst;
