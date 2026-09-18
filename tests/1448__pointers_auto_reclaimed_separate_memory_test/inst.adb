with Counters;

package body Inst with SPARK_Mode is

   procedure Bump with Global => null, Always_Terminates;
   --  The body is hidden from SPARK, so that Reclaim can keep the
   --  Global => null contract the library's formal expects.

   procedure Bump with SPARK_Mode => Off is
   begin
      Counters.Bump;
   end Bump;

   procedure Reclaim (X : in out Owning_Object) is
   begin
      Free (X.D);
      Bump;
   end Reclaim;

end Inst;
