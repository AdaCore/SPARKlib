--
--  Copyright (C) 2004-2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Hash_Table_Type is used to implement hashed containers. This package
--  declares hash-table operations that do not depend on keys.

pragma Ada_2022;

generic
   with package HT_Types is new Generic_Hash_Table_Types (<>);

   use HT_Types;

   with function Hash_Node (Node : Node_Type) return Hash_Type;

   with function Next (Node : Node_Type) return Count_Type;

   with procedure Set_Next (Node : in out Node_Type; Next : Count_Type);

package SPARK.Containers.Formal.Hash_Tables.Generic_Operations
is
   pragma Pure;

   function Index (Buckets : Buckets_Type; Node : Node_Type) return Hash_Type;
   pragma Inline (Index);
   --  Uses the hash value of Node to compute its Buckets array index

   function Index (HT : Hash_Table_Type; Node : Node_Type) return Hash_Type;
   pragma Inline (Index);
   --  Uses the hash value of Node to compute its Hash_Table buckets array
   --  index.

   generic
      with
        function Find (HT : Hash_Table_Type; Key : Node_Type) return Boolean;
   function Generic_Equal (L, R : Hash_Table_Type) return Boolean;
   --  Used to implement hashed container equality. For each node in hash table
   --  L, it calls Find to search for an equivalent item in hash table R. If
   --  Find returns False for any node then Generic_Equal terminates
   --  immediately and returns False. Otherwise if Find returns True for every
   --  node then Generic_Equal returns True.

   procedure Clear (HT : in out Hash_Table_Type);
   --  Empties the hash table HT

   procedure Delete_Node_Sans_Free
     (HT : in out Hash_Table_Type; X : Count_Type);
   --  Removes node X from the hash table without deallocating the node

   generic
      with procedure Set_Element (Node : in out Node_Type);
   procedure Generic_Allocate
     (HT : in out Hash_Table_Type; Node : out Count_Type);
   --  Claim a node from the free store. Generic_Allocate first
   --  calls Set_Element on the potential node, and then returns
   --  the node's index as the value of the Node parameter.

   procedure Free (HT : in out Hash_Table_Type; X : Count_Type);
   --  Return a node back to the free store, from where it had
   --  been previously claimed via Generic_Allocate.

   function First (HT : Hash_Table_Type) return Count_Type;
   --  Returns the head of the list in the first (lowest-index) non-empty
   --  bucket.

   function Next (HT : Hash_Table_Type; Node : Count_Type) return Count_Type;
   --  Returns the node that immediately follows Node. This corresponds to
   --  either the next node in the same bucket, or (if Node is the last node in
   --  its bucket) the head of the list in the first non-empty bucket that
   --  follows.

   generic
      with procedure Process (Node : Count_Type);
   procedure Generic_Iteration (HT : Hash_Table_Type);
   --  Calls Process for each node in hash table HT

end SPARK.Containers.Formal.Hash_Tables.Generic_Operations;
