with SPARK.Strings.Unicode;       use SPARK.Strings.Unicode;
with SPARK.Strings.Unicode.UTF_8; use SPARK.Strings.Unicode.UTF_8;

package Clients
  with SPARK_Mode
is
   procedure Append (Prefix : String; Value : Scalar_Value)
   with
     Pre =>
       Is_Valid_UTF_8 (Prefix) and then Prefix'Length <= Natural'Last - 10;

   procedure Round_Trip (Value : Scalar_Value);

   function Count_By_Traversal (S : String) return Natural
   with
     Pre  => Is_Valid_UTF_8 (S),
     Post => Count_By_Traversal'Result = Code_Point_Length (S);

   procedure Extract (S : String; Start : Positive; Count : Natural)
   with
     Pre =>
       Is_Valid_UTF_8 (S)
       and then Start - 1 <= Code_Point_Length (S)
       and then Count <= Code_Point_Length (S) - (Start - 1);
   function Valid_Prefix_Bytes (S : String) return Natural
   with
     Post =>
       Valid_Prefix_Bytes'Result <= S'Length
       and then
         Is_Valid_UTF_8
           (S (S'First .. S'Last - (S'Length - Valid_Prefix_Bytes'Result)));
end Clients;
