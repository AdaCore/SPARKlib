with Ada.Text_IO;
with Inst; use Inst;
use Inst.Pointer_Side;
use Inst.View_Side;

--  Proof and execution tests for poisoned pointers and views

procedure Test with SPARK_Mode is
   pragma Unevaluated_Use_Of_Old (Allow);

   use type Pointers.Pointer;

   subtype Three_Views is View_Arrays.View_Array (1 .. 3);
   subtype Six_Views is View_Arrays.View_Array (1 .. 6);

   --  Whether every view is readable, as required when an array borrow ends
   function Is_Readable (A : View_Arrays.View_Array) return Boolean
   is (for all V of A => not Views.Is_Poisoned (V))
   with Ghost => Static;

   procedure Assert (B : Boolean; S : String)
   with Pre => B;
   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   --  Reclaim every holder so the test leaves no owned cells behind
   procedure Reclaim_Array (A : in out Pointer_Array)
   with
     Pre  => (Static => (for all P of A => not Pointers.Is_Poisoned (P))),
     Post => (Static => (for all P of A => P = Pointers.Null_Pointer))
   is
      use Pointers;
   begin
      for I in A'Range loop
         pragma
           Loop_Invariant
             (Static =>
                (for all J in A'Range =>
                   (if J < I
                    then A (J) = Null_Pointer
                    else not Is_Poisoned (A (J)))));
         Reclaim (A (I));
      end loop;
   end Reclaim_Array;

   procedure Test_Pointer is
      use Pointers;
      H : Pointer := Create_Pointer ((V => 42));
      G : Pointer;
   begin
      Assert (Constant_Reference (H).V = 42, "Deref of a fresh holder");

      --  The read-write accessor reaches the held object in place
      declare
         R : access Object := Reference (H);
      begin
         R.V := 43;
      end;
      Assert
        (Constant_Reference (H).V = 43, "Reference wrote through the holder");

      --  Taking the content moves it out and poisons the source
      G := Take (H);
      Assert (Constant_Reference (G).V = 43, "Deref after Take");

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
      Assert
        (Constant_Reference (Handle_Operations.Constant_Reference (H).all).V
         = 9,
         "Deref through a handle");

      --  Writing through the handle reaches the holder it designates
      declare
         R : constant not null access Pointer :=
           Handle_Operations.Reference (H);
      begin
         Assert
           (Constant_Reference (R.all).V = 9, "Reference sees the holder");
         Reclaim (R.all);
      end;

      --  A null handle designates Null_Pointer
      declare
         Nh : aliased Object_Handle := Handle_Operations.Null_Handle;
      begin
         Assert
           (Handle_Operations.Constant_Reference (Nh).all = Null_Pointer,
            "Null_Handle designates Null_Pointer");
      end;
   end Test_Handles;

   procedure Test_Pointer_Array is
      use Pointers;
      use Pointer_Arrays;
      A    : Pointer_Array (1 .. 3) :=
        [Create_Pointer ((V => 1)),
         Create_Pointer ((V => 2)),
         Create_Pointer ((V => 3))];
      Temp : Pointer;
   begin
      --  Swap the first and last elements, going through the poisoned state
      Temp := Take (A (1));
      Relocate (A, 3, 1);
      Move (Temp, A (3));

      Assert (Constant_Reference (A (1)).V = 3, "Swap moved the last element");
      Assert (Constant_Reference (A (2)).V = 2, "Swap left the middle alone");
      Assert
        (Constant_Reference (A (3)).V = 1, "Swap moved the first element");

      Reclaim_Array (A);
   end Test_Pointer_Array;

   procedure Test_View_Array is
      use Views;
      use View_Arrays;
      A : aliased Object_Array := [(V => 1), (V => 2), (V => 3)];

      --  Swap the end elements, restoring readability before returning
      procedure Swap (Vs : in out Three_Views)
      with
        Pre  => (Static => Is_Readable (Vs)),
        Post =>
          (Static =>
             Is_Readable (Vs)
             and then Object_Logic_Equal (Peek (Vs (1)), Peek (Vs (3))'Old)
             and then Object_Logic_Equal (Peek (Vs (2)), Peek (Vs (2))'Old)
             and then Object_Logic_Equal (Peek (Vs (3)), Peek (Vs (1))'Old))
      is
         Temp : View;
      begin
         Temp := Take (Vs (1));
         Relocate (Vs, 3, 1);
         Move (Temp, Vs (3));
      end Swap;
   begin
      declare
         Vs : constant not null access Readable_Array := Get_View (A);
      begin
         Swap (Vs.all);
      end;

      --  The moves happened in place, in the caller's own array
      Assert (A (1).V = 3, "Swap through a view moved the last element");
      Assert (A (2).V = 2, "Swap through a view left the middle alone");
      Assert (A (3).V = 1, "Swap through a view moved the first element");
   end Test_View_Array;

   --  The whole array Move on views

   procedure Test_View_Array_Move is
      use Views;
      use View_Arrays;
      Source : View_Array (2 .. 4) :=
        [Create_View (1), Create_View (2), Create_View (3)];
      Target : View_Array (6 .. 8);
   begin
      Move (Source, Target);
      Assert (Constant_Element (Target (6)).V = 1, "Move carried the array");
      Assert (Constant_Element (Target (8)).V = 3, "Move carried the array");

      declare
         R : access Object := Reference_Element (Target (7));
      begin
         R.V := 4;
      end;
      Assert
        (Constant_Element (Target (7)).V = 4,
         "Reference_Element wrote through the view");
      pragma Assert (Static => (for all V of Source => Is_Poisoned (V)));
      --  Source is poisoned throughout, so it owns nothing
   end Test_View_Array_Move;

   --  The slice operations. Relocate shifts 4 .. 6 down onto 1 .. 3 inside
   --  one array; the cells it moves out of are left poisoned, so only the
   --  landing cells are reclaimed at the end.

   procedure Test_Pointer_Slice is
      use Pointers;
      use Pointer_Arrays;
      A : Pointer_Array (1 .. 6) :=
        [Create_Pointer ((V => 1)),
         Create_Pointer ((V => 2)),
         Create_Pointer ((V => 3)),
         Create_Pointer ((V => 4)),
         Create_Pointer ((V => 5)),
         Create_Pointer ((V => 6))];
   begin
      --  Relocate needs its landing cells to own nothing
      Reclaim_Array (A (1 .. 3));

      Relocate (A, 4, 6, 1, 3);
      Assert (Constant_Reference (A (1)).V = 4, "Slide moved the 4th element");
      Assert (Constant_Reference (A (2)).V = 5, "Slide moved the 5th element");
      Assert (Constant_Reference (A (3)).V = 6, "Slide moved the 6th element");

      Reclaim_Array (A (1 .. 3));
   end Test_Pointer_Slice;

   --  The slice Move, between two distinct arrays

   procedure Test_Pointer_Move_Slice is
      use Pointers;
      use Pointer_Arrays;
      Source : Pointer_Array (1 .. 3) :=
        [Create_Pointer ((V => 1)),
         Create_Pointer ((V => 2)),
         Create_Pointer ((V => 3))];
      Target : Pointer_Array (1 .. 3);
   begin
      Move (Source, 1, 3, Target, 1, 3);
      Assert (Constant_Reference (Target (1)).V = 1, "Move carried the slice");
      Assert (Constant_Reference (Target (3)).V = 3, "Move carried the slice");

      Reclaim_Array (Target);
      --  Source is poisoned throughout, so it owns nothing
   end Test_Pointer_Move_Slice;

   --  The whole array Move

   procedure Test_Pointer_Array_Move is
      use Pointers;
      use Pointer_Arrays;
      Source : Pointer_Array (2 .. 4) :=
        [Create_Pointer ((V => 1)),
         Create_Pointer ((V => 2)),
         Create_Pointer ((V => 3))];
      Target : Pointer_Array (6 .. 8);
   begin
      Move (Source, Target);
      Assert (Constant_Reference (Target (6)).V = 1, "Move carried the array");
      Assert (Constant_Reference (Target (8)).V = 3, "Move carried the array");

      pragma Assert (Static => (for all P of Source => Is_Poisoned (P)));
      Reclaim_Array (Target);
      --  Source is poisoned throughout, so it owns nothing
   end Test_Pointer_Array_Move;

   --  A view of a single object, rather than of an array

   procedure Test_View_Scalar is
      use Views;
      X : aliased Object := (V => 5);
   begin
      declare
         V : constant not null access Readable_View := Get_View (X);
      begin
         Assert
           (Constant_Reference (V.all).V = 5, "Constant_Reference on a view");
         declare
            R : access Object := Reference (V.all);
         begin
            R.V := 6;
         end;
      end;
      Assert (X.V = 6, "Reference wrote through the view");
   end Test_View_Scalar;

   --  Create refills a view poisoned by Take, and builds standalone views

   procedure Test_View_Create is
      use Views;
      use View_Arrays;
      A     : aliased Object_Array := [(V => 1), (V => 2), (V => 3)];
      Fresh : aliased Readable_View := Create_View (7);

      --  Take the middle view and refill it with a fresh object
      procedure Refill (Vs : in out Three_Views)
      with
        Pre  => (Static => Is_Readable (Vs)),
        Post =>
          (Static =>
             Is_Readable (Vs)
             and then Peek (Vs (2)).V = 9
             and then Object_Logic_Equal (Peek (Vs (1)), Peek (Vs (1))'Old)
             and then Object_Logic_Equal (Peek (Vs (3)), Peek (Vs (3))'Old))
      is
         Temp : View;
      begin
         Temp := Take (Vs (2));
         Vs (2) := Create_View (9);
      end Refill;
   begin
      declare
         Vs : constant not null access Readable_Array := Get_View (A);
      begin
         Refill (Vs.all);
      end;
      Assert (A (2).V = 9, "Create refilled the poisoned view");
      Assert
        (A (1).V = 1 and A (3).V = 3, "Create left the other cells alone");
      Assert
        (Constant_Reference (Fresh).V = 7, "Create built a standalone view");
   end Test_View_Create;

   --  Take and Move give back the object in a view as a plain Object

   procedure Test_View_To_Object is
      use Views;
      use View_Arrays;
      A : aliased Object_Array := [(V => 1), (V => 2), (V => 3)];
      X : Object;
      Y : Object;

      --  Extract the end objects and refill their views before returning
      procedure Extract (Vs : in out Three_Views; X, Y : out Object)
      with
        Pre  => (Static => Is_Readable (Vs)),
        Post =>
          (Static =>
             Is_Readable (Vs)
             and then Object_Logic_Equal (X, Peek (Vs (1))'Old)
             and then Object_Logic_Equal (Y, Peek (Vs (3))'Old)
             and then Peek (Vs (1)).V = 4
             and then Peek (Vs (3)).V = 5
             and then Object_Logic_Equal (Peek (Vs (2)), Peek (Vs (2))'Old))
      is
      begin
         X := Take (Vs (1));
         Vs (1) := Create_View (4);
         Y := (V => 0);
         Move (Vs (3), Y);
         Vs (3) := Create_View (5);
      end Extract;
   begin
      declare
         Vs : constant not null access Readable_Array := Get_View (A);
      begin
         Extract (Vs.all, X, Y);
      end;
      Assert (X.V = 1, "Take returned the object in the view");
      Assert (Y.V = 3, "Move carried the object out of the view");
      Assert
        (A (1).V = 4 and A (2).V = 2 and A (3).V = 5,
         "Take and Move only touched their source");
   end Test_View_To_Object;

   --  The slice operations on views, in place in the caller's own arrays

   procedure Test_View_Slice is
      use Views;
      use View_Arrays;
      A : aliased Object_Array :=
        [(V => 1), (V => 2), (V => 3), (V => 4), (V => 5), (V => 6)];
      B : aliased Object_Array := [(V => 0), (V => 0), (V => 0)];

      --  Move the last three objects to the front and refill the vacated views
      procedure Slide (Vs : in out Six_Views)
      with
        Pre  => (Static => Is_Readable (Vs)),
        Post =>
          (Static =>
             Is_Readable (Vs)
             and then Object_Logic_Equal (Peek (Vs (1)), Peek (Vs (4))'Old)
             and then Object_Logic_Equal (Peek (Vs (2)), Peek (Vs (5))'Old)
             and then Object_Logic_Equal (Peek (Vs (3)), Peek (Vs (6))'Old)
             and then (for all I in Index range 4 .. 6 => Peek (Vs (I)).V = 0))
      is
      begin
         Relocate (Vs, 4, 6, 1, 3);
         Vs (4) := Create_View (0);
         Vs (5) := Create_View (0);
         Vs (6) := Create_View (0);
      end Slide;

      --  Move the first three objects into Vb and refill their source views
      procedure Transfer (Va : in out Six_Views; Vb : in out Three_Views)
      with
        Pre  =>
          (Static =>
             Is_Readable (Va) and then (for all V of Vb => Is_Reclaimed (V))),
        Post =>
          (Static =>
             Is_Readable (Va)
             and then Is_Readable (Vb)
             and then (for all I in Index range 1 .. 3 => Peek (Va (I)).V = 0)
             and then Object_Logic_Equal (Peek (Va (4)), Peek (Va (4))'Old)
             and then Object_Logic_Equal (Peek (Va (5)), Peek (Va (5))'Old)
             and then Object_Logic_Equal (Peek (Va (6)), Peek (Va (6))'Old)
             and then Object_Logic_Equal (Peek (Vb (1)), Peek (Va (1))'Old)
             and then Object_Logic_Equal (Peek (Vb (2)), Peek (Va (2))'Old)
             and then Object_Logic_Equal (Peek (Vb (3)), Peek (Va (3))'Old))
      is
      begin
         Move (Va, 1, 3, Vb, 1, 3);
         Va (1) := Create_View (0);
         Va (2) := Create_View (0);
         Va (3) := Create_View (0);
      end Transfer;
   begin
      declare
         Vs : constant not null access Readable_Array := Get_View (A);
      begin
         Slide (Vs.all);
      end;
      Assert (A (1).V = 4, "Slide through a view moved the 4th element");
      Assert (A (3).V = 6, "Slide through a view moved the 6th element");

      declare
         Va : constant not null access Readable_Array := Get_View (A);
         Vb : constant not null access Readable_Array := Get_View (B);
      begin
         Transfer (Va.all, Vb.all);
      end;
      Assert (B (1).V = 4, "Move carried the slice between views");
      Assert (B (3).V = 6, "Move carried the slice between views");
   end Test_View_Slice;

   procedure Test_Empty_Arrays is
      Source : Pointer_Array (2 .. 1);
      Target : Pointer_Array (5 .. 4);
      Vs     : View_Arrays.View_Array (2 .. 1);
      Vt     : View_Arrays.View_Array (5 .. 4);
   begin
      Pointer_Arrays.Move (Source, Target);
      Pointer_Arrays.Move (Source, 2, 1, Target, 5, 4);
      Pointer_Arrays.Relocate (Source, 2, 1, 2, 1);
      View_Arrays.Move (Vs, Vt);
      View_Arrays.Move (Vs, 2, 1, Vt, 5, 4);
      View_Arrays.Relocate (Vs, 2, 1, 2, 1);
      Assert (Target'Length = 0 and Vt'Length = 0, "Empty moves stay empty");
   end Test_Empty_Arrays;

   procedure Test_Null_And_Poisoned is
      use Pointers;
      Source : Pointer_Array (2 .. 4);
      Target : Pointer_Array (6 .. 8);
      Temp   : Pointer;
   begin
      Source (3) := Create_Pointer ((V => 1));
      Source (4) := Create_Pointer ((V => 2));
      Temp := Take (Source (4));
      Reclaim (Temp);
      Pointer_Arrays.Move (Source, Target);
      Assert (Source (2) = Null_Pointer, "Moving null leaves null");
      Assert (Target (6) = Null_Pointer, "Moving null produces null");
      Assert
        (Constant_Reference (Target (7)).V = 1, "Move slides array bounds");
      pragma Assert (Static => Is_Poisoned (Target (8)));
      pragma Assert (Static => Is_Poisoned (Source (3)));

      Pointer_Arrays.Move (Target, Source);
      Assert (Source (2) = Null_Pointer, "Null survives a second move");
      Assert
        (Constant_Reference (Source (3)).V = 1, "Move refills poisoned cells");
      pragma Assert (Static => Is_Poisoned (Source (4)));
      Reclaim (Source (3));

      Temp := Take (Source (2));
      Assert (Temp = Null_Pointer, "Taking null returns null");
      Move (Temp, Target (6));
      Assert
        (Temp = Null_Pointer and Target (6) = Null_Pointer,
         "Scalar Move preserves null");
      Reclaim (Temp);
   end Test_Null_And_Poisoned;

   procedure Test_Pointer_Overlaps is
      use Pointers;
      use Pointer_Arrays;
      A : Pointer_Array (1 .. 6);
   begin
      A (1) := Create_Pointer ((V => 1));
      A (2) := Create_Pointer ((V => 2));
      A (3) := Create_Pointer ((V => 3));
      Relocate (A, 1, 3, 2, 4);
      Assert
        (Constant_Reference (A (2)).V = 1
         and Constant_Reference (A (3)).V = 2
         and Constant_Reference (A (4)).V = 3,
         "Overlapping relocation to the right");
      pragma Assert (Static => Is_Poisoned (A (1)));

      Relocate (A, 2, 4, 1, 3);
      Relocate (A, 2, 2);
      Relocate (A, 1, 3, 1, 3);
      Assert
        (Constant_Reference (A (1)).V = 1
         and Constant_Reference (A (2)).V = 2
         and Constant_Reference (A (3)).V = 3,
         "Relocation to the left and identical ranges");
      pragma Assert (Static => Is_Poisoned (A (4)));
      Assert
        (A (5) = Null_Pointer and A (6) = Null_Pointer,
         "Relocation leaves other cells alone");
      Reclaim_Array (A (1 .. 3));
   end Test_Pointer_Overlaps;

   procedure Test_View_Overlaps is
      use Views;
      use View_Arrays;
      A : View_Array (1 .. 6) :=
        [Create_View (1), Create_View (2), Create_View (3), others => <>];
   begin
      Relocate (A, 1, 3, 2, 4);
      Assert
        (Constant_Element (A (2)).V = 1
         and Constant_Element (A (3)).V = 2
         and Constant_Element (A (4)).V = 3,
         "Overlapping view relocation to the right");
      pragma Assert (Static => Is_Poisoned (A (1)));

      Relocate (A, 2, 4, 1, 3);
      Relocate (A, 2, 2);
      Relocate (A, 1, 3, 1, 3);
      Assert
        (Constant_Element (A (1)).V = 1
         and Constant_Element (A (2)).V = 2
         and Constant_Element (A (3)).V = 3,
         "View relocation to the left and identical ranges");
      pragma
        Assert
          (Static =>
             Is_Poisoned (A (4))
             and Is_Poisoned (A (5))
             and Is_Poisoned (A (6)));
   end Test_View_Overlaps;

   procedure Test_Owning_Copy is
      use Owning_Side;
      use Owning_Side.Pointers;
      use Owning_Side.Copy_Ops;
      O : Owning_Object := (D => new Integer'(5));
      P : Pointer := Create_Copy (O);
   begin
      O.D.all := 7;
      Assert
        (Constant_Reference (P).D.all = 5,
         "Create_Copy duplicates owned data");
      declare
         C : Owning_Object := Deref (P);
      begin
         Assert (C.D.all = 5, "Deref copies owned data");
         C.D.all := 9;
         Free (C.D);
      end;
      Assert
        (Constant_Reference (P).D.all = 5,
         "Changing a dereferenced copy leaves its source alone");
      declare
         R : access Owning_Object := Reference (P);
      begin
         Free (R.D);
      end;
      Assign (P, O);
      Free (O.D);
      Assert
        (Constant_Reference (P).D.all = 7, "Assign duplicates owned data");
      Owning_Side.Reclaim (P);
      P := Create_Copy (O);
      declare
         C : Owning_Object := Deref (P);
      begin
         Assert (C.D = null, "Copying a reclaimed object preserves null");
      end;
      Owning_Side.Reclaim (P);
      Owning_Side.Reclaim (P);
   end Test_Owning_Copy;

   procedure Test_Singleton_Moves is
      use Pointers;
      Source : Pointer_Array (1 .. 1) := [1 => Create_Pointer ((V => 8))];
      Target : Pointer_Array (10 .. 10);
      Vs     : View_Arrays.View_Array (1 .. 1) := [1 => Create_View (9)];
      Vt     : View_Arrays.View_Array (10 .. 10);
   begin
      Pointer_Arrays.Move (Source, 1, 1, Target, 10, 10);
      Assert
        (Constant_Reference (Target (10)).V = 8, "Singleton pointer move");
      Reclaim (Target (10));
      View_Arrays.Move (Vs, 1, 1, Vt, 10, 10);
      Assert
        (View_Arrays.Constant_Element (Vt (10)).V = 9, "Singleton view move");
   end Test_Singleton_Moves;

begin
   Test_Pointer;
   Test_Copy_Operations;
   Test_Move;
   Test_Handles;
   Test_Pointer_Array;
   Test_Pointer_Slice;
   Test_Pointer_Array_Move;
   Test_Pointer_Move_Slice;
   Test_View_Array;
   Test_View_Array_Move;
   Test_View_Scalar;
   Test_View_Slice;
   Test_View_Create;
   Test_View_To_Object;
   Test_Empty_Arrays;
   Test_Null_And_Poisoned;
   Test_Pointer_Overlaps;
   Test_View_Overlaps;
   Test_Singleton_Moves;
   Test_Owning_Copy;
end Test;
