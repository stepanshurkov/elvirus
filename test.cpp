//Упаковщик файлов

#include <stdio.h>

int main() {
    FILE *f12;
    FILE *f1;
    FILE *f2;
    if((f12=fopen("time.pkg","wb+"))==NULL) {
                                           printf("Error\n");
                                           return 1;
                                           }
    if((f1=fopen("loader.bin","rb+"))==NULL) {
                                            printf("Error\n");
                                            return 1;
                                            }
    if((f2=fopen("dd.exe","rb+"))==NULL) {
                                        printf("Error\n");
                                        return 1;
                                        }
    char lol;
    while (!feof(f1)) {
           lol=getc(f1);
           if (!feof(f1)) {
           fputc(lol,f12);
           }
	}
    fclose(f1);
    while (!feof(f2)) {
           lol=getc(f2);
           if (!feof(f2)) {
           fputc(lol,f12);
           }
	}
    fclose(f2);
    fclose(f12);
    return 0;
}
