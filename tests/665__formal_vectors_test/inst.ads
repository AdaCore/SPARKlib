with Gen_Inst;

package Inst with SPARK_Mode is
   package Big_Inst is new Gen_Inst (Positive);
   subtype Small_Positive is Short_Integer range 1 .. Short_Integer'Last;
   package Small_Inst is new Gen_Inst (Small_Positive);
end Inst;
