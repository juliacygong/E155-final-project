#include "STM32L432KC_ADC.h"

void initADC(void) {
    // Enable GPIOA clock (for analog input)
    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN;

    // TODO: choose pin and modify
    // Set PA0 to analog mode
    GPIOA->MODER |= GPIO_MODER_MODE5; // 11: analog mode
    GPIOA->PUPDR &= ~GPIO_PUPDR_PUPD5; // no pull-up/down

    // Enable ADC clock
    RCC->AHB2ENR |= RCC_AHB2ENR_ADCEN;
    // Enable system clock as source clock for ADC
    RCC->CCIPR |= _VAL2FLD(RCC_CCIPR_ADCSEL, 0b11);

    // clock pre-scalar
    ADC1_COMMON->CCR |= _VAL2FLD(ADC_CCR_PRESC, 0b0111); // div by 16 prescalar

    // Ensure ADC is disabled before configuration
    if (ADC1->CR & ADC_CR_ADEN) {
        ADC1->CR |= ADC_CR_ADDIS;
        while (ADC1->CR & ADC_CR_ADEN);
    }

    // Configure ADC
    ADC1->CFGR = 0; // single conversion, right alignment
    ADC1->CFGR |= ADC_CFGR_DMAEN | ADC_CFGR_DMACFG;
    ADC1->CFGR |= _VAL2FLD(ADC_CFGR_RES, 0b10); // set 8-bit resolution
    ADC1->CFGR |= _VAL2FLD(ADC_CFGR_EXTEN, 0b01); // set to rising edge
    ADC1->CFGR |= _VAL2FLD(ADC_CFGR_EXTSEL, 0b1101); // EXT13: TIM6_TRGO
    ADC1->CFGR |= _VAL2FLD(ADC_CFGR_DMAEN, 0b1); // DMA enable
    ADC1->CFGR |= _VAL2FLD(ADC_CFGR_DMACFG, 0b1); // DMA circular mode

    // Select channel 10 (PA5)
    ADC1->SQR1 = (10 << ADC_SQR1_SQ1_Pos);

    // disable deep-powder down mode
    ADC1->CR &= ~(ADC_CR_DEEPPWD);

    // Enable ADC voltage regulator
    ADC1->CR |= ADC_CR_ADVREGEN;
    delay(200); 

    // Calibrate ADC
    ADC1->CR |= ADC_CR_ADCAL;

    printf("start cal \n");
    while (ADC1->CR & ADC_CR_ADCAL);
    printf("end_cal \n");
    delay(10);

    // Enable ADC
    //ADC1->CFGR |= ADC_CFGR_CONT; // allow for continuous mode
    ADC1->ISR |= ADC_ISR_ADRDY; // check if this is needed
    ADC1->CR |= ADC_CR_ADEN;
    while (!(ADC1->ISR & ADC_ISR_ADRDY));
}

uint8_t readADC(void) {
    ADC1->CR |= ADC_CR_ADSTART; // start conversion
    while (!(ADC1->ISR & ADC_ISR_EOC)); // wait until done
    return (uint8_t)ADC1->DR; // return 8-bit result
}


void start_sampling(void) {
    // Clear
    ADC1->ISR |= ADC_ISR_OVR;

    // ADC respond to TIM6 TRGO
    ADC1->CR |= ADC_CR_ADSTART;

    // Start TIM6 (5 kHz)
    TIM6->CR1 |= TIM_CR1_CEN;
}

void stop_sampling(void) {
    // Stop timer so no more triggers
    TIM6->CR1 &= ~TIM_CR1_CEN;

    // Stop ADC conversion
    if (ADC1->CR & ADC_CR_ADSTART) {
        ADC1->CR |= ADC_CR_ADSTP;
        while (ADC1->CR & ADC_CR_ADSTP);
    }
}
