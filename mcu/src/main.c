// main.c file for mcu communication

#include "STM32L432KC.h"
#define LED_PIN PA6  // On-board LED for debugging
#define BUTTON_PIN PA7 // button for start/stop transcription

extern volatile uint8_t *SPIptr;
extern volatile uint8_t *sendBuffer; // Buffer ready to send via SPI
extern volatile uint8_t SPIReady;

volatile uint8_t sampling = 0; 

// Double buffer system
#define BUF_LEN 512  // Adjust to your FFT size

extern volatile uint16_t bufIndex;
extern volatile uint8_t bufferReady; // Flag: buffer ready to send

int main(void) {
    configureFlash();
    configureClock();

    // Clock Enable
    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN;
    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOBEN;

    gpioEnable(GPIO_PORT_A);
    gpioEnable(GPIO_PORT_B);

    pinMode(LED_PIN, GPIO_OUTPUT);
    pinMode(BUTTON_PIN, GPIO_INPUT);
    GPIOA->PUPDR |= GPIO_PUPDR_PUPD7_0; // Pull-up
    initTIM6();
    __enable_irq();  // Enable global interrupts


    // Initialize peripherals
    initSPI(0b100, 0, 1); 
    initADC();    // Now without DMA
  

    printf("System Ready\n");
    
    uint8_t prevButton = 1; 
    uint8_t sampling = 0;


    while (1) {
        // Button Logic for spi transcription start/stop
        uint8_t button = digitalRead(BUTTON_PIN);

        if (prevButton == 1 && button == 0) { 
            delay(5);  // Debounce
            if (digitalRead(BUTTON_PIN) == 0) {
                if (!sampling) {
                    printf("Start sampling\n");
                    sampling = 1;
                    digitalWrite(LED_PIN, 1);
                    start_sampling(); 
                } else {
                    printf("Stop sampling\n");
                    sampling = 0;
                    digitalWrite(LED_PIN, 0);
                    stop_sampling(); 
                }
            }
        }
        prevButton = button;
        
        // Send buffer over SPI when ready
        if (bufferReady && sampling) {
        printf("buffer ready");
            bufferReady = 0;  // Clear flag first
            
            for (int i = 0; i < BUF_LEN; i++) {
                digitalWrite(SPI_CS, PIO_LOW);  // Select FPGA
                spiSendReceive(sendBuffer[i]);
                digitalWrite(SPI_CS, PIO_HIGH);  // Deselect FPGA
            }
        }
    }
}
