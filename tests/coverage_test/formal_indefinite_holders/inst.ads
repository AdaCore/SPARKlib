with Gen_Inst;
with Shapes; use Shapes;

package Inst with SPARK_Mode is
   package String_Inst is new Gen_Inst (String, "=");
   package Shape_Inst is new Gen_Inst (Shape'Class, Same_Position);

   function String_Value (N : Positive) return String is
     (case N is
        when 1 => "abc",
        when 2 => "longer string",
        when others => "xyz");

   function Same_String (Left, Right : String) return Boolean is
     (Left'First = Right'First and then Left'Last = Right'Last
      and then Left = Right);

   function Shape_Value (N : Positive) return Shape'Class is
     (case N is
        when 1 => Circle'(X => 1, Y => 2, Radius => 3),
        when 2 => Shape'(X => 1, Y => 2),
        when others => Circle'(X => 4, Y => 5, Radius => 6));

   function Same_Shape (Left, Right : Shape'Class) return Boolean is
     ((Left in Circle) = (Right in Circle)
      and then Left.X = Right.X and then Left.Y = Right.Y
      and then (if Left in Circle
                then Circle (Left).Radius = Circle (Right).Radius));
end Inst;
