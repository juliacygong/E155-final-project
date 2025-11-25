// main.c file for mcu communication

#include "STM32L432KC.h"
#define LED_PIN PA6  // On-board LED (for debug)
#define ADC_PIN PA5  // Analog input pin
#define BUTTON_PIN PA7 // button for start/stop transcription

extern volatile uint8_t *SPIptr;
extern volatile uint8_t SPIReady;

volatile uint8_t sampling = 0; 

int main(void) {
    configureFlash();
    configureClock();

    // Clock Enable
    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN;
    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOBEN;

    // GPIO Setup
    pinMode(LED_PIN, GPIO_OUTPUT);
    pinMode(BUTTON_PIN, GPIO_INPUT);
    GPIOA->PUPDR |= GPIO_PUPDR_PUPD7_0; // Pull-up

    // Init
    initTIM6();  
    initSPI(0b100, 1, 0); 
    initADC_DMA(); 
    initADC();    
   

    printf("System Ready\n");
    
    uint8_t prevButton = 1; 
    SPIReady = 0;
   

    while (1) {
        // Button Logic
        uint8_t button = digitalRead(BUTTON_PIN);
        //printf("button: %d \n", button);
        if (prevButton == 1 && button == 0) { 
            delay(5); 
            if (digitalRead(BUTTON_PIN) == 0) {
                if (!sampling) {
                    printf("Start Transcription\n");
                    sampling = 1;
                    digitalWrite(LED_PIN, 1);
                    start_sampling(); 
                } else {
                    printf("Stop Transcription\n");
                    sampling = 0;
                    digitalWrite(LED_PIN, 0);
                    stop_sampling(); 
                }
            }
        }
        prevButton = button;
        
        // If DMA finished start SPI transaction
        if (sampling && SPIReady) {
          SPIReady = 0;

          uint8_t *currentBuffer = (uint8_t *)SPIptr;

          digitalWrite(SPI_CS, PIO_LOW); // Select Peripheral
            // Send the entire buffer that SPIptr is currently pointing to
            for (int i = 0; i < BUF_LEN; i++) {
                spiSendReceive(currentBuffer[i]);
               // printf("Starting SPI \n");
           }

          while(SPI1->SR & SPI_SR_BSY);

          digitalWrite(SPI_CS, PIO_HIGH); // Deselect Peripheral
          
            
            // Clear
            SPIReady = 0; 

            
        }
    }
}