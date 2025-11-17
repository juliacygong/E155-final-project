#define ADC_BUF_LEN  256
uint16_t adcBuf[ADC_BUF_LEN];

void initADC_DMA(void) {
    // Enable DMA1 clock
    RCC->AHB1ENR |= RCC_AHB1ENR_DMA1EN;

    // Disable channel during config
    DMA1_Channel1->CCR &= ~DMA_CCR_EN;

    // Set peripheral address (ADC1->DR)
    DMA1_Channel1->CPAR = (uint32_t)&ADC1->DR;

    // Set memory address
    DMA1_Channel1->CMAR = (uint32_t)adcBuf;

    // Number of transfers
    DMA1_Channel1->CNDTR = ADC_BUF_LEN;

    // Configure channel
    DMA1_Channel1->CCR |=
        (_VAL2FLD(DMA_CCR_PL,0b10) |      // Priority level: high
         _VAL2FLD(DMA_CCR_MINC, 0b1) |    // Memory increment
         _VAL2FLD(DMA_CCR_CIRC, 0b1) |    // Circular mode
         _VAL2FLD(DMA_CCR_MSIZE, 0b01) |  // Memory size = 16 bits
         _VAL2FLD(DMA_CCR_PSIZE, 0b01)    // Peripheral size = 16 bits
        );

    // Ensure direction is peripheral to memory
    DMA1_Channel1->CCR &= ~DMA_CCR_DIR;

    // Enable DMA channel
    DMA1_Channel1->CCR |= DMA_CCR_EN;
}

// page 1317 of ref manual
void startSPI_DMA(uint16_t *data, uint32_t length) {
    // Enable DMA1 clock
    RCC->AHB1ENR |= RCC_AHB1ENR_DMA1EN;

    // Disable channel while configuring
    DMA1_Channel3->CCR &= ~DMA_CCR_EN;

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
         _VAL2FLD(DMA_CCR_PSIZE, 0b01)    // Peripheral size = 16 bits
         _VAL2FLD(DMA_CCR_DIR, 0b1)       // Memory to Peripheral
        );

    // Enable SPI TX DMA request (CR2 bit)
    SPI1->CR2 |= SPI_CR2_TXDMAEN;

    // Enable channel
    DMA1_Channel3->CCR |= DMA_CCR_EN;
}
