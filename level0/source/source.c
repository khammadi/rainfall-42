#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

int main(int argc, char **argv)
{
    if (atoi(argv[1]) == 0x1a7)   // 423 in decimal
    {
        char *cmd = strdup("/bin/sh");

        gid_t egid = getegid();
        uid_t euid = geteuid();

        setresgid(egid, egid, egid);
        setresuid(euid, euid, euid);

        execv("/bin/sh", &cmd);
    }
    else
    {
        fwrite("No !\n", 1, 5, stderr);
    }

    return 0;
}