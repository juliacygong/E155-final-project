#include "STM32L432KC_ADC.h"

// Double buffer system
#define BUF_LEN 512  // Adjust to your FFT size
volatile uint8_t buffer0[BUF_LEN];
volatile uint8_t buffer1[BUF_LEN];
volatile uint8_t *fillBuffer = buffer0;    // Buffer being filled by ADC
volatile uint8_t *sendBuffer = buffer1;    // Buffer ready to send via SPI
volatile uint16_t bufIndex = 0;
volatile uint8_t bufferReady = 0;          // Flag: buffer ready to send


//// Modified ADC configuration without DMA
void initADC(void) {
    // Enable GPIO Clock
    gpioEnable(GPIO_PORT_B);
    pinMode(ADC_PIN, GPIO_ANALOG);

    // Set up ADC clock (RCC Side)
    RCC->AHB2ENR |= (RCC_AHB2ENR_ADCEN);
    RCC->CCIPR |= _VAL2FLD(RCC_CCIPR_ADCSEL, 0b11);

    // Select and Scale ADC Clock
    ADC1_COMMON->CCR |= _VAL2FLD(ADC_CCR_PRESC, 0b1001); // Prescaler to 64

    // Calibrate ADC
    ADC1->CR &= ~(ADC_CR_DEEPPWD);
    ADC1->CR |= (ADC_CR_ADVREGEN);
    delay(20);
    ADC1->CR &= ~(ADC_CR_ADEN);
    ADC1->CR &= ~(ADC_CR_ADCALDIF);
    ADC1->CR |= ADC_CR_ADCAL;
    while(ADC1->CR & ADC_CR_ADCAL);
    delay(1);

    // Enable ADC
    ADC1->ISR |= ADC_ISR_ADRDY;
    ADC1->CR |= ADC_CR_ADEN;
    while(!(ADC1->ISR & ADC_ISR_ADRDY));
    ADC1->ISR |= ADC_ISR_ADRDY;

    // Configure ADC conversion WITHOUT DMA
    ADC1->SMPR2 |= _VAL2FLD(ADC_SMPR2_SMP15, 2); // 12.5 cycles sampling time
    
    // REMOVE DMA configuration
    ADC1->CFGR &= ~(ADC_CFGR_DMAEN);   // Disable DMA
    ADC1->CFGR &= ~(ADC_CFGR_DMACFG);  // Disable DMA circular mode
    
    ADC1->IER |= (ADC_IER_EOCIE);  // Enable End of Conversion interrupt
    ADC1->CFGR |= (ADC_CFGR_CONT); // Continuous conversions
    ADC1->SQR1 |= _VAL2FLD(ADC_SQR1_SQ1, 15); // Channel 15 (PB0)
    ADC1->SQR1 |= _VAL2FLD(ADC_SQR1_L, 0);    // Only 1 channel
    ADC1->CFGR |= _VAL2FLD(ADC_CFGR_RES, 2);  // 8-bit resolution
    ADC1->CFGR |= ADC_CFGR_OVRMOD;  // Overwrite on overrun
    
    // Enable ADC interrupt in NVIC
    NVIC_EnableIRQ(ADC1_IRQn);
    NVIC_SetPriority(ADC1_IRQn, 1);
}

// ADC Interrupt Handler
void ADC1_IRQHandler(void) {
    if (ADC1->ISR & ADC_ISR_EOC) {
        // Read ADC data (clears EOC flag)
        uint8_t sample = (uint8_t)ADC1->DR;
        
        // Store in current fill buffer
        fillBuffer[bufIndex++] = sample;
        
        // If buffer is full, swap buffers
        if (bufIndex >= BUF_LEN) {
            bufIndex = 0;
            
            // Swap buffers
            volatile uint8_t *temp = fillBuffer;
            fillBuffer = sendBuffer;
            sendBuffer = temp;
            
            // Signal that a buffer is ready to send
            bufferReady = 1;
        }
    }
}

