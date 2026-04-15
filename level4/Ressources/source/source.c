#include <stdio.h>
#include <stdlib.h>

int m = 0;

void p(char *buffer)
{
  printf(buffer);
}

void n(void)
{
  char buffer[0x200];

  fgets(buffer, 0x200, stdin); 
  p(buffer);
  if (m == 0x1025544) {
    system("/bin/cat /home/user/level5/.pass");
  }
}

int main(int argc, char *argv[])
{
  n();
}