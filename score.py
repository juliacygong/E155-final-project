from PIL import Image
import numpy as np

def image_to_mem(image_path, output_path, threshold=128):
    """
    Convert an image to a MEM file with 1s and 0s
    
    Parameters:
    - image_path: path to input image file
    - output_path: path to output .mem file
    - threshold: pixel value threshold (0-255). Pixels above this are 1, below are 0
    """
    # Open and convert image to grayscale
    img = Image.open(image_path).convert('L')
    
    # Get image dimensions
    width, height = img.size
    print(f"Image dimensions: {width}x{height}")
    
    # Convert to numpy array
    img_array = np.array(img)
    
    # Convert to binary (1 for black/dark, 0 for white/light)
    # Note: In images, 0 is black and 255 is white, so we invert the threshold
    binary_array = (img_array < threshold).astype(int)
    
    # Write to MEM file - one pixel per line
    with open(output_path, 'w') as f:
        for row in binary_array:
            for pixel in row:
                f.write(str(pixel) + '\n')
    
    print(f"MEM file created: {output_path}")
    print(f"Total pixels: {width * height}")
    print(f"Black pixels (1s): {np.sum(binary_array)}")
    print(f"White pixels (0s): {width * height - np.sum(binary_array)}")

# Example usage
if __name__ == "__main__":
    # Replace 'treble_clef.png' with your image filename
    input_image = 'hdown_sharp.png'
    output_mem = 'half_down_sharp.mem'
    
    try:
        image_to_mem(input_image, output_mem, threshold=128)
    except FileNotFoundError:
        print(f"Error: Could not find image file '{input_image}'")
        print("Please make sure the image file is in the same directory as this script.")
    except Exception as e:
        print(f"Error: {e}")