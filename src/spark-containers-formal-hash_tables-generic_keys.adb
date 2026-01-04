--  Copyright (C) 2004-2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

package body SPARK.Containers.Formal.Hash_Tables.Generic_Keys is

   Checks : constant Boolean := Container_Checks'Enabled;

   --------------------------
   -- Delete_Key_Sans_Free --
   --------------------------

   procedure Delete_Key_Sans_Free
     (HT : in out Hash_Table_Type; Key : Key_Type; X : out Count_Type)
   is
      Indx : Hash_Type;
      Prev : Count_Type;

   begin
      if HT.Length = 0 then
         X := 0;
         return;
      end if;

      Indx := Index (HT, Key);
      X := HT.Buckets (Indx);

      if X = 0 then
         return;
      end if;

      if Equivalent_Keys (Key, HT.Nodes (X)) then
         HT.Buckets (Indx) := Next (HT.Nodes (X));
         HT.Length := HT.Length - 1;
         return;
      end if;

      loop
         Prev := X;
         X := Next (HT.Nodes (Prev));

         if X = 0 then
            return;
         end if;

         if Equivalent_Keys (Key, HT.Nodes (X)) then
            Set_Next (HT.Nodes (Prev), Next => Next (HT.Nodes (X)));
            HT.Length := HT.Length - 1;
            return;
         end if;
      end loop;
   end Delete_Key_Sans_Free;

   ----------
   -- Find --
   ----------

   function Find (HT : Hash_Table_Type; Key : Key_Type) return Count_Type is
      Indx : Hash_Type;
      Node : Count_Type;

   begin
      if HT.Length = 0 then
         return 0;
      end if;

      Indx := Index (HT, Key);

      Node := HT.Buckets (Indx);
      while Node /= 0 loop
         if Equivalent_Keys (Key, HT.Nodes (Node)) then
            return Node;
         end if;
         Node := Next (HT.Nodes (Node));
      end loop;

      return 0;
   end Find;

   --------------------------------
   -- Generic_Conditional_Insert --
   --------------------------------

   procedure Generic_Conditional_Insert
     (HT       : in out Hash_Table_Type;
      Key      : Key_Type;
      Node     : out Count_Type;
      Inserted : out Boolean)
   is
      Indx : Hash_Type;

   begin
      Indx := Index (HT, Key);
      Node := HT.Buckets (Indx);

      if Node = 0 then
         if Checks and then HT.Length = HT.Capacity then
            raise Capacity_Error with "no more capacity for insertion";
         end if;

         New_Node (HT, Node);
         Set_Next (HT.Nodes (Node), Next => 0);

         Inserted := True;

         HT.Buckets (Indx) := Node;
         HT.Length := HT.Length + 1;

         return;
      end if;

      loop
         if Equivalent_Keys (Key, HT.Nodes (Node)) then
            Inserted := False;
            return;
         end if;

         Node := Next (HT.Nodes (Node));

         exit when Node = 0;
      end loop;

      if Checks and then HT.Length = HT.Capacity then
         raise Capacity_Error with "no more capacity for insertion";
      end if;

      New_Node (HT, Node);
      Set_Next (HT.Nodes (Node), Next => HT.Buckets (Indx));

      Inserted := True;

      HT.Buckets (Indx) := Node;
      HT.Length := HT.Length + 1;
   end Generic_Conditional_Insert;

   -----------------------------
   -- Generic_Replace_Element --
   -----------------------------

   procedure Generic_Replace_Element
     (HT : in out Hash_Table_Type; Node : Count_Type; Key : Key_Type)
   is
      pragma Assert (HT.Length > 0);
      pragma Assert (Node /= 0);

      BB : Buckets_Type renames HT.Buckets;
      NN : Nodes_Type renames HT.Nodes;

      Old_Indx : Hash_Type;
      New_Indx : constant Hash_Type := Index (HT, Key);

      New_Bucket : Count_Type renames BB (New_Indx);
      N, M       : Count_Type;

   begin
      Old_Indx := HT.Buckets'First + Hash (NN (Node)) mod HT.Buckets'Length;

      --  Replace_Element is allowed to change a node's key to Key
      --  (generic formal operation Assign provides the mechanism), but
      --  only if Key is not already in the hash table. (In a unique-key
      --  hash table as this one, a key is mapped to exactly one node.)

      if Equivalent_Keys (Key, NN (Node)) then
         --  The new Key value is mapped to this same Node, so Node
         --  stays in the same bucket.

         Assign (NN (Node), Key);
         return;
      end if;

      --  Key is not equivalent to Node, so we now have to determine if it's
      --  equivalent to some other node in the hash table. This is the case
      --  irrespective of whether Key is in the same or a different bucket from
      --  Node.

      N := New_Bucket;
      while N /= 0 loop
         if Checks and then Equivalent_Keys (Key, NN (N)) then
            pragma Assert (N /= Node);
            raise Program_Error with "attempt to replace existing element";
         end if;

         N := Next (NN (N));
      end loop;

      --  We have determined that Key is not already in the hash table, so
      --  the change is allowed.

      if Old_Indx = New_Indx then
         --  The node is already in the bucket implied by Key. In this case
         --  we merely change its value without moving it.

         Assign (NN (Node), Key);
         return;
      end if;

      --  The node is in a bucket different from the bucket implied by Key.
      --  Do the assignment first, before moving the node, so that if Assign
      --  propagates an exception, then the hash table will not have been
      --  modified (except for any possible side-effect Assign had on Node).

      Assign (NN (Node), Key);

      --  Now we can safely remove the node from its current bucket

      N := BB (Old_Indx);  -- get value of first node in old bucket
      pragma Assert (N /= 0);

      if N = Node then
         --  node is first node in its bucket
         BB (Old_Indx) := Next (NN (Node));

      else
         pragma Assert (HT.Length > 1);

         loop
            M := Next (NN (N));
            pragma Assert (M /= 0);

            if M = Node then
               Set_Next (NN (N), Next => Next (NN (Node)));
               exit;
            end if;

            N := M;
         end loop;
      end if;

      --  Now we link the node into its new bucket (corresponding to Key)

      Set_Next (NN (Node), Next => New_Bucket);
      New_Bucket := Node;
   end Generic_Replace_Element;

   -----------
   -- Index --
   -----------

   function Index (HT : Hash_Table_Type; Key : Key_Type) return Hash_Type is
   begin
      return HT.Buckets'First + Hash (Key) mod HT.Buckets'Length;
   end Index;

end SPARK.Containers.Formal.Hash_Tables.Generic_Keys;