void start_sampling(void) {
    ADC1->ISR |= ADC_ISR_OVR;  // Clear overrun flag
    bufIndex = 0;
    bufferReady = 0;
    ADC1->CR |= ADC_CR_ADSTART;  // Start ADC conversions
}

void stop_sampling(void) {
    if (ADC1->CR & ADC_CR_ADSTART) {
        ADC1->CR |= ADC_CR_ADSTP;
        while (ADC1->CR & ADC_CR_ADSTP);
    }
}

//void initADC(void) {
//    // Enable GPIO Clock
//    gpioEnable(GPIO_PORT_B);
//    // Set the pin to analog function
//    pinMode(ADC_PIN, GPIO_ANALOG);

//    // Set up ADC clock (RCC Side)
//    RCC->AHB2ENR |= (RCC_AHB2ENR_ADCEN); // Enable ADC clock
//    RCC->CCIPR |= _VAL2FLD(RCC_CCIPR_ADCSEL, 0b11); // System clock selected as ADC clock

//    // Select and Scale ADC CLock (ADC Side)
//        // We assume that ADC CCR CKMODE[1:0] is reset already to 0b00
//    ADC1_COMMON->CCR |= _VAL2FLD(ADC_CCR_PRESC, 0b1001); // Set prescaler to 64
//    /* ADC1_COMMON->CCR |= _VAL2FLD(ADC_CCR_PRESC, 0b1011); // 256 prescale test to be super long */

//    // Calibrate ADC
//    ADC1->CR &= ~(ADC_CR_DEEPPWD); // Disable deep power down 
//    ADC1->CR |= (ADC_CR_ADVREGEN); // Enable ADC voltage regulator
//    delay(20); // Wait for the start up time of ADC voltage regulator
//    ADC1->CR &= ~(ADC_CR_ADEN); // Ensure ADC is disabled
//    ADC1->CR &= ~(ADC_CR_ADCALDIF); // Select input mode single-ended
//    ADC1->CR |= ADC_CR_ADCAL; // Enable calibration
//    while(ADC1->CR & ADC_CR_ADCAL); // Wait until calibration is completed
//    delay(1);

//    // Enable ADC
//    ADC1->ISR |= ADC_ISR_ADRDY; // Clear the ADRDY bit by writing ‘1’
//    ADC1->CR |= ADC_CR_ADEN; // Enable ADC
//    while(!(ADC1->ISR & ADC_ISR_ADRDY)); // Wait until ADC is ready for conversion
//    ADC1->ISR |= ADC_ISR_ADRDY;

//    // Configure ADC conversion
//    ADC1->SMPR2 |= _VAL2FLD(ADC_SMPR2_SMP15, 2); // Set sampling time for channel 15 to 12.5 cycles\
//    /*ADC1->SMPR2 |= _VAL2FLD(ADC_SMPR2_SMP15, 0b111); // 640.5 cycles test for slow logging */
//    //ADC1->CFGR |= (ADC_CFGR_DMAEN); // Enable DMA
//    //ADC1->CFGR |= (ADC_CFGR_DMACFG); // Select DMA circular mode
//    ADC1->IER |= (ADC_IER_EOCIE); // Enable EOC interrupt
//    // DMA Enable and circular mode could go here

//    ADC1->CFGR |= (ADC_CFGR_CONT); // Select Continous conversions
//    ADC1->SQR1 |= _VAL2FLD(ADC_SQR1_SQ1, 15); // Set channel 15 (PB0) as the 1st to be converted
//    ADC1->SQR1 |= _VAL2FLD(ADC_SQR1_L, 0); // Set to only scan 1 channel
//    ADC1->CFGR |= _VAL2FLD(ADC_CFGR_RES, 2); //0: 12-bit    1: 10-bit    2: 8-bit    3: 6-bit
//    ADC1->CFGR |= ADC_CFGR_OVRMOD;  // Made it rewrite new conversions over data register - Jackson Added
    
