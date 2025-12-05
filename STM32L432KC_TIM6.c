// Julia Gong
// 9/27/25
// initializing timer for MCU
// STM32L432KC_TIM6.c

#include "STM32L432KC_TIM6.h"

void initTIM6(void) {
    // Enable clock for TIM6
    RCC->APB1ENR1 |= RCC_APB1ENR1_TIM6EN;
    
    // Reset TIM6 config
    TIM6->CR1 = 0; 
    TIM6->CR2 = 0;

    // Set Prescaler (PSC)
    // 80 MHz / 16 = 5 MHz timer clock
    TIM6->PSC = 15; 

    // Set Auto-Reload (ARR)
    // 5 MHz / 1000 = 5 kHz trigger frequency
    TIM6->ARR = 999; 

    // Set Master Mode Selection (MMS) to 010 for Update Event (TRGO)
    // Tells the timer to send a signal to the ADC every time it overflows
    TIM6->CR2 &= ~TIM_CR2_MMS;
    TIM6->CR2 |= TIM_CR2_MMS_1; // 010

    // Enable Update Interrupt 
    TIM6->DIER |= TIM_DIER_UIE; 

    // Enable Counter
    TIM6->CR1 |= TIM_CR1_CEN;
}

// new delay without using TIM6
void delay(int ms) {
    for(int i = 0; i < ms; i++) {
        for(volatile int j = 0; j < 6000; j++) {
            __NOP();
        }
    }
}
