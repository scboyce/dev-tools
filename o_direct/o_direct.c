#define _GNU_SOURCE
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
int main(int argc, char *argv[])
{
   int ret;
     // create file
        ret=open(argv[1], O_RDWR|O_CREAT|O_EXCL, 0600);
        if ( ret < 0 ) {
           perror("ERROR:");
           printf("errno creating= %d.\n", errno);
           return ret;
        }
     // open file with O_DIRECT flag
      ret=open(argv[1], O_RDWR|O_CREAT|O_DIRECT,0664);
      if ( ret < 0 ) {
        printf("errno = %d.\n", errno);
      } else {
         perror("ERROR:");
         printf ("Open O_DIRECT OK : %d\n" , ret);
         close(ret);
      }
 return;
}
