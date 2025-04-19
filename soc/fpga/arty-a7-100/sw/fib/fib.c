int main(void) {
  int a, b;
  volatile int y;

  //asm("csrci 0x7c0, 1"); // disable icache
  asm("csrsi 0x7c0, 1"); // enable icache

  a = 0;
  b = 1;

  /* F10 = 55 (0x37) */
  for (int i = 1; i < 10; ++i) {
    y = a + b;
    a = b;
    b = y;
  }

  for (;;) {
    asm("wfi");
  }
}
