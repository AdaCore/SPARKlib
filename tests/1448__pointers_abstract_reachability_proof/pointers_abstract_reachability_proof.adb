pragma Ada_2022;

with SPARK.Containers.Functional.Infinite_Sequences;
with SPARK.Containers.Functional.Sets;
with SPARK.Pointers.Abstract_Maps;
with SPARK.Pointers.Abstract_Reachability;

procedure Pointers_Abstract_Reachability_Proof with SPARK_Mode
is
   --  Run the proofs on as general an example as possible

   package Nested is
      type Key_Type is private;
      type Object_Type is private;

      function "=" (Left, Right : Key_Type) return Boolean
      with Global => null, Annotate => (GNATprove, Logical_Equal);

      No_Key : constant Key_Type;

      function Next (O : Object_Type) return Key_Type
      with Import, Global => null, Ghost => Static;
   private
      pragma SPARK_Mode (Off);
      type Key_Type is record
         V : Integer;
      end record;
      type Object_Type is new Float;
      No_Key : constant Key_Type := (V => 0);
      function "=" (Left, Right : Key_Type) return Boolean
      is (Left.V = Right.V);
   end Nested;
   use Nested;

   package Memory_Maps is new
     SPARK.Pointers.Abstract_Maps (Key_Type, No_Key, Object_Type);

   package Ghost_Containers with Ghost => Static is
      package Key_Sets is new SPARK.Containers.Functional.Sets (Key_Type, "=");
      package Key_Sequences is new
        SPARK.Containers.Functional.Infinite_Sequences
          (Key_Type, "=", Use_Logical_Equality => True);
   end Ghost_Containers;
   use Ghost_Containers;
   use type Key_Sets.Set;
   use type Key_Sequences.Sequence;

   package Inst_Automated is new
     SPARK.Pointers.Abstract_Reachability
       (Memory_Maps                           => Memory_Maps,
        "="                                   => "=",
        Next                                  => Next,
        Key_Sets                              => Key_Sets,
        Key_Sequences                         => Key_Sequences,
        Automatically_Instantiate_Definitions => True);

   package Inst_Manual is new
     SPARK.Pointers.Abstract_Reachability
       (Memory_Maps                           => Memory_Maps,
        "="                                   => "=",
        Next                                  => Next,
        Key_Sets                              => Key_Sets,
        Key_Sequences                         => Key_Sequences,
        Automatically_Instantiate_Definitions => False);

begin
   null;
end Pointers_Abstract_Reachability_Proof;
