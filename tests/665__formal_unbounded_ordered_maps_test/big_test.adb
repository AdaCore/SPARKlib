pragma Ada_2022;
with Ada.Text_IO;
with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Containers.Formal.Unbounded_Ordered_Maps;

--  Insert and delete several elements in a map to exercise the underlying
--  tree structure. Turn Off the execution of contracts as it is too heavy.
--  Also turn off proof as the underlying representation is not relevant.

procedure Big_Test with SPARK_Mode => Off is
   pragma Assertion_Policy (SPARKlib_Full => Ignore);

   function Lt (X, Y : Integer) return Boolean is
      (X mod 1000 < Y mod 1000);

   function Eq (X, Y : Integer) return Boolean is
      (X mod 1000 = Y mod 1000);

   package Inst is new
     SPARK.Containers.Formal.Unbounded_Ordered_Maps (Integer, Integer, Lt, Eq);
   use Inst;

   --  Insert and delete several elements in a map to exercise the underlying
   --  tree structure. Use big prime numbers to shuffle the inserted integers.

   X : Map;
   procedure Insert_1000 is
   begin
      for I in 1 .. 1000 loop
         Insert (X, (I * 503) mod 1000 + 1, I);
      end loop;
   end Insert_1000;
   procedure Delete_1000 is
   begin
      for I in 1 .. 1000 loop
         Delete (X, (I * 499) mod 1000 + 1);
      end loop;
   end Delete_1000;
begin
   Insert_1000;
   Delete_1000;
end Big_Test;
