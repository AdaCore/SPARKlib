pragma Ada_2022;

with SPARK.Containers.Formal.Unbounded_Ordered_Sets;

procedure Big_Test with SPARK_Mode => Off is
   pragma Assertion_Policy (SPARKlib_Full => Ignore);

   package Int_Sets is new SPARK.Containers.Formal.Unbounded_Ordered_Sets (Integer);
   use Int_Sets;

   X : Set;
begin
   --  Exercise rotations and relinking with orders different from insertion
   for I in 1 .. 1000 loop
      Insert (X, (I * 503) mod 1000 + 1);
   end loop;
   for I in 1 .. 1000 loop
      Delete (X, (I * 499) mod 1000 + 1);
   end loop;
   pragma Assert (Is_Empty (X));
end Big_Test;
