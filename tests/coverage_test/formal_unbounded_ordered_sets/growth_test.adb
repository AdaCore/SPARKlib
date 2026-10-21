pragma Ada_2022;

with SPARK.Containers.Formal.Unbounded_Ordered_Sets;
with SPARK.Containers.Types; use SPARK.Containers.Types;

procedure Growth_Test with SPARK_Mode => Off is
   pragma Assertion_Policy (SPARKlib_Full => Ignore);

   package Int_Sets is new SPARK.Containers.Formal.Unbounded_Ordered_Sets
     (Integer);
   use Int_Sets;

   procedure Fill (Container : in out Set; First_Item, Last_Item : Integer) is
   begin
      for Item in First_Item .. Last_Item loop
         Insert (Container, Item);
      end loop;
   end Fill;

begin
   declare
      Target, Source : Set;
   begin
      Fill (Target, 1, 5);
      Fill (Source, 100, 220);
      Union (Target, Source);
      if Length (Target) /= 126
        or else not Contains (Target, 1)
        or else not Contains (Target, 220)
      then
         raise Program_Error with "Union did not grow target correctly";
      end if;
   end;

   declare
      Target, Source : Set;
   begin
      Fill (Target, 1, 5);
      Fill (Source, 100, 220);
      Symmetric_Difference (Target, Source);
      if Length (Target) /= 126
        or else not Contains (Target, 1)
        or else not Contains (Target, 220)
      then
         raise Program_Error with
           "Symmetric_Difference did not grow target correctly";
      end if;
   end;
end Growth_Test;
