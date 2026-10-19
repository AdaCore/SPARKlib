package body Inst
  with SPARK_Mode
is

   procedure Reclaim (X : in out Owning_Object) is
   begin
      Free (X.D);
   end Reclaim;

   function Copy (O : Owning_Object) return Owning_Object is
   begin
      if O.D = null then
         return (D => null);
      else
         return (D => new Integer'(O.D.all));
      end if;
   end Copy;

   function Tree_Next
     (O : not null access constant Tree_Node; W : Way)
      return access constant Tree_Handles.Handle is
   begin
      if W <= O.Arity then
         return O.Children (W)'Access;
      else
         return null;
      end if;
   end Tree_Next;

end Inst;
