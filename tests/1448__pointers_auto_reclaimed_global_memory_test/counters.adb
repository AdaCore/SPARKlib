package body Counters with SPARK_Mode => Off is

   procedure Bump is
   begin
      Reclaimed := Reclaimed + 1;
   end Bump;

end Counters;
