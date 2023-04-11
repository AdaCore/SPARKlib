--
--  Copyright (C) 2022-2023, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0
--

package body SPARK.Containers.Functional.Multisets
  with SPARK_Mode => Off
is

   ----------
   -- "<=" --
   ----------

   function "<=" (Left : Multiset; Right : Multiset) return Boolean is
     (raise Program_Error);

   ---------
   -- "=" --
   ---------

   function "=" (Left, Right : Multiset) return Boolean is
     (raise Program_Error);

   ---------
   -- Add --
   ---------

   function Add
     (Container : Multiset;
      Element   : Element_Type;
      Count     : Big_Positive) return Multiset is
     (raise Program_Error);

   function Add
     (Container : Multiset;
      Element   : Element_Type) return Multiset is
     (raise Program_Error);

   -----------------
   -- Cardinality --
   -----------------

   function Cardinality (Container : Multiset) return Big_Natural is
     (raise Program_Error);

   --------------
   -- Contains --
   --------------

   function Contains
     (Container : Multiset;
      Element   : Element_Type) return Boolean is
     (raise Program_Error);

   ------------
   -- Choose --
   ------------

   function Choose (Container : Multiset) return Element_Type is
     (raise Program_Error);

   ----------------
   -- Difference --
   ----------------

   function Difference
     (Left  : Multiset;
      Right : Multiset) return Multiset is
     (raise Program_Error);

   --------------------
   -- Empty_Multiset --
   --------------------

   function Empty_Multiset return Multiset is
     (raise Program_Error);

   ------------------
   -- Equal_Except --
   ------------------

   function Equal_Except
     (Left    : Multiset;
      Right   : Multiset;
      Element : Element_Type) return Boolean is
     (raise Program_Error);

   ------------------
   -- Intersection --
   ------------------

   function Intersection
     (Left  : Multiset;
      Right : Multiset) return Multiset
   is
     (raise Program_Error);

   ---------------
   -- Invariant --
   ---------------

   function Invariant (Container : Map; Card : Big_Natural) return Boolean is
     (raise Program_Error);

   --------------
   -- Is_Empty --
   --------------

   function Is_Empty (Container : Multiset) return Boolean is
     (raise Program_Error);

   -----------------------------------
   -- Lemma_Nb_Occurence_Equivalent --
   -----------------------------------

   procedure Lemma_Nb_Occurence_Equivalent
     (Container            : Multiset;
      Element_1, Element_2 : Element_Type)
   is null;

   ----------------------------
   -- Lemma_Sym_Intersection --
   ----------------------------

   procedure Lemma_Sym_Intersection
     (Left  : Multiset;
      Right : Multiset)
   is null;

   -------------------
   -- Lemma_Sym_Sum --
   -------------------

   procedure Lemma_Sym_Sum
     (Left  : Multiset;
      Right : Multiset)
   is null;

   ---------------------
   -- Lemma_Sym_Union --
   ---------------------

   procedure Lemma_Sym_Union
     (Left  : Multiset;
      Right : Multiset)
   is null;

   ------------------
   -- Nb_Occurence --
   ------------------

   function Nb_Occurence
     (Container : Multiset;
      Element   : Element_Type) return Big_Natural
   is (raise Program_Error);

   ----------
   -- Next --
   ----------

   function Next
     (Iterator : Iterable_Multiset; Cursor : Multiset) return Multiset
   is (raise Program_Error);

   ------------
   -- Remove --
   ------------

   function Remove
     (Container : Multiset;
      Element   : Element_Type;
      Count     : Big_Positive := 1) return Multiset is
     (raise Program_Error);

   ----------------
   -- Remove_All --
   ----------------

   function Remove_All
     (Container : Multiset;
      Element   : Element_Type) return Multiset
   is
     (raise Program_Error);

   -----------
   -- Union --
   -----------

   function Sum (Left : Multiset; Right : Multiset) return Multiset is
     (raise Program_Error);

   -----------
   -- Union --
   -----------

   function Union
     (Left  : Multiset;
      Right : Multiset) return Multiset
   is
     (raise Program_Error);

end SPARK.Containers.Functional.Multisets;
