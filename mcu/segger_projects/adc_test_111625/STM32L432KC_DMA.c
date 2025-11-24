#include "STM32L432KC_DMA.h"

uint8_t adcBuf[BUF_LEN];
uint8_t spiBuf[BUF_LEN];

volatile uint32_t *ADCptr = adcBuf;
volatile uint32_t *SPIptr = spiBuf; 
volatile uint8_t SPIReady = 1;

void initADC_DMA(void) {
    // Enable DMA1 clock
    RCC->AHB1ENR |= RCC_AHB1ENR_DMA1EN;

    // Disable channel during config
    DMA1_Channel1->CCR &= ~DMA_CCR_EN;

    // Select ADC as request
    DMA1_CSELR->CSELR &= ~DMA_CSELR_C1S;

    // Set peripheral address (ADC1->DR)
    DMA1_Channel1->CPAR = (uint32_t)&ADC1->DR;

    // Set memory address
    DMA1_Channel1->CMAR = (uint32_t)adcBuf;

    // Number of transfers
    DMA1_Channel1->CNDTR = BUF_LEN;

    // Configure channel
    DMA1_Channel1->CCR |=
        (_VAL2FLD(DMA_CCR_PL,0b10) |      // Priority level: high
         _VAL2FLD(DMA_CCR_MINC, 0b1) |    // Memory increment
         _VAL2FLD(DMA_CCR_CIRC, 0b1) |    // Circular mode
         _VAL2FLD(DMA_CCR_HTIE, 0b01) |   // Half transfer interrupt enable
         _VAL2FLD(DMA_CCR_TCIE, 0b01)     // Transfer complete interrupt enable
        );

    DMA1_Channel1->CCR &= ~DMA_CCR_MSIZE; // Memory size = 8 bits
    DMA1_Channel1->CCR &= ~DMA_CCR_PSIZE; // Peripheral size = 8 bits

    // Ensure direction is peripheral to memory
    DMA1_Channel1->CCR &= ~DMA_CCR_DIR;

    DMA1->IFCR = DMA_IFCR_CGIF1 | DMA_IFCR_CTCIF1 | DMA_IFCR_CHTIF1 | DMA_IFCR_CTEIF1;

    NVIC_EnableIRQ(DMA1_Channel1_IRQn);
    NVIC_EnableIRQ(DMA1_Channel3_IRQn);

    // Enable DMA channel
    DMA1_Channel1->CCR |= DMA_CCR_EN;
}

// page 1317 of ref manual
void startSPI_DMA(uint16_t *data, uint32_t length) {
    // Enable DMA1 clock
    RCC->AHB1ENR |= RCC_AHB1ENR_DMA1EN;

    // Disable channel while configuring
    DMA1_Channel3->CCR &= ~DMA_CCR_EN;

    // Select SPI1_TX as request
    DMA1_CSELR->CSELR &= ~DMA_CSELR_C3S;
    DMA1_CSELR->CSELR |= _VAL2FLD(DMA_CSELR_C3S, 0b0001); // SPI1_TX select: 0001

    // Peripheral: SPI1->DR
    DMA1_Channel3->CPAR = (uint32_t)&SPI1->DR;

    // Memory source
    DMA1_Channel3->CMAR = (uint32_t)data;

    // Data count (in transfers, not bytes)
    DMA1_Channel3->CNDTR = length;

    // Configure channel
    DMA1_Channel3->CCR |=
        (_VAL2FLD(DMA_CCR_PL,0b10) |      // Priority level: high
         _VAL2FLD(DMA_CCR_MINC, 0b1) |    // Memory increment
         _VAL2FLD(DMA_CCR_MSIZE, 0b01) |  // Memory size = 16 bits
         _VAL2FLD(DMA_CCR_PSIZE, 0b01) |  // Peripheral size = 16 bits
         _VAL2FLD(DMA_CCR_DIR, 0b1)       // Memory to Peripheral
        );

    // Enable SPI TX DMA request (CR2 bit)
    SPI1->CR2 |= SPI_CR2_TXDMAEN;

    // Enable channel
    DMA1_Channel3->CCR |= DMA_CCR_EN;
}

void DMA1_Channel1_IRQHandler(void) {
    // Check for Transfer Complete
    if (DMA1->ISR & DMA_ISR_TCIF1) {
        DMA1->IFCR = DMA_IFCR_CGIF1; // Clear Global interrupt flag (clears all subflags)

        // Disable DMA1 to make changes
        DMA1_Channel1->CCR &= ~(DMA_CCR_EN);

        // Ensure SPI processing is complete before switching buffers
        if (!SPIReady) {
            return; // Skip switching if SPI buffer hasn't been processed
        }

        // Switch buffers
        if (ADCptr == adcBuf) {
            ADCptr = spiBuf; // DMA will now write to spiBuf
            SPIptr = adcBuf; // SPI processing will use adcBuf
        } else {
            ADCptr = adcBuf; // DMA will now write to adcBuf
            SPIptr = spiBuf; // SPI processing will use spiBuf
        }

        // Mark FFT buffer as not ready
        SPIReady = 0;  // TODO NEED TO ENABLE THIS FOR REAL SYSTEM TO WORK PLEASE DON'T FORGET

        // Update DMA memory address
        DMA1_Channel1->CMAR = (uint32_t)ADCptr;

        // Acknowledge the OVR bit in ADC
        ADC1->ISR |= ADC_ISR_OVR;

        // Refill DMA CNDTR
        DMA1_Channel1->CNDTR |= BUF_LEN;

        // Re-enable DMA channel
        DMA1_Channel1->CCR |= DMA_CCR_EN;
    }
}