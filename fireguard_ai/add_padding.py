from PIL import Image
import sys

def add_padding(input_path, output_path, padding_ratio=0.5):
    try:
        img = Image.open(input_path).convert("RGBA")
        width, height = img.size
        new_width = int(width * (1 + padding_ratio))
        new_height = int(height * (1 + padding_ratio))
        
        # Create a new transparent image
        new_img = Image.new("RGBA", (new_width, new_height), (255, 255, 255, 0))
        
        # Paste the original image in the center
        new_img.paste(img, ((new_width - width) // 2, (new_height - height) // 2), img)
        
        new_img.save(output_path)
        print(f"Success: Created {output_path}")
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    add_padding("assets/images/logo.png", "assets/images/logo_padded.png", 1.0) # 100% padding
