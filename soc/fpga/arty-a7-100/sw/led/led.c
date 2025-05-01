// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdint.h>
#define CLK_FIXED_FREQ_HZ (50ULL * 1000 * 1000)

/**
 * Delay loop executing within 8 cycles on ibex
 */
static void delay_loop_ibex(unsigned long loops) {
  int out; /* only to notify compiler of modifications to |loops| */
  asm volatile(
      "1: nop             \n" // 1 cycle
      "   nop             \n" // 1 cycle
      "   nop             \n" // 1 cycle
      "   nop             \n" // 1 cycle
      "   addi %1, %1, -1 \n" // 1 cycle
      "   bnez %1, 1b     \n" // 3 cycles
      : "=&r" (out)
      : "0" (loops)
  );
}

static int usleep_ibex(unsigned long usec) {
  unsigned long usec_cycles;
  usec_cycles = CLK_FIXED_FREQ_HZ * usec / 1000 / 1000 / 8;

  delay_loop_ibex(usec_cycles);
  return 0;
}

static int usleep(unsigned long usec) {
  return usleep_ibex(usec);
}

int main(int argc, char **argv) {
  volatile uint32_t *sw     = (volatile uint32_t *) 0x10000000;
  volatile uint32_t *ledrgb = (volatile uint32_t *) 0x10001000;
  volatile uint32_t *led    = (volatile uint32_t *) 0x10002000;
  volatile uint32_t *btn    = (volatile uint32_t *) 0x10003000;

  *ledrgb = 0;
  *led = 0;

  //asm("csrci 0x7c0, 1"); // disable icache
  asm("csrsi 0x7c0, 1"); // enable icache

  for (;;) {
    usleep(1000 * 1000); // 1000 ms
    //usleep(1 * 1000); // 1 ms

    // RGB LED
    uint8_t button = *btn;
    if (*sw & 0b1000) {
      uint8_t color = *led & 0b0111;
      *ledrgb = (color << 24) | (color << 16) | (color << 8) | color;
    } else {
      uint8_t color = *sw & 0b0111;
      if (button & 0b0001) *ledrgb = color;
      if (button & 0b0010) *ledrgb = color << 8;
      if (button & 0b0100) *ledrgb = color << 16;
      if (button & 0b1000) *ledrgb = color << 24;
    }

    // green LED
    *led = *led + 1;
  }
}
