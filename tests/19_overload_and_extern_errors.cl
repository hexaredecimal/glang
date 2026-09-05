// Feature Test 19: Overloading Restrictions and Redefinition Error Check (@EXPECT-ERROR)

extern int external_func(int a);
extern int external_func(double a); // Error: cannot overload extern function

void main() {}