//}

////void initADC(void) {
////    // Enable GPIOA clock (for analog input)
////    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN;

////    // TODO: choose pin and modify
////    // Set PA5 to analog mode
////    pinMode(ADC_PIN, GPIO_ANALOG); // analog mode
////    GPIOA->PUPDR &= ~GPIO_PUPDR_PUPD5; // no pull-up/down

////    // Enable ADC clock
////    RCC->AHB2ENR |= RCC_AHB2ENR_ADCEN;
////    // Enable system clock as source clock for ADC
////    RCC->CCIPR |= _VAL2FLD(RCC_CCIPR_ADCSEL, 0b11);

////    // clock pre-scalar
////    ADC1_COMMON->CCR |= _VAL2FLD(ADC_CCR_PRESC, 0b0111); // div by 16 prescalar

////    // Ensure ADC is disabled before configuration
////    if (ADC1->CR & ADC_CR_ADEN) {
////        ADC1->CR |= ADC_CR_ADDIS;
////        while (ADC1->CR & ADC_CR_ADEN);
////    }

////    // Configure ADC
////    ADC1->CFGR = 0; // single conversion, right alignment
////    ADC1->CFGR |= ADC_CFGR_DMAEN | ADC_CFGR_DMACFG;
////    ADC1->CFGR |= _VAL2FLD(ADC_CFGR_RES, 0b10); // set 8-bit resolution
////    ADC1->CFGR |= _VAL2FLD(ADC_CFGR_EXTEN, 0b01); // set to rising edge
////    ADC1->CFGR |= _VAL2FLD(ADC_CFGR_EXTSEL, 0b1101); // EXT13: TIM6_TRGO
////    ADC1->CFGR |= _VAL2FLD(ADC_CFGR_DMAEN, 0b1); // DMA enable
////    ADC1->CFGR |= _VAL2FLD(ADC_CFGR_DMACFG, 0b1); // DMA circular mode

////    // Select channel 10 (PA5)
////    ADC1->SQR1 = (10 << ADC_SQR1_SQ1_Pos);

////    // disable deep-powder down mode
////    ADC1->CR &= ~(ADC_CR_DEEPPWD);

////    // Enable ADC voltage regulator
////    ADC1->CR |= ADC_CR_ADVREGEN;
////    delay(200); 

////    // Calibrate ADC
////    ADC1->CR |= ADC_CR_ADCAL;

////    printf("start cal \n");
////    while (ADC1->CR & ADC_CR_ADCAL);
////    printf("end_cal \n");
////    delay(10);

////    // Enable ADC
////    //ADC1->CFGR |= ADC_CFGR_CONT; // allow for continuous mode
////    ADC1->ISR |= ADC_ISR_ADRDY; // check if this is needed
////    ADC1->CR |= ADC_CR_ADEN;
////    while (!(ADC1->ISR & ADC_ISR_ADRDY));
////}

//uint8_t readADC(void) {
//    ADC1->CR |= ADC_CR_ADSTART; // start conversion
//    while (!(ADC1->ISR & ADC_ISR_EOC)); // wait until done
//    return (uint8_t)ADC1->DR; // return 8-bit result
//}


//void start_sampling(void) {
//    // Clear
//    ADC1->ISR |= ADC_ISR_OVR;

//    // ADC respond to TIM6 TRGO
//    ADC1->CR |= ADC_CR_ADSTART;

//    // Start TIM6 (5 kHz)
//    TIM6->CR1 |= TIM_CR1_CEN;
//}

//void stop_sampling(void) {
//    // Stop timer so no more triggers
//    TIM6->CR1 &= ~TIM_CR1_CEN;

//    // Stop ADC conversion
//    if (ADC1->CR & ADC_CR_ADSTART) {
//        ADC1->CR |= ADC_CR_ADSTP;
//        while (ADC1->CR & ADC_CR_ADSTP);
//    }
//}