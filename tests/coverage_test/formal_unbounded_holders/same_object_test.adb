with SPARK.Containers.Formal.Unbounded_Holders;

--  Call Assign, Move and Swap with the same holder as both parameters, which
--  has no effect, and Replace_Element with a view of the element which is
--  replaced. Such calls are not possible in SPARK, which forbids this
--  aliasing, so turn off proof. Also turn off the execution of postconditions,
--  as they assume that the parameters do not overlap.

procedure Same_Object_Test with SPARK_Mode => Off is
   pragma Assertion_Policy (SPARKlib_Full => Ignore);
   pragma Warnings (Off, "writable actual for * overlaps with actual for *");

   package String_Holders is new
     SPARK.Containers.Formal.Unbounded_Holders (String);
   use String_Holders;

   H : Holder := To_Holder ("abc");
begin
   Assign (Target => H, Source => H);
   pragma Assert (Element (H) = "abc");

   Move (Target => H, Source => H);
   pragma Assert (Element (H) = "abc");

   Swap (H, H);
   pragma Assert (Element (H) = "abc");

   Replace_Element (H, Constant_Reference (H).all);
   pragma Assert (Element (H) = "abc");
end Same_Object_Test;
