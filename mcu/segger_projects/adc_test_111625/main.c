// main.c file for mcu communication

#include "STM32L432KC.h"
#define LED_PIN PA6  // On-board LED (for debug)
#define BUTTON_PIN PA7 // button for start/stop transcription

extern volatile uint8_t *SPIptr;
extern volatile uint8_t SPIReady;

volatile uint8_t sampling = 0; 
uint8_t testbuf[4] = {0xAA, 0xBB, 0xCC, 0xDD};

int main(void) {
    configureFlash();
    configureClock();

    // Clock Enable
    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN;
    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOBEN;

    // Enable Pins
    gpioEnable(GPIO_PORT_A);
    gpioEnable(GPIO_PORT_B);
    gpioEnable(GPIO_PORT_C);

    // GPIO Setup
    pinMode(LED_PIN, GPIO_OUTPUT);
    pinMode(BUTTON_PIN, GPIO_INPUT);
    GPIOA->PUPDR |= GPIO_PUPDR_PUPD7_0; // Pull-up

    // Init
    initTIM6();  
    initSPI(0b100, 0, 1); 
    // Enable global interrupts
    //__enable_irq();
    // Enable DMA1 Channel 1 interrupt in NVIC
    //NVIC_EnableIRQ(DMA1_Channel1_IRQn);
    //NVIC_SetPriority(DMA1_Channel1_IRQn, 0);

    initADC_DMA(); 
    initADC();    
   

    printf("System Ready\n");
    
    uint8_t prevButton = 1; 
    SPIReady = 0;
   

    while (1) {
        // Button Logic
        //uint8_t button = digitalRead(BUTTON_PIN);
        ////printf("button: %d \n", button);
        //if (prevButton == 1 && button == 0) { 
        //    //delay(5); 
        //    if (digitalRead(BUTTON_PIN) == 0) {
        //        if (!sampling) {
        //            printf("Start\n");
        //            sampling = 1;
        //            //digitalWrite(LED_PIN, 1);
        //            start_sampling(); 
        //        } else {
        //            printf("Stop\n");
        //            sampling = 0;
        //            //digitalWrite(LED_PIN, 0);
        //            //stop_sampling(); 
        //        }
        //    }
        //}
        //prevButton = button;
        
        // If DMA finished start SPI transaction
        sampling = 1;
        if (sampling) {
          SPIReady = 0;

          if (!SPIReady) {


          uint8_t *currentBuffer = (uint8_t *)SPIptr;
            // Send the entire buffer that SPIptr is currently pointing to
            for (int i = 0; i < BUF_LEN; i++) {
              digitalWrite(SPI_CS, PIO_LOW); // Select Peripheral
              spiSendReceive(currentBuffer[i]);
               // printf("Starting SPI \n");
               digitalWrite(SPI_CS, PIO_HIGH); // Deselect Peripheral              
           }
          

            // Clear
            SPIReady = 1; 

            }
        }
    }
}