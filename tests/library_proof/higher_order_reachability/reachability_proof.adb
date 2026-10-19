pragma Ada_2022;

with SPARK.Containers.Functional.Infinite_Sequences;
with SPARK.Containers.Functional.Sets;
with SPARK.Higher_Order.Reachability;

procedure Reachability_Proof with SPARK_Mode
is
   --  Run the proofs on as general an example as possible

   package Nested with
      Initial_Condition => No_Index_Raw not in First .. Last
   is
      First, Last, No_Index_Raw : constant Integer;
      type Cell is private;
      function Next (C : Cell) return Integer with
        Import,
        Global => null;
   private
      pragma SPARK_Mode (Off);
      type Cell is new Float;
      First : constant Integer := 1;
      Last : constant Integer := 10;
      No_Index_Raw : constant Integer := 0;
   end Nested;
   use Nested;

   subtype Index_Type is Integer range First .. Last;

   subtype No_Index_Type is Integer with
     Predicate => No_Index_Type not in First .. Last;
   No_Index : constant No_Index_Type := No_Index_Raw;

   type Memory_Array is array (Index_Type range <>) of Cell;

   package Memory_Index_Sets is new
     SPARK.Containers.Functional.Sets (Index_Type);
   use type Memory_Index_Sets.Set;
   package Memory_Index_Sequences is new
     SPARK.Containers.Functional.Infinite_Sequences
       (Index_Type,
        Use_Logical_Equality => True);
   use type Memory_Index_Sequences.Sequence;

   package Inst_Automated is new
     SPARK.Higher_Order.Reachability
     (Index_Type                            => Index_Type,
      No_Index                              => No_Index,
      Cell_Type                             => Cell,
      Memory_Type                           => Memory_Array,
      Next                                  => Next,
      Memory_Index_Sets                     => Memory_Index_Sets,
      Memory_Index_Sequences                => Memory_Index_Sequences,
      Automatically_Instantiate_Definitions => True);

   package Inst_Manual is new
     SPARK.Higher_Order.Reachability
     (Index_Type                            => Index_Type,
      No_Index                              => No_Index,
      Cell_Type                             => Cell,
      Memory_Type                           => Memory_Array,
      Next                                  => Next,
      Memory_Index_Sets                     => Memory_Index_Sets,
      Memory_Index_Sequences                => Memory_Index_Sequences,
      Automatically_Instantiate_Definitions => False);

begin
   null;
end Reachability_Proof;
