int main(void) {
  unsigned long a, b;
  volatile unsigned long y;

  //asm("csrci 0x7c0, 1"); // disable icache
  asm("csrsi 0x7c0, 1"); // enable icache

  a = 0;
  b = 1;

  /* F47 = 2971215073 (0xb11924e1) */
  for (int i = 1; i < 47; ++i) {
    y = a + b;
    a = b;
    b = y;
  }

  for (;;) {
    asm("wfi");
  }
}
