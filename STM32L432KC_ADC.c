// ADC modules to initialize ADC, start/stop sampling, and ADC interrupt handling

#include "STM32L432KC_ADC.h"

// Double buffer system
#define BUF_LEN 512  
volatile uint8_t buffer0[BUF_LEN];
volatile uint8_t buffer1[BUF_LEN];
volatile uint8_t *fillBuffer = buffer0;    // Buffer being filled by ADC
volatile uint8_t *sendBuffer = buffer1;    // Buffer ready to send via SPI
volatile uint16_t bufIndex = 0;
volatile uint8_t bufferReady = 0;          // Flag: buffer ready to send


void initADC(void) {
    // Enable GPIO Clock
    gpioEnable(GPIO_PORT_B);
    pinMode(ADC_PIN, GPIO_ANALOG);

    // Set up ADC clock
    RCC->AHB2ENR |= (RCC_AHB2ENR_ADCEN);
    RCC->CCIPR |= _VAL2FLD(RCC_CCIPR_ADCSEL, 0b11); // System Clock

    // ADC wake up sequence
    ADC1->CR &= ~(ADC_CR_DEEPPWD);
    ADC1->CR |= (ADC_CR_ADVREGEN);
    delay(2); // Wait for regulator

    // Calibrate ADC
    ADC1->CR &= ~(ADC_CR_ADEN);
    ADC1->CR |= ADC_CR_ADCAL;
    while(ADC1->CR & ADC_CR_ADCAL);

    // Enable ADC
    ADC1->ISR |= ADC_ISR_ADRDY;
    ADC1->CR |= ADC_CR_ADEN;
    while(!(ADC1->ISR & ADC_ISR_ADRDY));

    // Disable Continuous Mode since e want 1 conversion per timer tick
    ADC1->CFGR &= ~(ADC_CFGR_CONT); 

    // Enable External Trigger (EXTEN) on Rising Edge (01)
    ADC1->CFGR &= ~ADC_CFGR_EXTEN;
    ADC1->CFGR |= _VAL2FLD(ADC_CFGR_EXTEN, 0b01); 

    // Select Timer 6 TRGO as the trigger source (EXTSEL)
    ADC1->CFGR &= ~ADC_CFGR_EXTSEL;
    ADC1->CFGR |= _VAL2FLD(ADC_CFGR_EXTSEL, 13); 

    // Configure Channel
    ADC1->SQR1 |= _VAL2FLD(ADC_SQR1_SQ1, 15); // Channel 15 (PB0)
    ADC1->SQR1 |= _VAL2FLD(ADC_SQR1_L, 0);    // Sequence length 1
    
    // Resolution 8-bit = 2
    ADC1->CFGR |= _VAL2FLD(ADC_CFGR_RES, 2); 
    
    // Interrupts
    ADC1->IER |= ADC_IER_EOCIE; // End of Conversion Interrupt
    NVIC_EnableIRQ(ADC1_IRQn);
    NVIC_SetPriority(ADC1_IRQn, 1);
}

// ADC Interrupt Handler
// Sampling at 5kHz and interrupts everytime ADC samples value
void ADC1_IRQHandler(void) {
    if (ADC1->ISR & ADC_ISR_EOC) {
        // Read ADC data and EOC flag
        uint8_t sample = (uint8_t)ADC1->DR;
        
        // Debug frequency to check with oscope
        GPIOA->ODR ^= (1 << 6); 

        // Store in current buffer
        fillBuffer[bufIndex++] = sample;
        
        // Swap buffers when sampled 512 inputs
        if (bufIndex >= BUF_LEN) {
            bufIndex = 0;
            
            // Swap buffers
            volatile uint8_t *temp = fillBuffer;
            fillBuffer = sendBuffer;
            sendBuffer = temp;
            
            // bufer read to send over SPI
            bufferReady = 1;
        }
    }
}

void start_sampling(void) {
    // Clear overrun flag
    ADC1->ISR |= ADC_ISR_OVR;  
    bufIndex = 0;
    bufferReady = 0;
    // Start ADC conversions
    ADC1->CR |= ADC_CR_ADSTART;  
}

void stop_sampling(void) {
    if (ADC1->CR & ADC_CR_ADSTART) {
        ADC1->CR |= ADC_CR_ADSTP;
        while (ADC1->CR & ADC_CR_ADSTP);
    }
}