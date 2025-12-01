#!/usr/bin/env python3
"""
Convert a black and white image to FPGA memory initialization file
Usage: python image_to_mem.py treble_clef.png
"""

from PIL import Image
import sys

def image_to_mem(image_path, output_path=None, threshold=128):
    """
    Convert image to .mem file for FPGA
    
    Args:
        image_path: Path to input image
        output_path: Path to output .mem file (defaults to input name + .mem)
        threshold: Pixel brightness threshold (0-255), above = white/1, below = black/0
    """
    # Load and convert image to grayscale
    img = Image.open(image_path).convert('L')
    width, height = img.size
    
    print(f"Image size: {width}x{height} = {width*height} pixels")
    
    # Default output path
    if output_path is None:
        output_path = image_path.rsplit('.', 1)[0] + '.mem'
    
    # Convert to binary (1-bit per pixel)
    pixels = img.load()
    
    # Write .mem file (one bit per line in hex format)
    with open(output_path, 'w') as f:
        for y in range(height):
            for x in range(width):
                pixel_value = pixels[x, y]
                # If pixel is bright (above threshold), output 1, else 0
                bit = '1' if pixel_value > threshold else '0'
                f.write(bit + '\n')
    
    print(f"Generated {output_path}")
    print(f"Total bits: {width * height}")
    print(f"Address width needed: {(width * height - 1).bit_length()} bits")
    
    # Also create a packed version (8 bits per line) for efficiency
    packed_output = output_path.rsplit('.', 1)[0] + '_packed.mem'
    with open(packed_output, 'w') as f:
        bit_buffer = []
        for y in range(height):
            for x in range(width):
                pixel_value = pixels[x, y]
                bit = 1 if pixel_value > threshold else 0
                bit_buffer.append(bit)
                
                # Write byte when we have 8 bits
                if len(bit_buffer) == 8:
                    byte_val = 0
                    for i, b in enumerate(bit_buffer):
                        byte_val |= (b << (7-i))
                    f.write(f"{byte_val:02X}\n")
                    bit_buffer = []
        
        # Write remaining bits (pad with zeros)
        if bit_buffer:
            while len(bit_buffer) < 8:
                bit_buffer.append(0)
            byte_val = 0
            for i, b in enumerate(bit_buffer):
                byte_val |= (b << (7-i))
            f.write(f"{byte_val:02X}\n")
    
    print(f"Also generated packed version: {packed_output}")
    print(f"Packed size: {(width * height + 7) // 8} bytes")

def create_sample_treble_clef(width=40, height=80):
    """Create a simple treble clef shape for testing"""
    img = Image.new('L', (width, height), color=255)  # White background
    pixels = img.load()
    
    # Draw a simple treble clef-like shape
    # Vertical line
    for y in range(10, 70):
        for x in range(18, 22):
            pixels[x, y] = 0
    
    # Top curl
    for y in range(5, 20):
        for x in range(15, 30):
            if ((x-20)**2 + (y-12)**2) < 80:
                pixels[x, y] = 0
    
    # Bottom curl
    for y in range(60, 75):
        for x in range(10, 28):
            if ((x-19)**2 + (y-67)**2) < 90:
                pixels[x, y] = 0
    
    # Middle crossing line
    for x in range(12, 28):
        for y in range(38, 42):
            pixels[x, y] = 0
    
    img.save('sample_treble_clef.png')
    print("Created sample_treble_clef.png")
    return 'sample_treble_clef.png'

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("No image provided, creating sample treble clef...")
        image_path = create_sample_treble_clef()
        image_to_mem(image_path)
    else:
        image_to_mem(sys.argv[1])