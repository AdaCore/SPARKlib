--  Index types for instantiating SPARK.Containers.Formal.Vectors.Impl in the
--  proof test. Two subtypes are provided to cover the two shapes the
--  implementation distinguishes:
--
--    * Big_Index, whose base type Big_Base is Long_Long_Integer (the widest
--      base type the implementation supports, as its body uses
--      Long_Long_Integer for intermediate index/count arithmetic). For this
--      base type Index_Type'Base'Last >= Count_Type'Last, so the "wide index"
--      branches are exercised.
--
--    * Small_Index, whose base type Small_Base is a narrow integer type with
--      Index_Type'Base'Last < Count_Type'Last, so the "narrow index" branches
--      are exercised.
--
--  In both cases the subtype bounds are obtained through function calls with
--  no precise contract.

with SPARK.Containers.Types; use SPARK.Containers.Types;

package Index_Types with SPARK_Mode is

   --  Forces Long_Long_Integer as the base type (the static range exceeds
   --  32 bits but stays within 64 bits).
   type Big_Base is range -(2 ** 62) .. 2 ** 62;

   --  Forces a narrow base type (Short_Integer): its base'Last stays below
   --  Count_Type'Last.
   type Small_Base is range -1000 .. 1000;

   --  First is not the first element of its base type (to allow the definition
   --  of Extended_Index), and there is at least a valid index.

   function First return Big_Base
     with Import, Global => null,
     Post => First'Result /= Big_Base'Base'First;

   function Last return Big_Base
     with Import, Global => null,
     Post => Last'Result >= First;

   function First return Small_Base
     with Import, Global => null,
     Post => First'Result /= Small_Base'Base'First;

   function Last return Small_Base
     with Import, Global => null,
     Post => Last'Result >= First;

   Big_First   : constant Big_Base := First;
   Big_Last    : constant Big_Base := Last;
   Small_First : constant Small_Base := First;
   Small_Last  : constant Small_Base := Last;

   subtype Big_Index is Big_Base range Big_First .. Big_Last;
   subtype Small_Index is Small_Base range Small_First .. Small_Last;

end Index_Types;
