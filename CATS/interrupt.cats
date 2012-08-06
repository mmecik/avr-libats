#ifndef _AVR_LIBATS_INTERRUPT_HEADER
#define _AVR_LIBATS_INTERRUPT_HEADER

#define declare_isr(vector, ...)                                        \
  void vector (void) __attribute__ ((signal,__INTR_ATTRS)) __VA_ARGS__

#endif
