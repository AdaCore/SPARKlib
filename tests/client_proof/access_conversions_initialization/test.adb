with Instances; use Instances;

procedure Test with SPARK_Mode is
   use type Word;
   X : aliased Relaxed := (Value => 42);
   P : constant not null access constant Relaxed := X'Access;
   Y : constant not null access constant Word :=
     Constant_Checked.Convert_Constant_Access (P);
begin
   pragma Assert (Y.all = 42);
end Test;
