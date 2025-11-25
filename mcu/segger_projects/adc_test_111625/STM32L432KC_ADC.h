#ifndef STM32L432KC_ADC_H
#define STM32L432KC_ADC_H

#include "STM32L432KC.h"

#define ADC_PIN PA5  // Analog input pin

void initADC(void);

uint8_t readADC(void);

void start_sampling(void);

void stop_sampling(void);

#endif
