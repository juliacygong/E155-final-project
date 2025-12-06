# Live Music Transcriber
This project aims to take in sound inputs, whether using a keyboard, any instruments, or someone signing, transcribe the sound onto a score in real-time with a given bpm, and play back the input melody. An FPGA will be used as the main calculation and display engine, using Fast Fourier Transform (FFT) to handle frequency analysis and driving a VGA display. A MCU will be used for interfacing the audio inputs and outputs.

The final report of this project can be found in this [link](https://juliacygong.github.io/E155-project-website/).

## Code Overview
- The code is split up into folders for FPGA and MCU
- FPGA code includes the entire FPGA design, Testbenches used to debug FFT implementation, and memfiles for the notes and score
- MCU code contains interface with button input, ADC sampling, and SPI

## FPGA
### Design and Folder Description
- FPGA Design
    - Top module split into fft control, vga top module, and spi module
- Testbenches
    - contains a hierarchy of testbenches from debugging fft module, fft decoding, and spi input
- Mem Files
    - contains pixel layout for score and notes (upwards/downwards stems and sharp/no sharp)
- Generators
    - python scripts used to generate LUTs for fft module, such as the twiddle factors
- Radiant Project
    - contains the project files used for synthesis and implementation on the FPGA board

### Code Folder Heirarchy
- fpga
    - generators
    - memfile
    - radiant_project
    - src
        - bitstream_data
        - testbenches
        - all modules and submodules used in the final product

## MCU
### Design and Folder Description
- ADC sampling is controlled by button input
- Creates new ADC driver to sample from ADC at 5KHz and uses an interrupt to count the number of samples taken before sending data using SPI
- The lib folder contains the drivers used, including SPI and ADC drivers
- The main.c file contains the main loop and button interrupt handler

### Code Heirarchy
- mcu
    - lib
        - all drivers used
    - src
        - main.c

## Proposal
- The proposal of this project can be found in the proposal folder
