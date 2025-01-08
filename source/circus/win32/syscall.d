module circus.win32.syscall;

void syscall(int ssn) {
    asm {
        mov R10, RCX;
        mov EAX, ssn;
        syscall;
        ret;
    }
}