package body Inst
  with SPARK_Mode
is

   function Copy_Owning (O : Owning_Object) return Owning_Object is
   begin
      if O.D = null then
         return (D => null);
      else
         return (D => new Integer'(O.D.all));
      end if;
   end Copy_Owning;

   procedure Reclaim (X : in out Owning_Object) is
   begin
      Free (X.D);
   end Reclaim;

end Inst;
