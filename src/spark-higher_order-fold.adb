--
--  Copyright (C) 2018-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package body SPARK.Higher_Order.Fold with SPARK_Mode is

   -----------
   -- Count --
   -----------

   package body Count is

      ------------------
      -- Count_Length --
      ------------------

      procedure Count_Length (A : Array_Type) with SPARK_Mode =>
#if SPARK_BODY_MODE="On"
          On
#else
          Off
#end if;
      is
      begin
         for I in A'Range loop
            pragma Loop_Invariant
              ((Count_Left.Acc.Fold (A, 0) (I) = Natural (I - A'First) + 1) =
               (for all K in A'First .. I =>
                     Choose (A (K))));
         end loop;
      end Count_Length;

      ----------------
      -- Count_Zero --
      ----------------

      procedure Count_Zero (A : Array_Type) with SPARK_Mode =>
#if SPARK_BODY_MODE="On"
          On
#else
          Off
#end if;
      is
      begin
         for I in A'Range loop
            pragma Loop_Invariant
              ((Count_Left.Acc.Fold (A, 0) (I) = 0) =
               (for all K in A'First .. I =>
                     not Choose (A (K))));
         end loop;
      end Count_Zero;

      ------------------
      -- Update_Count --
      ------------------

      procedure Update_Count (A1, A2 : Array_Type; I : Index_Type) with
        SPARK_Mode =>
#if SPARK_BODY_MODE="On"
          On
#else
          Off
#end if;
      is
         C : constant Integer :=
           (if (Choose (A1 (I)) and Choose (A2 (I)))
            or (not Choose (A1 (I)) and not Choose (A2 (I))) then 0
            elsif  Choose (A1 (I)) then 1
            else -1);
      begin
         for K in A1'Range loop
            pragma Loop_Invariant
              (if K < I then
                    Count_Left.Acc.Fold (A1, 0) (K) =
                    Count_Left.Acc.Fold (A2, 0) (K)
               else
                    Count_Left.Acc.Fold (A1, 0) (K) =
                    Count_Left.Acc.Fold (A2, 0) (K) + C);
         end loop;
         pragma Assert
           (Count_Left.Acc.Fold (A1, 0) (A1'Last) =
            Count_Left.Acc.Fold (A2, 0) (A1'Last) + C);
      end Update_Count;

   end Count;

   -------------
   -- Count_2 --
   -------------

   package body Count_2 is

      ------------------
      -- Count_Length --
      ------------------

      procedure Count_Length (A : Array_Type) with SPARK_Mode =>
#if SPARK_BODY_MODE="On"
          On
#else
          Off
#end if;
      is

         function Count_Length (I : Index_1; J : Index_2) return Boolean is
         --  Count_Length up to the position I, J

         ((Fold_Count.Acc.Fold (A, 0) (I, J) =
                Natural (I - A'First (1)) * A'Length (2)
              + Natural (J - A'First (2)) + 1)
             =
               ((if I > A'First (1) then
                   (for all K in A'First (1) .. I - 1 =>
                        (for all L in A'Range (2) =>
                                Choose (A (K, L)))))
                and (for all L in A'First (2) .. J =>
                        Choose (A (I, L)))))
         with Pre => I in A'Range (1) and then J in A'Range (2),
           Post => (if J = A'Last (2) then
                        Count_Length'Result = Count_Length (I));

         function Count_Length (I : Index_1) return Boolean is
         --  Count_Length up to the position I, A'Last (2)

         ((Fold_Count.Acc.Fold (A, 0) (I, A'Last (2)) =
                           Natural (I - A'First (1) + 1) * A'Length (2))
                       =
                         (for all K in A'First (1) .. I =>
                              (for all L in A'Range (2) =>
                                     Choose (A (K, L)))))
         with Pre => I in A'Range (1) and then A'Length (2) > 0,
           Post =>
             (if I = A'Last (1) then
                    Count_Length'Result =
                ((Count (A) = A'Length (1) * A'Length (2)) =
                 (for all I in A'Range (1) =>
                      (for all J in A'Range (2) => Choose (A (I, J))))));

         procedure Prove_Next (I : Index_1; J : Index_2) with
         --  Prove Count_Length in the next iteration

           Pre => I in A'Range (1) and then J in A'Range (2)
           and then
             (if J > A'First (2) then
                Count_Length (I, J - 1)
             elsif I > A'First (1) then
                Count_Length (I - 1)),
           Post => Count_Length (I, J);

         ----------------
         -- Prove_Next --
         ----------------

         procedure Prove_Next (I : Index_1; J : Index_2) is null;

      begin
         if A'Length (2) > 0 then
            for I in A'Range (1) loop
               pragma Loop_Invariant
                 (if I > A'First (1)
                  then Count_Length (I - 1));
               for J in A'Range (2) loop
                  Prove_Next (I, J);
                  pragma Loop_Invariant
                    (Count_Length (I, J));
               end loop;
            end loop;
         end if;
      end Count_Length;

      ----------------
      -- Count_Zero --
      ----------------

      procedure Count_Zero (A : Array_Type) with SPARK_Mode =>
#if SPARK_BODY_MODE="On"
          On
#else
          Off
#end if;
      is
      begin
         if A'Length (2) > 0 then
            for I in A'Range (1) loop
               pragma Loop_Invariant
                 (if I > A'First (1) then
                      (Fold_Count.Acc.Fold (A, 0) (I - 1, A'Last (2)) = 0) =
                  (for all K in A'First (1) .. I - 1 =>
                       (for all L in A'Range (2) => not Choose (A (K, L)))));
               for J in A'Range (2) loop
                  pragma Loop_Invariant
                    ((Fold_Count.Acc.Fold (A, 0) (I, J) = 0) =
                     ((if I > A'First (1) then
                            (for all K in A'First (1) .. I - 1 =>
                               (for all L in A'Range (2) =>
                                     not Choose (A (K, L)))))
                        and (for all L in A'First (2) .. J =>
                             not Choose (A (I, L)))));
               end loop;
            end loop;
         end if;
      end Count_Zero;

      ------------------
      -- Update_Count --
      ------------------

      procedure Update_Count (A1, A2 : Array_Type; I : Index_1; J : Index_2)
      with SPARK_Mode =>
#if SPARK_BODY_MODE="On"
          On
#else
          Off
#end if;
      is
         C : constant Integer :=
           (if Choose (A1 (I, J)) = Choose (A2 (I, J)) then 0
            elsif  Choose (A1 (I, J)) then 1
            else -1);

         function Update_Count (K : Index_1; L : Index_2) return Boolean is
         --  Update_Count up to the position I, J

           (if K < I or else (K = I and then L < J) then
                 Fold_Count.Acc.Fold (A1, 0) (K, L) =
                Fold_Count.Acc.Fold (A2, 0) (K, L)
            else
               Fold_Count.Acc.Fold (A1, 0) (K, L) =
                Fold_Count.Acc.Fold (A2, 0) (K, L) + C)
         with Pre => I in A1'Range (1) and then J in A1'Range (2)
           and then K in A1'Range (1) and then L in A1'Range (2)
           and then A1'First (1) = A2'First (1)
           and then A1'Last (1) = A2'Last (1)
           and then A1'First (2) = A2'First (2)
           and then A1'Last (2) = A2'Last (2);

         procedure Prove_Next (K : Index_1; L : Index_2) with
         --  Prove Update_Count in the next iteration

           Pre => I in A1'Range (1) and then J in A1'Range (2)
           and then K in A1'Range (1) and then L in A1'Range (2)
           and then A1'First (1) = A2'First (1)
           and then A1'Last (1) = A2'Last (1)
           and then A1'First (2) = A2'First (2)
           and then A1'Last (2) = A2'Last (2)
           and then
           (for all K in A1'Range (1) =>
                (for all L in A2'Range (2) =>
                   (if K /= I or else L /= J then A1 (K, L) = A2 (K, L))))
           and then
             (if L > A1'First (2) then
                Update_Count (K, L - 1)
             elsif K > A1'First (1) then
                Update_Count (K - 1, A1'Last (2))),
           Post => Update_Count (K, L);

         ----------------
         -- Prove_Next --
         ----------------

         procedure Prove_Next (K : Index_1; L : Index_2) is null;

      begin
         for K in A1'Range (1) loop
            pragma Loop_Invariant
              (if K > A1'First (1) then Update_Count (K - 1, A1'Last (2)));
            for L in A1'Range (2) loop
               Prove_Next (K, L);
               pragma Loop_Invariant (Update_Count (K, L));
            end loop;
         end loop;
      end Update_Count;
   end Count_2;

   ------------
   -- Fold_2 --
   ------------

   package body Fold_2 is

      ----------
      -- Fold --
      ----------

      function Fold (A : Array_Type; Init : Element_Out) return Element_Out
      with SPARK_Mode =>
#if SPARK_BODY_MODE="On"
          On
#else
          Off
#end if;
      is
      begin
         return R : Element_Out := Init do
            if A'Length (2) > 0 then
               for I in A'Range (1) loop
                  pragma Loop_Invariant
                    (Ind_Prop (A, R, I, A'First (2))
                     and then F (A (I, A'First (2)), R) =
                         Acc.Fold (A, Init) (I, A'First (2)));
                  for J in A'Range (2) loop
                     pragma Loop_Invariant
                       (Ind_Prop (A, R, I, J)
                        and then F (A (I, J), R) = Acc.Fold (A, Init) (I, J));
                     if J /= A'Last (2) then
                        Acc.Prove_Ind_Col (A, R, I, J);
                     elsif I /= A'Last (1) then
                        Acc.Prove_Ind_Row (A, R, I);
                     end if;

                     R := F (A (I, J), R);
                  end loop;
               end loop;
            end if;
         end return;
      end Fold;
   end Fold_2;

   ----------------
   -- Fold_2_Acc --
   ----------------

   package body Fold_2_Acc is

      ----------
      -- Fold --
      ----------

      function Fold (A : Array_Type; Init : Element_Out) return Acc_Array with
        SPARK_Mode =>
#if SPARK_BODY_MODE="On"
          On
#else
          Off
#end if;
      is
         Acc : Element_Out := Init;
      begin
         return R : Acc_Array (A'Range (1), A'Range (2)) :=
           (others => (others => Init))
         do
            for I in A'Range (1) loop
               pragma Loop_Invariant
                 (if I = A'First (1) then Acc = Init
                  else Acc = R (I - 1, A'Last (2)));
               pragma Loop_Invariant (Ind_Prop (A, Acc, I, A'First (2)));
               pragma Loop_Invariant
                 (if I > A'First (1) then
                       Ind_Prop (A, Init, A'First (1), A'First (2))
                  and then R (A'First (1), A'First (2)) =
                    F (A (A'First (1), A'First (2)), Init));
               pragma Loop_Invariant
                 (for all K in A'Range (1) =>
                      (if K < I and then K > A'First (1) then
                         Ind_Prop (A, R (K - 1, A'Last (2)), K, A'First (2))
                       and then R (K, A'First (2)) =
                         F (A (K, A'First (2)), R (K - 1, A'Last (2)))));
               pragma Loop_Invariant
                 (for all K in A'Range (1) =>
                      (for all L in A'Range (2) =>
                         (if K < I and then L > A'First (2) then
                               Ind_Prop (A, R (K, L - 1), K, L)
                          and then R (K, L) = F (A (K, L), R (K, L - 1)))));
               for J in A'Range (2) loop
                  pragma Loop_Invariant
                    (if I > A'First (1) or else J > A'First (2) then
                          Ind_Prop (A, Init, A'First (1), A'First (2))
                     and then R (A'First (1), A'First (2)) =
                       F (A (A'First (1), A'First (2)), Init));
                  pragma Loop_Invariant
                    (for all K in A'Range (1) =>
                         (if K > A'First (1) and then
                            (K < I or else (K = I and then J > A'First (2)))
                          then
                            Ind_Prop (A, R (K - 1, A'Last (2)), K, A'First (2))
                          and then R (K, A'First (2)) =
                            F (A (K, A'First (2)), R (K - 1, A'Last (2)))));
                  pragma Loop_Invariant
                    (for all K in A'Range (1) =>
                         (for all L in A'Range (2) =>
                            (if L > A'First (2) and then
                                 (K < I or else (K = I and then L < J))
                             then
                                Ind_Prop (A, R (K, L - 1), K, L)
                             and then R (K, L) = F (A (K, L), R (K, L - 1)))));
                  pragma Loop_Invariant
                    (if J /= A'First (2) then Acc = R (I, J - 1)
                     elsif I /= A'First (1) then Acc = R (I - 1, A'Last (2))
                     else Acc = Init);
                  pragma Loop_Invariant (Ind_Prop (A, Acc, I, J));
                  R (I, J) := F (A (I, J), Acc);
                  if J < A'Last (2) then
                     Prove_Ind_Col (A, Acc, I, J);
                  elsif I < A'Last (1) then
                     Prove_Ind_Row (A, Acc, I);
                  else
                     Prove_Last (A, Acc);
                  end if;
                  Acc := R (I, J);
               end loop;
            end loop;
            pragma Assert
              (for all K in A'Range (1) =>
                   (if K > A'First (1) then
                           Ind_Prop (A, R (K - 1, A'Last (2)), K, A'First (2))
                    and then R (K, A'First (2)) =
                      F (A (K, A'First (2)), R (K - 1, A'Last (2)))));
         end return;
      end Fold;

      -------------------
      -- Prove_Ind_Col --
      -------------------

      procedure Prove_Ind_Col
        (A : Array_Type; X : Element_Out; I : Index_1; J : Index_2)
      is null;

      -------------------
      -- Prove_Ind_Row --
      -------------------

      procedure Prove_Ind_Row (A : Array_Type; X : Element_Out; I : Index_1)
      is null;

      ----------------
      -- Prove_Last --
      ----------------

      procedure Prove_Last (A : Array_Type; X : Element_Out) is null;

   end Fold_2_Acc;

   ---------------
   -- Fold_Left --
   ---------------

   package body Fold_Left is

      ----------
      -- Fold --
      ----------

      function Fold (A : Array_Type; Init : Element_Out) return Element_Out
        with SPARK_Mode =>
#if SPARK_BODY_MODE="On"
          On
#else
          Off
#end if;
      is
      begin
         return R : Element_Out := Init do
            for I in A'Range loop
               pragma Loop_Invariant
                 (Ind_Prop (A, R, I)
                  and then F (A (I), R) = Acc.Fold (A, Init) (I));
               if I /= A'Last then
                  Acc.Prove_Ind (A, R, I);
               end if;
               R := F (A (I), R);
            end loop;
         end return;
      end Fold;
   end Fold_Left;

   -------------------
   -- Fold_Left_Acc --
   -------------------

   package body Fold_Left_Acc is

      ----------
      -- Fold --
      ----------

      function Fold (A : Array_Type; Init : Element_Out) return Acc_Array
        with SPARK_Mode =>
#if SPARK_BODY_MODE="On"
          On
#else
          Off
#end if;
      is
         Acc : Element_Out := Init;
      begin
         return R : Acc_Array (A'First .. A'Last) := (others => Init) do
            for I in A'Range loop
               pragma Assert (Ind_Prop (A, Acc, I));
               R (I) := F (A (I), Acc);
               pragma Loop_Invariant
                 (Ind_Prop (A, Init, A'First)
                  and then R (A'First) = F (A (A'First), Init));
               pragma Loop_Invariant
                 (for all K in A'First .. I =>
                    (if K > A'First then
                         Ind_Prop (A, R (K - 1), K)
                     and then R (K) = F (A (K), R (K - 1))));
               pragma Loop_Invariant
                    (if I = A'First then Acc = Init else Acc = R (I - 1));
               if I /= A'Last then
                  Prove_Ind (A, Acc, I);
               else
                  Prove_Last (A, Acc);
               end if;
               Acc := R (I);
            end loop;
         end return;
      end Fold;

      ---------------
      -- Prove_Ind --
      ---------------

      procedure Prove_Ind  (A : Array_Type; X : Element_Out; I : Index_Type) is
      null;

      ----------------
      -- Prove_Last --
      ----------------

      procedure Prove_Last  (A : Array_Type; X : Element_Out) is null;

   end Fold_Left_Acc;

   -----------------
   -- Fold_Left_I --
   -----------------

   package body Fold_Left_I is

      ----------
      -- Fold --
      ----------

      function Fold (A : Array_Type; Init : Element_Out) return Element_Out
        with SPARK_Mode =>
#if SPARK_BODY_MODE="On"
          On
#else
          Off
#end if;
      is
      begin
         return R : Element_Out := Init do
            for I in A'Range loop
               pragma Loop_Invariant
                 (Ind_Prop (A, R, I)
                  and then F (A (I), I, R) = Acc.Fold (A, Init) (I));
               if I /= A'Last then
                  Acc.Prove_Ind (A, R, I);
               end if;
               R := F (A (I), I, R);
            end loop;
         end return;
      end Fold;
   end Fold_Left_I;

   ---------------------
   -- Fold_Left_I_Acc --
   ---------------------

   package body Fold_Left_I_Acc is

      ----------
      -- Fold --
      ----------

      function Fold (A : Array_Type; Init : Element_Out) return Acc_Array
        with SPARK_Mode =>
#if SPARK_BODY_MODE="On"
          On
#else
          Off
#end if;
      is
         Acc : Element_Out := Init;
      begin
         return R : Acc_Array (A'First .. A'Last) := (others => Init) do
            for I in A'Range loop
               pragma Assert (Ind_Prop (A, Acc, I));
               R (I) := F (A (I), I, Acc);
               pragma Loop_Invariant
                 (Ind_Prop (A, Init, A'First)
                  and then R (A'First) = F (A (A'First), A'First, Init));
               pragma Loop_Invariant
                 (for all K in A'First .. I =>
                    (if K > A'First then
                         Ind_Prop (A, R (K - 1), K)
                     and then R (K) = F (A (K), K, R (K - 1))));
               pragma Loop_Invariant
                    (if I = A'First then Acc = Init else Acc = R (I - 1));
               if I /= A'Last then
                  Prove_Ind (A, Acc, I);
               else
                  Prove_Last (A, Acc);
               end if;
               Acc := R (I);
            end loop;
         end return;
      end Fold;

      ---------------
      -- Prove_Ind --
      ---------------

      procedure Prove_Ind  (A : Array_Type; X : Element_Out; I : Index_Type) is
      null;

      ----------------
      -- Prove_Last --
      ----------------

      procedure Prove_Last  (A : Array_Type; X : Element_Out) is null;

   end Fold_Left_I_Acc;

   ----------------
   -- Fold_Right --
   ----------------

   package body Fold_Right is

      ----------
      -- Fold --
      ----------

      function Fold (A : Array_Type; Init : Element_Out) return Element_Out
        with SPARK_Mode =>
#if SPARK_BODY_MODE="On"
          On
#else
          Off
#end if;
      is
      begin
         return R : Element_Out := Init do
            for I in reverse A'Range loop
               pragma Loop_Invariant
                 (Ind_Prop (A, R, I)
                  and then F (A (I), R) = Acc.Fold (A, Init) (I));
               if I /= A'First then
                  Acc.Prove_Ind (A, R, I);
               end if;
               R := F (A (I), R);
            end loop;
         end return;
      end Fold;
   end Fold_Right;

   --------------------
   -- Fold_Right_Acc --
   --------------------

   package body Fold_Right_Acc is

      ----------
      -- Fold --
      ----------

      function Fold (A : Array_Type; Init : Element_Out) return Acc_Array
        with SPARK_Mode =>
#if SPARK_BODY_MODE="On"
          On
#else
          Off
#end if;
      is
         Acc : Element_Out := Init;
      begin
         return R : Acc_Array (A'First .. A'Last) := (others => Init) do
            for I in reverse A'Range loop
               pragma Assert (Ind_Prop (A, Acc, I));
               R (I) := F (A (I), Acc);
               pragma Loop_Invariant
                 (Ind_Prop (A, Init, A'Last)
                  and then R (A'Last) = F (A (A'Last), Init));
               pragma Loop_Invariant
                 (for all K in I .. A'Last =>
                    (if K < A'Last then
                         Ind_Prop (A, R (K + 1), K)
                     and then R (K) = F (A (K), R (K + 1))));
               pragma Loop_Invariant
                    (if I = A'Last then Acc = Init else Acc = R (I + 1));
               if I /= A'First then
                  Prove_Ind (A, Acc, I);
               else
                  Prove_Last (A, Acc);
               end if;
               Acc := R (I);
            end loop;
         end return;
      end Fold;

      ---------------
      -- Prove_Ind --
      ---------------

      procedure Prove_Ind (A : Array_Type; X : Element_Out; I : Index_Type) is
      null;

      ----------------
      -- Prove_Last --
      ----------------

      procedure Prove_Last  (A : Array_Type; X : Element_Out) is null;

   end Fold_Right_Acc;

   ---------
   -- Sum --
   ---------

   package body Sum is

      ---------------------
      -- Big_Integer_Sum --
      ---------------------

      package body Big_Integer_Sum is

         -------------
         -- Sum_Cst --
         -------------

         procedure Sum_Cst (A : Array_Type; C : Element_Out) with SPARK_Mode =>
#if SPARK_BODY_MODE="On"
             On
#else
             Off
#end if;
         is
         begin
            for I in A'Range loop
               if Value (A (I)) /= C then
                  return;
               end if;
               pragma Loop_Invariant
                 (Sum_Left.Acc.Fold (A, 0) (I) =
                      To_Big (C) * (To_Big_I (I) - To_Big_I (A'First))
                  + To_Big (C));
               pragma Loop_Invariant
                 (for all K in A'First .. I => Value (A (K)) = C);
            end loop;
         end Sum_Cst;

         ----------------
         -- Update_Sum --
         ----------------

         procedure Update_Sum (A1, A2 : Array_Type; I : Index_Type) with
           SPARK_Mode =>
#if SPARK_BODY_MODE="On"
               On
#else
               Off
#end if;
         is

         begin
            for K in A1'Range loop
               pragma Loop_Invariant
                 (if K < I then
                     Sum_Left.Acc.Fold (A1, 0) (K) =
                      Sum_Left.Acc.Fold (A2, 0) (K)
                  else
                     Sum_Left.Acc.Fold (A1, 0) (K) - To_Big (Value (A1 (I))) =
                      Sum_Left.Acc.Fold (A2, 0) (K) - To_Big (Value (A2 (I))));
            end loop;

            pragma Assert
              (Sum_Left.Acc.Fold (A1, 0) (A1'Last) - To_Big (Value (A1 (I))) =
                   Sum_Left.Acc.Fold (A2, 0) (A1'Last) -
                     To_Big (Value (A2 (I))));
         end Update_Sum;
      end Big_Integer_Sum;

      ---------------
      -- Prove_Add --
      ---------------

      procedure Prove_Add (Left, Right : Element_Out) is null;

      ----------------
      -- Prove_Zero --
      ----------------

      procedure Prove_Zero is null;

      ---------
      -- Sum --
      ---------

      function Sum (A : Array_Type) return Element_Out with
        SPARK_Mode =>
#if SPARK_BODY_MODE="On"
             On
#else
             Off
#end if;
      is
         R : Element_Out := Zero;
      begin
         Prove_Zero;
         for I in A'Range loop
            pragma Loop_Invariant (No_Overflows (A, R, I));
            pragma Loop_Invariant
              (if I = A'First then To_Big (R) = 0
               else To_Big (R) =
                   Big_Integer_Sum.Sum_Left.Acc.Fold (A, 0) (I - 1));
            Prove_Add (R, Value (A (I)));
            R := R + Value (A (I));
         end loop;
         return R;
      end Sum;

   end Sum;

   -----------
   -- Sum_2 --
   -----------

   package body Sum_2 is

      ---------------------
      -- Big_Integer_Sum --
      ---------------------

      package body Big_Integer_Sum is

         -------------
         -- Sum_Cst --
         -------------

         procedure Sum_Cst (A : Array_Type; C : Element_Out) with SPARK_Mode =>
#if SPARK_BODY_MODE="On"
             On
#else
             Off
#end if;
         is
            function Sum_Cst (I : Index_1; J : Index_2) return Boolean is
              (Fold_Sum.Acc.Fold (A, 0) (I, J) =
                   To_Big (C) *
                     ((To_Big_1 (I) - To_Big_1 (A'First (1))) * Length_2 (A) +
                      (To_Big_2 (J) - To_Big_2 (A'First (2)))) + To_Big (C))
              with Pre => I in A'Range (1) and then J in A'Range (2);
            --  The property we want to show at position I, J

         begin
            if A'Length (2) > 0 then
               for I in A'Range (1) loop
                  pragma Loop_Invariant
                    (I = A'First (1) or else
                         (for all K in A'First (1) .. I - 1 =>
                            (for all L in A'Range (2) =>
                                 Value (A (K, L)) = C)));
                  pragma Loop_Invariant
                    (I = A'First (1) or else Sum_Cst (I - 1, A'Last (2)));
                  for J in A'Range (2) loop
                     if Value (A (I, J)) /= C then
                        return;
                     end if;
                     pragma Loop_Invariant (Sum_Cst (I, J));
                     pragma Loop_Invariant
                       (for all L in A'First (2) .. J => Value (A (I, L)) = C);
                  end loop;
               end loop;
            end if;
         end Sum_Cst;

         ----------------
         -- Update_Sum --
         ----------------

         procedure Update_Sum (A1, A2 : Array_Type; I : Index_1; J : Index_2)
         with
           SPARK_Mode =>
#if SPARK_BODY_MODE="On"
               On
#else
               Off
#end if;
         is
         begin
            for K in A1'Range (1) loop
               pragma Loop_Invariant
                 (if K < I  or else (K = I and then A1'First (2) < J) then
                     Fold_Sum.Acc.Fold (A1, 0) (K, A1'First (2)) =
                     Fold_Sum.Acc.Fold (A2, 0) (K, A1'First (2))
                  else
                     Fold_Sum.Acc.Fold (A1, 0) (K, A1'First (2)) -
                      To_Big (Value (A1 (I, J))) =
                     Fold_Sum.Acc.Fold (A2, 0) (K, A1'First (2)) -
                      To_Big (Value (A2 (I, J))));
               for L in A1'Range (2) loop
                  if K /= I or else L /= J then
                     pragma Assert (Value (A1 (K, L)) = Value (A2 (K, L)));
                  end if;
                  pragma Loop_Invariant
                    (if K < I or else (K = I and then L < J) then
                        Fold_Sum.Acc.Fold (A1, 0) (K, L) =
                        Fold_Sum.Acc.Fold (A2, 0) (K, L)
                     else
                        Fold_Sum.Acc.Fold (A1, 0) (K, L) -
                         To_Big (Value (A1 (I, J))) =
                        Fold_Sum.Acc.Fold (A2, 0) (K, L) -
                         To_Big (Value (A2 (I, J))));
               end loop;
            end loop;

            pragma Assert
              (Fold_Sum.Acc.Fold (A1, 0) (A1'Last (1), A1'Last (2)) -
                   To_Big (Value (A1 (I, J))) =
               Fold_Sum.Acc.Fold (A2, 0) (A1'Last (1), A1'Last (2)) -
                   To_Big (Value (A2 (I, J))));
         end Update_Sum;

      end Big_Integer_Sum;

      ---------------
      -- Prove_Add --
      ---------------

      procedure Prove_Add (Left, Right : Element_Out) is null;

      ----------------
      -- Prove_Zero --
      ----------------

      procedure Prove_Zero is null;

      ---------
      -- Sum --
      ---------

      function Sum (A : Array_Type) return Element_Out with
        SPARK_Mode =>
#if SPARK_BODY_MODE="On"
             On
#else
             Off
#end if;
      is
         R : Element_Out := Zero;
      begin
         Prove_Zero;
         if A'Length (2) = 0 then
            return R;
         end if;

         for I in A'Range (1) loop
            pragma Loop_Invariant (No_Overflows (A, R, I, A'First (2)));
            pragma Loop_Invariant
              (if I = A'First (1) then To_Big (R) = 0
               else To_Big (R) =
                   Big_Integer_Sum.Fold_Sum.Acc.Fold (A, 0)
                      (I - 1, A'Last (2)));
            for J in A'Range (2) loop
               pragma Loop_Invariant (No_Overflows (A, R, I, J));
               pragma Loop_Invariant
                 (if I = A'First (1) and J = A'First (2) then To_Big (R) = 0
                  elsif J = A'First (2)
                  then To_Big (R) =
                      Big_Integer_Sum.Fold_Sum.Acc.Fold (A, 0)
                         (I - 1, A'Last (2))
                  else To_Big (R) =
                      Big_Integer_Sum.Fold_Sum.Acc.Fold (A, 0) (I, J - 1));
               Prove_Add (R, Value (A (I, J)));
               R := R + Value (A (I, J));
            end loop;
         end loop;
         return R;
      end Sum;

   end Sum_2;

end SPARK.Higher_Order.Fold;
