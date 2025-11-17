#ifndef STM32L432KC_DMA_H
#define STM32L432KC_DMA_H

#include "STM32L432KC.h"

#define ADC_BUF_LEN 256
extern uint16_t adcBuf[ADC_BUF_LEN];

void initADC_DMA(void);
void startSPI_DMA(uint16_t *data, uint32_t length);

#endif
