#include <stdio.h>
extern "C" int myPrint(const char* fmt, ...);

int main()
{
	int a = 52;
	// myPrint("TEST 1");
	// for(int i = 0; i < 100; i++)
	// {
		myPrint("d = %d | o = %o | b = %b | c = %c | x = %x| a = %d", 1, 2, 3, 4, 5, 31);
	// 	printf("\n");
	// }

	// myPrint("TEST2 (%%)");
	// printf("\n");

	// myPrint("TEST3 (OVERFLOW)");
	// printf("\n");
	// myPrint("123456789ABCDF123456789ABCDFAAA  %d", a);
	// printf("\n");

	// char test4[] = "test4";
	// myPrint("%c = %s!", a, test4);
	return 0;
}