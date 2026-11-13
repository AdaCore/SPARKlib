with Instances; use Instances;

procedure Variable_Constant_Invalid with SPARK_Mode is
   X : aliased Relaxed := (Value => 0);
   P : constant not null access constant Relaxed := X'Access;
   Y : constant not null access constant Positive_Word :=
     Variable_Invalid_Checked.Convert_Constant_Access (P); -- @PRECONDITION:FAIL
begin
   null;
end Variable_Constant_Invalid;
