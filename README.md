Code Overview
- The code is split up into folders for FPGA and MCU
- FPGA code includes the entire FPGA design, Testbenches used to debug FFT implementation, and memfiles for the notes and score
- MCU code contains interface with button input, ADC sampling, and SPI

FPGA
- FPGA Design
    - Top module split into fft control, vga top module, and spi module
- Testbenches
    - contains a hierarchy of testbenches from debugging fft module, fft decoding, and spi input
- Mem Files
    - contains pixel layout for score and notes (upwards/downwards stems and sharp/no sharp)

MCU
- Contains drivers used
- ADC sampling is controlled by button input
- Creates new ADC driver to sample from ADC at 5KHz and uses an interrupt to count the number of samples taken before sending data using SPI
