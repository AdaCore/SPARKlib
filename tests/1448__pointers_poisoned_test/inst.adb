package body Inst
  with SPARK_Mode
is

   package body Owning_Side is

      function Copy (O : Owning_Object) return Owning_Object is
      begin
         if O.D = null then
            return (D => null);
         else
            return (D => new Integer'(O.D.all));
         end if;
      end Copy;

      procedure Reclaim (P : in out Pointers.Pointer) is
         use Pointers;
      begin
         if P /= Null_Pointer then
            declare
               R : access Owning_Object := Reference (P);
            begin
               Free (R.D);
            end;
         end if;
         Pointers.Reclaim (P);
      end Reclaim;

   end Owning_Side;

end Inst;
