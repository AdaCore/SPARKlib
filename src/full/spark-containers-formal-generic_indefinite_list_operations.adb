--
--  Copyright (C) 2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with Ada.Unchecked_Deallocation;

package body SPARK.Containers.Formal.Generic_Indefinite_List_Operations
  with SPARK_Mode
is

   -------------------
   -- Copy_Elements --
   -------------------

   procedure Copy_Elements
     (Target : in out Elements_Array;
      Source : Elements_Array;
      Nodes  : Node_Array;
      Free   : Count_Type'Base) is
   begin
      for I in Source'Range loop
         if (Free >= 0 or else I <= -(Free + 1)) and then Nodes (I).Prev /= -1
         then
            Target (I) :=
              Copies.Create_Copy (Constant_Access (Source (I)).all);
         end if;

         pragma
           Loop_Invariant
             (Static =>
                (for all J in Target'Range =>
                   (if J <= I
                      and then (Free >= 0 or else J <= -(Free + 1))
                      and then Nodes (J).Prev /= -1
                    then Is_Initialized (Target (J))
                    else Cells.Is_Reclaimed (Target (J)))));
      end loop;
   end Copy_Elements;

   --------------
   -- Exchange --
   --------------

   procedure Exchange (Elements : in out Elements_Array; I, J : Count_Type) is
      Tmp : Cells.Pointer;
   begin
      Cells.Move (Elements (I), Tmp);
      Arrays.Relocate (Elements, J, I);
      Cells.Move (Tmp, Elements (J));
   end Exchange;

   ----------
   -- Fill --
   ----------

   procedure Fill (H : out Cells.Pointer; Item : Element_Type) is
   begin
      H := Copies.Create_Copy (Item);
   end Fill;

   ------------------
   -- New_Capacity --
   ------------------

   function New_Capacity (Capacity, Size : Count_Type) return Count_Type is
      Result : Count_Type := (if Capacity = 0 then 100 else Capacity);
   begin
      while Result < Size loop
         pragma Loop_Invariant (Static => Result >= Capacity);
         pragma Loop_Invariant (Static => Result > 0);
         pragma
           Loop_Variant (Static => (Decreases => Count_Type'Last - Result));
         Result :=
           (if Result > Count_Type'Last / 2
            then Count_Type'Last
            else Count_Type'Max (100, 2 * Result));
      end loop;
      return Count_Type'Max (100, Result);
   end New_Capacity;

   ------------
   -- Resize --
   ------------

   procedure Resize
     (Nodes    : in out Node_Array_Access;
      Elements : in out Elements_Array_Access;
      Free     : in out Count_Type'Base;
      Size     : Count_Type)
   is
      procedure Free_Nodes is new
        Ada.Unchecked_Deallocation (Node_Array, Node_Array_Access);
      procedure Free_Elements is new
        Ada.Unchecked_Deallocation (Elements_Array, Elements_Array_Access);

      Capacity     : constant Count_Type :=
        (if Nodes = null then 0 else Nodes'Length);
      New_Size     : constant Count_Type := New_Capacity (Capacity, Size);
      --  The separate allocations have no cleanup on Storage_Error: failure
      --  of the second can leak the first. This is accepted because recovery
      --  from Storage_Error is not supported. Existing storage is untouched
      --  until both allocations succeed.
      New_Nodes    : constant Node_Array_Access :=
        new Node_Array'(1 .. New_Size => (Prev => -1, Next => 0));
      New_Elements : constant Elements_Array_Access :=
        new Elements_Array (1 .. New_Size);
   begin
      if Nodes /= null then
         New_Nodes (1 .. Capacity) := Nodes.all;
         Arrays.Move (Elements.all, New_Elements (1 .. Capacity));

         if Free >= 0 then
            for I in Capacity + 1 .. New_Size loop
               New_Nodes (I).Prev := -1;
               New_Nodes (I).Next := (if I = New_Size then Free else I + 1);
               pragma
                 Loop_Invariant
                   (Static =>
                      (for all J in Capacity + 1 .. I =>
                         New_Nodes (J).Prev'Initialized
                         and then New_Nodes (J).Next'Initialized
                         and then New_Nodes (J).Prev = -1
                         and then
                           New_Nodes (J).Next
                           = (if J = New_Size then Free else J + 1)));
            end loop;
            Free := Capacity + 1;
         end if;

         Free_Elements (Elements);
         Free_Nodes (Nodes);
      end if;
      Nodes := New_Nodes;
      Elements := New_Elements;
   end Resize;

end SPARK.Containers.Formal.Generic_Indefinite_List_Operations;
