--  Copyright (C) 2004-2024, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package body SPARK.Containers.Formal.Hash_Tables.Prime_Numbers is

   --------------
   -- To_Prime --
   --------------

   function To_Prime (Length : Count_Type) return Hash_Type is
      I, J, K : Integer'Base;
      Index   : Integer'Base;

   begin
      I := Primes'Last - Primes'First;
      Index := Primes'First;
      while I > 0 loop
         J := I / 2;
         K := Index + J;

         if Primes (K) < Hash_Type (Length) then
            Index := K + 1;
            I := I - J - 1;
         else
            I := J;
         end if;
      end loop;

      return Primes (Index);
   end To_Prime;

end SPARK.Containers.Formal.Hash_Tables.Prime_Numbers;
