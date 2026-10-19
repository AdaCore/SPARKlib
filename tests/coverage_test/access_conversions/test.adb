with Ada.Text_IO;
with Inst; use Inst;

--  Execution test for SPARK.Conversions.Access_Conversions. It instantiates the
--  four generics (see Inst) and exercises every conversion function. The
--  asserted properties follow from the generics' postconditions and from the
--  precise handling of the Unchecked_Conversions, so this unit is proved as
--  well as run. Only a failing check prints anything, so a passing run has
--  empty output.
--
--  The conversion functions take an access value. An 'Access attribute of an
--  owning object may only appear directly in an object declaration, so each
--  call first binds the access to a local object and passes that.

procedure Test with SPARK_Mode is

   procedure Assert (B : Boolean; S : String) with Pre => B;

   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   --  Access_Constant_Conversions: observe a constant through the converted
   --  view. The conversion maps the fields positionally.

   procedure Test_Constant is
      S  : aliased constant Src_Valid := (A => 1, B => 2);
      SA : constant not null access constant Src_Valid := S'Access;
      T  : constant not null access constant Tgt_Valid :=
        Constant_Conversions.Convert_Constant_Access (SA);
   begin
      Assert (T.X = 1 and T.Y = 2,
              "Convert_Constant_Access reinterprets the fields");
   end Test_Constant;

   --  Access_Variable_Conversions. Convert_Access is exercised by a borrow
   --  that writes both fields; the library's own postcondition, executed at run
   --  time, checks the write reached the source. Once the borrow ends, the
   --  source SV is read back to confirm the writes are visible there, mapped
   --  positionally. Convert_Constant_Access is exercised separately as an
   --  observe.

   procedure Test_Variable is
      SV : aliased Src_Valid := (A => 3, B => 4);
   begin
      declare
         SA : constant not null access Src_Valid := SV'Access;
         T  : constant not null access Tgt_Valid :=
           Variable_Conversions.Convert_Access (SA);
      begin
         T.X := 30;
         T.Y := 40;
      end;
      Assert (SV.A = 30 and SV.B = 40,
              "Convert_Access wrote through to the source");
      declare
         S  : aliased constant Src_Valid := (A => 5, B => 6);
         SA : constant not null access constant Src_Valid := S'Access;
         T  : constant not null access constant Tgt_Valid :=
           Variable_Conversions.Convert_Constant_Access (SA);
      begin
         Assert (T.X = 5 and T.Y = 6,
                 "Convert_Constant_Access of the variable instance");
      end;
   end Test_Variable;

   --  Access_Constant_Conversions_Potentially_Invalid. Bytes 2 and 1 denote
   --  the valid codes C2 and C1, so the 'Valid_Scalars contract holds.

   procedure Test_Constant_PI is
      S  : aliased constant Src_PI := (A => 2, B => 1);
      SA : constant not null access constant Src_PI := S'Access;
      T  : constant not null access constant Tgt_PI :=
        Constant_Conversions_PI.Convert_Constant_Access (SA);
   begin
      Assert (T.X = C2 and T.Y = C1,
              "Potentially-invalid Convert_Constant_Access");
   end Test_Constant_PI;

   --  Access_Variable_Conversions_Potentially_Invalid.

   procedure Test_Variable_PI is
      SV : aliased Src_PI := (A => 1, B => 0);
   begin
      declare
         SA : constant not null access Src_PI := SV'Access;
         T  : constant not null access Tgt_PI :=
           Variable_Conversions_PI.Convert_Access (SA);
      begin
         T.X := C3;
         T.Y := C2;
      end;
      --  C3 and C2 are stored as the bytes 3 and 2, so the writes are visible
      --  in the source once the borrow ends.
      Assert (SV.A = 3 and SV.B = 2,
              "Convert_Access wrote through to the source (PI instance)");
      declare
         S  : aliased constant Src_PI := (A => 3, B => 2);
         SA : constant not null access constant Src_PI := S'Access;
         T  : constant not null access constant Tgt_PI :=
           Variable_Conversions_PI.Convert_Constant_Access (SA);
      begin
         Assert (T.X = C3 and T.Y = C2,
                 "Potentially-invalid Convert_Constant_Access of the variable "
                 & "instance");
      end;
   end Test_Variable_PI;

begin
   Test_Constant;
   Test_Variable;
   Test_Constant_PI;
   Test_Variable_PI;
end Test;
