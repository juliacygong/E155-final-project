#ifndef STM32L432KC_DMA_H
#define STM32L432KC_DMA_H

#include "STM32L432KC.h"

#define BUF_LEN 512
extern uint8_t adcBuf[BUF_LEN];
extern uint8_t spiBuf[BUF_LEN];

void initADC_DMA(void);
void startSPI_DMA(uint16_t *data, uint32_t length);
void DMA1_Channel1_IRQHandler(void);

extern volatile uint32_t *ADCptr;
extern volatile uint32_t *SPIptr;
extern volatile uint8_t SPIReady;

#endif
