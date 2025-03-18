#include <stdio.h>
extern "C" int myPrint(const char* fmt, ...);

int main()
{
	// int a = 52;
	// myPrint("TEST 1");
	// for(int i = 0; i < 100; i++)
	// {
	// 	myPrint("d = %d | o = %o | b = %b | c = %c | x = %x| a = %d", i, i, i, i, i, a);
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

	const char *format = "%d\n%b\n%c\n%s\n%%\n%x\n%c\n%o\n%o\n";
    long long   par1 = 123456;
    int         par2 = 5;
    const char  par3 = 'c';
    const char *par4 = "STRING";
    long long   par5 = 0xA1B2C3DE;
    const char  par6 = 'f';
    int         par7 = -1234;
    int         par8 = 05555;

    int a = myPrint("%d\n%b\n%c\n%s\n%%\n%x\n%c\n%o\n%o\n"
                    "%d %s %x %d %% %c %b\n", par1, par2, par3,
                    par4, par5, par6, par7, par8,
                    -1, "love", 3802, 100, 33, 30);


	// int c = myPrint("%x", 20);

	return 0;
}