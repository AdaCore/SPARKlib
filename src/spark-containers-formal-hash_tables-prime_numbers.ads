--  Copyright (C) 2004-2025, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This package declares the prime numbers array used to implement hashed
--  containers. Bucket arrays are always allocated with a prime-number
--  length (computed using To_Prime below), as this produces better scatter
--  when hash values are folded.

pragma Ada_2022;

package SPARK.Containers.Formal.Hash_Tables.Prime_Numbers is
   pragma Pure;

   type Primes_Type is array (Positive range <>) of Hash_Type;

   Primes : constant Primes_Type :=
     [53,
      97,
      193,
      389,
      769,
      1543,
      3079,
      6151,
      12289,
      24593,
      49157,
      98317,
      196613,
      393241,
      786433,
      1572869,
      3145739,
      6291469,
      12582917,
      25165843,
      50331653,
      100663319,
      201326611,
      402653189,
      805306457,
      1610612741,
      3221225473,
      4294967291];

   function To_Prime (Length : Count_Type) return Hash_Type;
   --  Returns the smallest value in Primes not less than Length

end SPARK.Containers.Formal.Hash_Tables.Prime_Numbers;
