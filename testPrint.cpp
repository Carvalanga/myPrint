#include <stdio.h>
extern "C" int myPrint(const char* fmt, ...);

int main()
{


	int a = 52;
	// myPrint("TEST 1");
	// for(int i = 0; i < 100; i++)
	// {
	// 	myPrint("d = %d | o = %o | b = %b | c = %c | a = %d", i, i, i, i, a);
	// 	printf("\n");
	// }

	// myPrint("TEST2");
	// printf("\n");
	// myPrint("%%");
	// printf("\n");

	// myPrint("TEST3");
	// printf("\n");
	myPrint("123456789ABCDF123456789ABCDFAAA  %d", a);
	printf("\n");
	return 0;
}