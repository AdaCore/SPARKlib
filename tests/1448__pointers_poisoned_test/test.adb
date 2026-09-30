with Ada.Text_IO;
with Inst; use Inst;
use Inst.Pointer_Side;
use Inst.View_Side;

--  Execution test for SPARK.Pointers.Poisoned. Proof of the same API is in
--  testsuite/gnatprove/tests/1448__pointers_poisoned.

procedure Test with SPARK_Mode => Off is

   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   procedure Test_Pointer is
      use Pointers;
      H : Pointer := Create_Pointer ((V => 42));
      G : Pointer;
   begin
      Assert (Constant_Reference (H).V = 42, "Deref of a fresh holder");

      --  Taking the content moves it out and poisons the source
      G := Take (H);
      Assert (Constant_Reference (G).V = 42, "Deref after Take");

      Reclaim (G);
      Assert (G = Null_Pointer, "Reclaim nulls out the holder");
      --  H is poisoned, so it is already reclaimed and needs no action
   end Test_Pointer;

   --  Copy_Operations. Create_Copy is what fills a cell from an Object, since
   --  Assign has no designated value to overwrite on a poisoned pointer.

   procedure Test_Copy_Operations is
      use Pointers;
      use Copy_Ops;
      P : Pointer := Create_Copy ((V => 11));
   begin
      Assert (Deref (P).V = 11, "Deref after Create_Copy");
      Assert (Constant_Reference (P).V = 11, "Create_Copy filled the cell");

      Assign (P, (V => 22));
      Assert (Deref (P).V = 22, "Deref after Assign");
      Assert (Constant_Reference (P).V = 22, "Assign overwrote in place");

      Reclaim (P);
      Assert (P = Null_Pointer, "Reclaim nulls out the pointer");
   end Test_Copy_Operations;

   procedure Test_Move is
      use Pointers;
      Source : Pointer := Create_Pointer ((V => 7));
      Target : Pointer;
   begin
      Move (Source, Target);
      Assert (Constant_Reference (Target).V = 7, "Deref after Move");
      Reclaim (Target);
   end Test_Move;

   procedure Test_Handles is
      use Pointers;
      H : aliased Object_Handle := Create_Object_Handle ((V => 9));
   begin
      Assert (Constant_Reference
                (Handle_Operations.Constant_Reference (H).all).V = 9,
              "Deref through a handle");

      --  Writing through the handle reaches the holder it designates
      declare
         R : constant not null access Pointer := Handle_Operations.Reference (H);
      begin
         Assert (Constant_Reference (R.all).V = 9, "Reference sees the holder");
         Reclaim (R.all);
      end;

      --  A null handle designates Null_Pointer
      declare
         Nh : aliased Object_Handle := Handle_Operations.Null_Handle;
      begin
         Assert (Handle_Operations.Constant_Reference (Nh).all = Null_Pointer,
                 "Null_Handle designates Null_Pointer");
      end;
   end Test_Handles;

   procedure Test_Pointer_Array is
      use Pointers;
      use Pointer_Arrays;
      A : Pointer_Array (1 .. 3) :=
        [Create_Pointer ((V => 1)), Create_Pointer ((V => 2)),
         Create_Pointer ((V => 3))];
      Temp : Pointer;
   begin
      --  Swap the first and last elements, going through the poisoned state
      Temp := Take (A (1));
      Relocate (A, 3, 1);
      Move (Temp, A (3));

      Assert (Constant_Reference (A (1)).V = 3, "Swap moved the last element");
      Assert (Constant_Reference (A (2)).V = 2, "Swap left the middle alone");
      Assert (Constant_Reference (A (3)).V = 1, "Swap moved the first element");

      for I in A'Range loop
         Reclaim (A (I));
      end loop;
   end Test_Pointer_Array;

   procedure Test_View_Array is
      use Views;
      use View_Arrays;
      A : aliased Object_Array := [(V => 1), (V => 2), (V => 3)];
      Temp : View;
   begin
      declare
         Vs : constant not null access Readable_Array := Get_View (A);
      begin
         Temp := Take (Vs (1));
         Relocate (Vs.all, 3, 1);
         Move (Temp, Vs (3));
      end;

      --  The moves happened in place, in the caller's own array
      Assert (A (1).V = 3, "Swap through a view moved the last element");
      Assert (A (2).V = 2, "Swap through a view left the middle alone");
      Assert (A (3).V = 1, "Swap through a view moved the first element");
   end Test_View_Array;

   --  The slice operations. Relocate shifts 4 .. 6 down onto 1 .. 3 inside
   --  one array; the cells it moves out of are left poisoned, so only the
   --  landing cells are reclaimed at the end.

   procedure Test_Pointer_Slice is
      use Pointers;
      use Pointer_Arrays;
      A : Pointer_Array (1 .. 6) :=
        [Create_Pointer ((V => 1)), Create_Pointer ((V => 2)),
         Create_Pointer ((V => 3)), Create_Pointer ((V => 4)),
         Create_Pointer ((V => 5)), Create_Pointer ((V => 6))];
   begin
      --  Relocate needs its landing cells to own nothing
      for I in Index range 1 .. 3 loop
         Reclaim (A (I));
      end loop;

      Relocate (A, 4, 6, 1, 3);
      Assert (Constant_Reference (A (1)).V = 4, "Slide moved the 4th element");
      Assert (Constant_Reference (A (2)).V = 5, "Slide moved the 5th element");
      Assert (Constant_Reference (A (3)).V = 6, "Slide moved the 6th element");

      for I in Index range 1 .. 3 loop
         Reclaim (A (I));
      end loop;
   end Test_Pointer_Slice;

   --  The slice Move, between two distinct arrays

   procedure Test_Pointer_Move_Slice is
      use Pointers;
      use Pointer_Arrays;
      Source : Pointer_Array (1 .. 3) :=
        [Create_Pointer ((V => 1)), Create_Pointer ((V => 2)),
         Create_Pointer ((V => 3))];
      Target : Pointer_Array (1 .. 3);
   begin
      Move (Source, 1, 3, Target, 1, 3);
      Assert (Constant_Reference (Target (1)).V = 1, "Move carried the slice");
      Assert (Constant_Reference (Target (3)).V = 3, "Move carried the slice");

      for I in Target'Range loop
         Reclaim (Target (I));
      end loop;
      --  Source is poisoned throughout, so it owns nothing
   end Test_Pointer_Move_Slice;

   --  A view of a single object, rather than of an array

   procedure Test_View_Scalar is
      use Views;
      X : aliased Object := (V => 5);
   begin
      declare
         V : constant not null access Readable_View := Get_View (X);
      begin
         Assert (Constant_Reference (V.all).V = 5,
                 "Constant_Reference on a view");
         Reference (V.all).V := 6;
      end;
      Assert (X.V = 6, "Reference wrote through the view");
   end Test_View_Scalar;

   --  Create refills a view poisoned by Take, and builds standalone views

   procedure Test_View_Create is
      use Views;
      use View_Arrays;
      A     : aliased Object_Array := [(V => 1), (V => 2), (V => 3)];
      Temp  : View;
      Fresh : aliased Readable_View := Create_View (7);
   begin
      declare
         Vs : constant not null access Readable_Array := Get_View (A);
      begin
         Temp := Take (Vs (2));
         Vs (2) := Create_View (9);
      end;
      Assert (A (2).V = 9, "Create refilled the poisoned view");
      Assert (A (1).V = 1 and A (3).V = 3,
              "Create left the other cells alone");
      Assert (Constant_Reference (Fresh).V = 7,
              "Create built a standalone view");
   end Test_View_Create;

   --  Take and Move give back the object in a view as a plain Object

   procedure Test_View_To_Object is
      use Views;
      use View_Arrays;
      A : aliased Object_Array := [(V => 1), (V => 2), (V => 3)];
      X : Object;
      Y : Object := (V => 0);
   begin
      declare
         Vs : constant not null access Readable_Array := Get_View (A);
      begin
         X := Take (Vs (1));
         Vs (1) := Create_View (4);
         Move (Vs (3), Y);
         Vs (3) := Create_View (5);
      end;
      Assert (X.V = 1, "Take returned the object in the view");
      Assert (Y.V = 3, "Move carried the object out of the view");
      Assert (A (1).V = 4 and A (2).V = 2 and A (3).V = 5,
              "Take and Move only touched their source");
   end Test_View_To_Object;

   --  The slice operations on views, in place in the caller's own arrays

   procedure Test_View_Slice is
      use Views;
      use View_Arrays;
      A : aliased Object_Array :=
        [(V => 1), (V => 2), (V => 3), (V => 4), (V => 5), (V => 6)];
      B : aliased Object_Array := [(V => 0), (V => 0), (V => 0)];
   begin
      declare
         Vs : constant not null access Readable_Array := Get_View (A);
      begin
         Relocate (Vs.all, 4, 6, 1, 3);
      end;
      Assert (A (1).V = 4, "Slide through a view moved the 4th element");
      Assert (A (3).V = 6, "Slide through a view moved the 6th element");

      declare
         Va : constant not null access Readable_Array := Get_View (A);
         Vb : constant not null access Readable_Array := Get_View (B);
      begin
         Move (Va.all, 1, 3, Vb.all, 1, 3);
      end;
      Assert (B (1).V = 4, "Move carried the slice between views");
      Assert (B (3).V = 6, "Move carried the slice between views");
   end Test_View_Slice;

begin
   Test_Pointer;
   Test_Copy_Operations;
   Test_Move;
   Test_Handles;
   Test_Pointer_Array;
   Test_Pointer_Slice;
   Test_Pointer_Move_Slice;
   Test_View_Array;
   Test_View_Scalar;
   Test_View_Slice;
   Test_View_Create;
   Test_View_To_Object;
end Test;
