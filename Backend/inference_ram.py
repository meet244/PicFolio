'''
 * The Recognize Anything Model (RAM)
 * Written by Xinyu Huang
'''
import argparse
import numpy as np
import random
import threading
import time

import torch

from PIL import Image
from ram.models import ram
from ram import inference_ram as inference
from ram import get_transform
from huggingface_hub import hf_hub_download
import os


# Global model manager
class ModelManager:
    def __init__(self):
        self.model = None
        self.device = None
        self.transform = None
        self.timer = None
        self.lock = threading.Lock()
        self.unload_timeout = 180  # 3 minutes in seconds
        
    def load_model(self, pretrained='backend/ram_swin_large_14m.pth', image_size=384):
        """Load the model if not already loaded"""
        with self.lock:
            if self.model is None:
                print("Loading RAM model...")
                self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
                self.transform = get_transform(image_size=image_size)
                
                self.model = ram(pretrained=pretrained,
                               image_size=image_size,
                               vit='swin_l')
                self.model.eval()
                self.model = self.model.to(self.device)
                print(f"Model loaded successfully on {self.device}")
    
    def unload_model(self):
        """Unload the model from memory"""
        with self.lock:
            if self.model is not None:
                print("Unloading RAM model due to inactivity...")
                del self.model
                self.model = None
                self.device = None
                self.transform = None
                if torch.cuda.is_available():
                    torch.cuda.empty_cache()
                print("Model unloaded successfully")
    
    def reset_timer(self):
        """Reset the unload timer"""
        if self.timer is not None:
            self.timer.cancel()
        
        self.timer = threading.Timer(self.unload_timeout, self.unload_model)
        self.timer.daemon = True
        self.timer.start()
    
    def process_image(self, image_path, pretrained='pretrained/ram_swin_large_14m.pth', image_size=384) -> list:
        """Process an image and return English tags as a list"""
        # Load model if not loaded
        self.load_model(pretrained, image_size)
        
        # Reset the unload timer
        self.reset_timer()
        
        # Process the image
        with self.lock:
            image = self.transform(Image.open(image_path)).unsqueeze(0).to(self.device)
            res = inference(image, self.model)
        
        # Return English tags as a list
        english_tags = res[0]
        tag_list = [tag.strip() for tag in english_tags.split(' | ')]
        print('Tags - ', tag_list)
        
        return tag_list


# Global instance
_model_manager = ModelManager()


def process_image_with_ram(image_path, pretrained='backend/ram_swin_large_14m.pth', image_size=384):
    """
    Process an image using the RAM model and return tags in English as a list.
    
    The model is automatically loaded if not already loaded, and stays loaded for 3 minutes
    after the last use. If a new image is processed within 3 minutes, the timer resets.
    
    Args:
        image_path (str): Path to the image file
        pretrained (str): Path to the pretrained model weights
        image_size (int): Input image size for the model
        
    Returns:
        list: List of English tags for the image
        
    Example:
        >>> tags = process_image_with_ram("path/to/image.jpg")
        >>> print(tags)
        ['dog', 'grass', 'outdoor', 'animal']
    """

    print('Processing on RAM - ', image_path, os.getcwd())

    if not os.path.exists(pretrained):
        # Repository info
        repo_id = "xinyu1205/recognize-anything"
        target_file = "ram_swin_large_14m.pth"
        save_dir = "backend"

        # Download only the model file
        downloaded_path = hf_hub_download(
            repo_id=repo_id,
            filename=target_file,
            repo_type="space",
            local_dir=save_dir,
            local_dir_use_symlinks=False
        )

        print(f"✅ Download complete. File saved to: {downloaded_path}")

    r=  _model_manager.process_image(image_path, pretrained, image_size)

    print('Tags2 - ', r)
    return r

    # Example: Process multiple images (uncomment to test)
    # print("\n--- Processing another image ---")
    # tags2 = process_image_with_ram("path/to/another/image.jpg")
    # print("Image Tags:", tags2)
    
    # The model will stay loaded for 3 minutes and then automatically unload
    # if no more images are processed

if __name__ == "__main__":
    tags = process_image_with_ram(r"C:\Users\Meet\Downloads\WhatsApp Image 2025-05-11 at 11.17.47 AM.jpeg")
    print(tags)