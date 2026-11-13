with Instances; use Instances;

procedure Constant_Invalid with SPARK_Mode is
   X : aliased Relaxed := (Value => 0);
   P : constant not null access constant Relaxed := X'Access;
   Y : constant not null access constant Positive_Word :=
     Constant_Invalid_Checked.Convert_Constant_Access (P); -- @PRECONDITION:FAIL
begin
   null;
end Constant_Invalid;
