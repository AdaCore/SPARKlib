with Ada.Text_IO;
with SPARK.Pointers.Static_Allocation;

--  Proof and execution tests for statically allocated objects

procedure Test with SPARK_Mode is

   procedure Assert (B : Boolean; S : String)
   with Pre => B;
   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   procedure Test_Scalar is
      function Create_Object return Integer is (42);
      package Storage is new SPARK.Pointers.Static_Allocation
        (Integer, Create_Object);
      use Storage;

      Q : Object_Access := P;
   begin
      Assert (Q /= null, "Initial pointer is not null");
      Assert (Q.all = 42, "Initial scalar value");
      declare
         R : access Integer := Q;
      begin
         R.all := 43;
      end;
      Assert (Q.all = 43, "Mutation through a borrow");
      P := Q;
      Assert (P.all = 43, "Ownership returned to the instance");
   end Test_Scalar;

   procedure Test_String is
      function Create_Object return String is (5 .. 8 => 'a');
      package Storage is new SPARK.Pointers.Static_Allocation
        (String, Create_Object);
      use Storage;

      Q : Object_Access := P;
   begin
      Assert (Q /= null, "Initial string pointer is not null");
      Assert (Q'First = 5 and Q'Last = 8, "Bounds supplied by Create_Object");
      Assert (Q.all = "aaaa", "Initial string value");
      declare
         R : access String := Q;
      begin
         R (6) := 'b';
      end;
      declare
         R : access constant String := Q;
      begin
         Assert (R.all = "abaa", "Observation after a mutable borrow");
      end;
      P := Q;
      Assert (P.all = "abaa", "String ownership returned to the instance");
   end Test_String;

   procedure Test_Discriminants is
      type Buffer (Length : Positive) is record
         Data : String (1 .. Length);
      end record;

      --  Initialization uses logical equality, independently of user equality
      function "=" (Left, Right : Buffer) return Boolean is
        (Left.Length = Right.Length);

      function Create_Object return Buffer is ((Length => 3, Data => "abc"));
      package Storage is new SPARK.Pointers.Static_Allocation
        (Buffer, Create_Object);
      use Storage;
   begin
      Assert (P /= null, "Initial record pointer is not null");
      Assert (P.Length = 3, "Discriminant supplied by Create_Object");
      Assert (P.Data = "abc", "Components preserved by logical equality");
      declare
         R : access Buffer := P;
      begin
         R.Data (2) := 'x';
      end;
      Assert (P.Data = "axc", "Mutation of a discriminated object");
   end Test_Discriminants;

begin
   Test_Scalar;
   Test_String;
   Test_Discriminants;
end Test;
