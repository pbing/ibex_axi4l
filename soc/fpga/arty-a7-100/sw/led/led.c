// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdint.h>
//#define CLK_FIXED_FREQ_HZ (50ULL * 1000 * 1000)
const unsigned long long CLK_FIXED_FREQ_HZ = (50ull * 1000 * 1000);
const unsigned int TICK_TIME = 10;    // 10 ms
const unsigned int BLINK_TIME = 1000; // 1000 ms

static volatile uint32_t *SW        = (uint32_t*)0x10000000;
static volatile uint32_t *LEDRGB    = (uint32_t*)0x10001000;
static volatile uint32_t *LED       = (uint32_t*)0x10002000;
static volatile uint32_t *BTN       = (uint32_t*)0x10003000;
static volatile uint32_t *MTIME     = (uint32_t*)0x10004000;
//static volatile uint32_t *MTIMEH  = (uint32_t*)0x10004004;
static volatile uint32_t *MTIMECMP  = (uint32_t*)0x10004008;
static volatile uint32_t *MTIMECMPH = (uint32_t*)0x1000400c;

__attribute__((interrupt)) void timer_interrupt_handler(void) {
  static unsigned int ticks = 0;

  // blink every second
  if (++ticks == BLINK_TIME / TICK_TIME) {
    ticks = 0;
    ++(*LED);
  }

  // increment mtimecmp
  uint64_t mtimecmp = *((uint64_t*)MTIMECMP);
  mtimecmp += CLK_FIXED_FREQ_HZ / 1000 / TICK_TIME;
  *MTIMECMP = 0xffffffff;
  *MTIMECMPH = mtimecmp >> 32;
  *MTIMECMP = mtimecmp & 0xffffffff;
};

__attribute__((interrupt))
void btn_interrupt_handler(void) {
  if (!(*SW & 0b1000)) {
    uint8_t button = *BTN;
    uint8_t color = *SW & 0b0111;
    uint32_t ledrgb_reg = 0;
    if (button & 0b0001) ledrgb_reg |= color;
    if (button & 0b0010) ledrgb_reg |= color << 3;
    if (button & 0b0100) ledrgb_reg |= color << 6;
    if (button & 0b1000) ledrgb_reg |= color << 9;
    *LEDRGB = ledrgb_reg;
  }
};

int main(int argc, char **argv) {
  //asm("csrci 0x7c0, 1"); // disable icache
  asm("csrsi 0x7c0, 1"); // enable icache

  *LEDRGB = 0;
  *LED = 0;

  uint64_t mtime = *((uint64_t*)MTIME);
  uint64_t mtimecmp = mtime + CLK_FIXED_FREQ_HZ / 1000 / TICK_TIME;
  *MTIMECMP = 0xffffffff;
  *MTIMECMPH = mtimecmp >> 32;
  *MTIMECMP = mtimecmp & 0xffffffff;

  asm("csrw mie, %0" : : "r"(1ul << 7)); // MTIE: Machine Timer Interrupt Enable
  asm("csrsi mstatus, 1 << 3");          // MIE: Machine Interrupt Enable

  for (;;) {
    asm volatile("wfi");
  }
//  for (;;) {
//    usleep(1000 * 1000); // 1000 ms
//    //usleep(1 * 1000); // 1 ms
//
//    // RGB LED
//    if (*SW & 0b1000) {
//      uint8_t color = *LED & 0b0111;
//      *LEDRGB = (color << 9) | (color << 6) | (color << 3) | color;
//    }
//
//    // green LED
//    ++(*LED);
//  }
}
