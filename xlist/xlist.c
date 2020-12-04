/* xlist.c

Written by Jim Moorehead 1990
Adapted by Steve Boyce 1997

--------------------------------------------------------------------*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define        MAX_LENGTH 120
#define        TRUE         1
#define        FALSE        0
#define        FORM_FEED  printf("\f")

void           openfile( int argc );
void           heading( void );
int            display_line(void);
int            fill_space( int old_j, int position );

char           *in_name;
unsigned char  string[MAX_LENGTH + 1];
int            length;
FILE           *fptr;

/*-----------------------------------------------------------------*/
int main(int argc, char *argv[] )
{
   int not_eof;

   length  = 16;
   not_eof = TRUE;
   in_name = argv[1];

   openfile( argc);

   while( (not_eof = display_line() ) == TRUE );

   fclose( fptr );

   return( 0 );
}
/*-----------------------------------------------------------------*/
void openfile( int argc )
{
   if( argc != 2){
      printf( "Missing file name.  -h for help.\n");
      exit( 1 );
   }

   if( !strcmp( in_name, "-h" )){
      printf( "\nXLIST.EXE v2.0  Copyright (c) 1997 Steve Boyce");
      printf( "\nSpecial thanks goes to Jim Moorehead for allowing me adapt this code.");
      printf( "\nFORMAT: xlist [path]<filename> [-h]");
      printf( "\nWhere:  path      - is the full or relative path to the input file");
      printf( "\n        filename  - is the name of the input file");
      printf( "\n        -h        - is this help");
      printf( "\n");
      printf( "\n");
      exit( 0 );
   }

   if( ( fptr = fopen( in_name,"rb" ) ) == NULL ){
      printf( "Can't open file %s.  -h for help.\n", in_name );
      exit( 1 );
   }

   return;
}
/*-----------------------------------------------------------------*/
int display_line(void)
{
   unsigned int ch;
   static int   first_page = TRUE;
   static int   line;
   static long  pos;
   int          j, space, not_eof;

   not_eof = TRUE;
   space   = FALSE;

   if( first_page ){
      printf( "\n\nXLIST.EXE v1.0  Copyright (c) 1997 Steve Boyce\n");
      first_page = FALSE;
      line = 2;
      heading();
      line += 4;
   }

   for( j = 0; j < length; j++ ){
      if(  ( ch = getc( fptr ) ) == EOF )
         not_eof = FALSE;

      if(  not_eof ){
         printf( "%3x", ch );
      }
      else
      {
         not_eof = FALSE;
         printf( "%s", " XX" );
      }

      pos++;

      if( not_eof ){
         if( ch > 31  &&  ch < 128 )
            *(string + j) = (unsigned char)ch;
         else
            *(string + j) = '.';
      }
      else
         *(string + j) = '\0';
   }

   *(string + j) = '\0';
   printf( " - %7ld  %s\n", pos , string );
   line ++;

   return( not_eof );
}
/*-----------------------------------------------------------------*/
void heading( void )
{
   int k;

   printf("Hex/ASCII: %s\n", in_name);

   for( k = 0; k < length; k++){
      printf("%3d", k );
   }
   printf("\n\n");

   return;
}
/*-----------------------------------------------------------------*/
int fill_space( int old_j, int position )
{
   int k, new_j;
   new_j = 0;

   for( k = old_j+1; k < length; k++)
      printf( "   ");

   *(string + old_j) = '\0';
   printf( " - %3d  %s\n", position , string );

   for( k = 0; k < (old_j+1) ; k++){
      printf( "   " );
      *(string + k) = ' ';
   }

   return( k-1 );
}
