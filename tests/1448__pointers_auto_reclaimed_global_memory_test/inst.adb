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
      Bump;
   end Reclaim;

   function Copy_Cell (O : Cell) return Cell is
   begin
      if O.Value = null then
         return (null, O.Next, O.Prev);
      else
         return (new Integer'(O.Value.all), O.Next, O.Prev);
      end if;
   end Copy_Cell;

end Inst;
