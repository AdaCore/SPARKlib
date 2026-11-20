--
--  Copyright (C) 2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with Ada.Unchecked_Deallocation;

package body SPARK.Containers.Formal.Generic_Indefinite_Vector_Operations
  with SPARK_Mode
is
   --  The minimum size of the underlying array to avoid too much resizing
   Min_Size : constant Capacity_Range :=
     Count_Type'Min (100, Capacity_Range'Last);

   ---------------------
   -- Constant_Access --
   ---------------------

   function Constant_Access
     (H : aliased Cells.Pointer) return not null access constant Element_Type
   is (Cells.Constant_Reference (H));

   ----------
   -- Copy --
   ----------

   procedure Copy (Target : in out Elements_Array; Source : Elements_Array) is
   begin
      --  Clear moved-from pointers before allocation can fail
      Target := (others => <>);

      for I in Target'Range loop
         pragma
           Loop_Invariant
             (Static =>
                (for all J in Target'Range =>
                   (if J < I
                    then Is_Initialized (Target (J))
                    else Is_Reclaimed (Target (J)))));
         Target (I) :=
           Values.Create_Copy
             (Constant_Access
                (Source (Source'First + (I - Target'First))).all);
      end loop;
   end Copy;

   --------------
   -- Exchange --
   --------------

   procedure Exchange (E : in out Elements_Array; I, J : Count_Type'Base) is
   begin
      if I = J then
         return;
      end if;

      declare
         Tmp : Cells.Pointer;
      begin
         Cells.Move (E (I), Tmp);
         Arrays.Relocate (E, Array_Index (J), Array_Index (I));
         Cells.Move (Tmp, E (J));
      end;
   end Exchange;

   ----------
   -- Fill --
   ----------

   procedure Fill (H : out Cells.Pointer; Item : Element_Type) is
   begin
      H := Values.Create_Copy (Item);
   end Fill;

   procedure Fill (E : in out Elements_Array; Item : Element_Type) is
   begin
      --  Clear moved-from pointers before allocation can fail
      E := (others => <>);

      for I in E'Range loop
         pragma
           Loop_Invariant
             (Static =>
                (for all J in E'Range =>
                   (if J < I
                    then Is_Initialized (E (J))
                    else Is_Reclaimed (E (J)))));
         Fill (E (I), Item);
      end loop;
   end Fill;

   ------------------
   -- New_Capacity --
   ------------------

   function New_Capacity
     (Capacity, Size : Capacity_Range) return Capacity_Range
   is
      New_Length : constant Capacity_Range :=
        (if Capacity < Capacity_Range'Last / 2
         then (if Capacity * 2 < Size then Size else Capacity * 2)
         else Capacity_Range'Last);
   begin
      return Count_Type'Max (Min_Size, New_Length);
   end New_Capacity;

   -------------
   -- Reclaim --
   -------------

   procedure Reclaim (E : in out Elements_Array; First, Last : Count_Type'Base)
   is
      Initial : constant Elements_Array := Arrays.Copy (E)
      with Ghost => Static;
   begin
      for I in First .. Last loop
         --  The reclaimed prefix owns nothing; other cell states are preserved
         pragma
           Loop_Invariant
             (Static =>
                (for all J in E'Range =>
                   (if J in First .. I - 1
                    then Is_Reclaimed (E (J))
                    else
                      Is_Initialized (E (J)) = Is_Initialized (Initial (J))
                      and then
                        Is_Reclaimed (E (J)) = Is_Reclaimed (Initial (J)))));
         Cells.Reclaim (E (I));
      end loop;
   end Reclaim;

   ------------
   -- Resize --
   ------------

   procedure Resize
     (E    : in out Elements_Array_Access;
      Last : Extended_Index;
      Size : Capacity_Range := 0)
   is
      procedure Free is new
        Ada.Unchecked_Deallocation (Elements_Array, Elements_Array_Access);

      New_Array : constant Elements_Array_Access :=
        new Elements_Array
              (1 .. New_Capacity ((if E = null then 0 else E'Length), Size));
   begin
      if E /= null then
         declare
            Length : constant Count_Type := To_Array_Index (Last);
         begin
            Arrays.Move (E (1 .. Length), New_Array (1 .. Length));
         end;
         Free (E);
      end if;
      E := New_Array;
   end Resize;

end SPARK.Containers.Formal.Generic_Indefinite_Vector_Operations;
