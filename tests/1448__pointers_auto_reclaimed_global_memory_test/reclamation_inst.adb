with Counters;

package body Reclamation_Inst
  with SPARK_Mode => Off
is

   procedure Reclaim (X : in out Owning_Object) is
   begin
      Free (X.D);
      Counters.Bump;
   end Reclaim;

   function Copy_Owning (O : Owning_Object) return Owning_Object is
   begin
      if O.D = null then
         return (D => null);
      else
         return (D => new Integer'(O.D.all));
      end if;
   end Copy_Owning;

   procedure Reclaim (X : in out Cell) is
   begin
      Free (X.Value);
      Counters.Bump;
   end Reclaim;

   function Copy_Cell (O : Cell) return Cell is
   begin
      if O.Value = null then
         return (null, O.Next, O.Prev);
      else
         return (new Integer'(O.Value.all), O.Next, O.Prev);
      end if;
   end Copy_Cell;

end Reclamation_Inst;
