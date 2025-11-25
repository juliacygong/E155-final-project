#include "STM32L432KC_DMA.h"

uint8_t adcBuf[BUF_LEN];
uint8_t spiBuf[BUF_LEN];

volatile uint8_t *ADCptr = adcBuf;
volatile uint8_t *SPIptr = spiBuf; 
volatile uint8_t SPIReady = 0;

volatile uint8_t spiBusy = 0;
extern volatile uint8_t sampling;

void initADC_DMA(void) {
    // Set DMA clock
    RCC->AHB1ENR |= RCC_AHB1ENR_DMA1EN;

    // Make sure AHB Prescaler is set to divide by 1 field cleared
    RCC->CFGR &= ~(RCC_CFGR_HPRE);

    // Disable DMA to configure
    DMA1_Channel1->CCR &= ~DMA_CCR_EN;

    // Select ADC request (C1S = 0000 for ADC1 on Channel 1)
    DMA1_CSELR->CSELR &= ~DMA_CSELR_C1S;

    // Set Peripheral Address
    DMA1_Channel1->CPAR = _VAL2FLD(DMA_CPAR_PA, (uint32_t)&ADC1->DR);
    // Set Memory Address
    DMA1_Channel1->CMAR = (uint32_t)ADCptr; // Start with ADCptr

    // Set Data Length
    DMA1_Channel1->CNDTR = BUF_LEN;

    // Reset DMA channel configuration
    DMA1_Channel1->CCR &= ~(0xFFFFFFFF);

    // The channel priority
    DMA1_Channel1->CCR |= _VAL2FLD(DMA_CCR_PL, 3); // Channel priority very high
    
    // The data transfer direction (DIR=0 implies peripheral-to-memory)
    DMA1_Channel1->CCR &= ~(DMA_CCR_DIR);

    // The Peripheral and Memory Incremented mode
    DMA1_Channel1->CCR &= ~(DMA_CCR_PINC); // Disable peripheral increment mode
    DMA1_Channel1->CCR |= (DMA_CCR_MINC); // Enable memory increment mode

    // The Peripheral and Memory data size
    DMA1_Channel1->CCR |= _VAL2FLD(DMA_CCR_MINC, 1); // Memory data size 16 bits

    // The interrupt enable for full transfer
     DMA1_Channel1->CCR |= DMA_CCR_TCIE;

    // FINALLY, activate the channel by setting EN bit in DMA_CCRx
    DMA1_Channel1->CCR |= (DMA_CCR_EN);

    //// Enable DMA1 Channel 1 interrupt in NVIC
    //NVIC_EnableIRQ(DMA1_Channel1_IRQn);
    //NVIC_SetPriority(DMA1_Channel1_IRQn, 0);

    //// Configure Control Register
    //// PL = High (10)
    //// MINC = 1 (Memory Increment)
    //// CIRC = 0 (Normal mode - we manually reload in ISR for ping-pong)
    //// TCIE = 1 (Transfer Complete Interrupt)
    //// DIR = 0 (Peripheral to Memory)
    //// MSIZE/PSIZE = 00 (8-bit)
    //DMA1_Channel1->CCR = 
    //    _VAL2FLD(DMA_CCR_PL, 0b10) |
    //    DMA_CCR_MINC |
    //    DMA_CCR_TCIE; 
    //    // Note: CIRC is OFF. We want it to stop so we can swap pointers.

    //// 6. Clear Interrupt Flags
    //DMA1->IFCR = DMA_IFCR_CGIF1;

    //// 7. Enable Interrupts in NVIC
    //NVIC_SetPriority(DMA1_Channel1_IRQn, 1);
    //NVIC_EnableIRQ(DMA1_Channel1_IRQn);

    //// 8. Enable DMA
    //DMA1_Channel1->CCR |= DMA_CCR_EN;
}

void DMA1_Channel1_IRQHandler(void) {
    // Check for Transfer Complete
    if (DMA1->ISR & DMA_ISR_TCIF1) {
        DMA1->IFCR = DMA_IFCR_CGIF1; // Clear all flags

        // 1. Disable DMA to modify CMAR/CNDTR
        DMA1_Channel1->CCR &= ~DMA_CCR_EN;
        
        //// Make sure SPI is complete before switching buffers
        //if (!SPIReady) {
        //  return;
        //}

        // 2. Swap Pointers
        if (ADCptr == adcBuf) {
            ADCptr = spiBuf; // Next fill goes to buffer2
            SPIptr = adcBuf; // Main should send buffer1
        } else {
            ADCptr = adcBuf; // Next fill goes to buffer1
            SPIptr = spiBuf; // Main should send buffer2
        }

        
        SPIReady = 1;

        // 4. Reconfigure DMA for the new buffer
        DMA1_Channel1->CMAR = (uint32_t)ADCptr;
        DMA1_Channel1->CNDTR = BUF_LEN; // Reload count!

        ADC1->ISR |= ADC_ISR_OVR;

        //// 5. Re-enable DMA
        //// Only re-enable if we are still sampling
        //if (sampling) {
        //    DMA1_Channel1->CCR |= DMA_CCR_EN;
        //}

        //SPIReady = 1;

        // Refill DMA CNDTR
        DMA1_Channel1->CNDTR |= BUF_LEN;

        // Re-enable DMA channel
        DMA1_Channel1->CCR |= DMA_CCR_EN;
    }
    
}