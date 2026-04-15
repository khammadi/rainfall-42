#include <stdlib.h>
#include <string.h>
#include <stdio.h>


int main(int argc, char *argv[])
{
  char *str = malloc(0x40); 
  uint32_t *addr = malloc(0x4);

  *addr = m;
  strcpy(str, argv[1]);

  ((uint32_t (*)())*addr)();
}