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

   function Count (P : List_Pointers.Pointer) return Big_Natural is
   begin
      if P = List_Pointers.Null_Pointer then
         return Big_Natural'(0);
      else
         return 1
                + Count
                    (List_Handle_Ops.Of_Handle
                       (Cell_Next
                          (List_Pointers.Constant_Reference (P)).all));
      end if;
   end Count;

   function Tree_Next (O : not null access constant Tree_Node; W : Way)
     return access constant Tree_Handles.Handle is
   begin
      if W <= O.Arity then
         return O.Children (W)'Access;
      else
         return null;
      end if;
   end Tree_Next;

end Inst;
