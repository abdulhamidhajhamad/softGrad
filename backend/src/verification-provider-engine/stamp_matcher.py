#!/usr/bin/env python3
"""
🔐 Stamp Matcher - Official Stamp Verification Engine
=====================================================
This script uses OpenCV to verify the presence of official stamps
in uploaded documents using multi-scale template matching.

Usage:
    python stamp_matcher.py <document_url> <stamp_type>
    
Arguments:
    document_url: URL of the document image (from Supabase storage)
    stamp_type: Either "id" or "business"
    
Output:
    JSON object with { "found": boolean, "score": number, "error": string? }
"""

import sys
import json
import os
import urllib.request
import ssl
import numpy as np

try:
    import cv2
except ImportError:
    print(json.dumps({
        "found": False,
        "score": 0,
        "error": "OpenCV not installed. Run: pip install opencv-python"
    }))
    sys.exit(1)


# ============================================================================
# 📁 CONFIGURATION
# ============================================================================

# Get the directory where this script is located
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ANCHORS_DIR = os.path.join(SCRIPT_DIR, "anchors")

# Anchor files for different stamp types
ANCHOR_FILES = {
    "id": "id_anchor.png",           # National ID stamp (Eagle stamp - ختم النسر)
    "business": "business_anchor.png" # Business/Commercial stamp
}

# Matching thresholds (minimum similarity scores)
# Note: These values should be tuned based on anchor image quality
# Lower = more lenient, Higher = more strict
THRESHOLDS = {
    "id": 0.30,        # 30% for ID stamps
    "business": 0.30   # 30% for business stamps
}

# Scale range for multi-scale matching
SCALE_RANGE = np.linspace(0.3, 1.5, 25)  # From 30% to 150% in 25 steps


# ============================================================================
# 🖼️ IMAGE PROCESSING FUNCTIONS
# ============================================================================

def download_image(url: str) -> np.ndarray:
    """
    Download image from URL and convert to OpenCV format.
    
    Args:
        url: URL of the image to download
        
    Returns:
        OpenCV image array (BGR format)
    """
    try:
        # Create SSL context that doesn't verify certificates (for development)
        ssl_context = ssl.create_default_context()
        ssl_context.check_hostname = False
        ssl_context.verify_mode = ssl.CERT_NONE
        
        # Add headers to mimic browser request
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
        
        request = urllib.request.Request(url, headers=headers)
        
        with urllib.request.urlopen(request, context=ssl_context, timeout=30) as response:
            image_data = response.read()
            
        # Convert bytes to numpy array
        nparr = np.frombuffer(image_data, np.uint8)
        
        # Decode image
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if image is None:
            raise ValueError("Failed to decode image from URL")
            
        return image
        
    except Exception as e:
        raise RuntimeError(f"Failed to download image: {str(e)}")


def preprocess_image(image: np.ndarray) -> np.ndarray:
    """
    Preprocess image for stamp detection:
    1. Convert to grayscale
    2. Apply Gaussian blur to reduce noise
    3. Apply binary thresholding for high contrast
    
    Args:
        image: Input BGR image
        
    Returns:
        Preprocessed binary image
    """
    # Convert to grayscale
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    
    # Apply Gaussian blur to reduce noise
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)
    
    # Apply adaptive thresholding for better results with varying lighting
    # This creates a high-contrast black and white image
    binary = cv2.adaptiveThreshold(
        blurred,
        255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY,
        11,  # Block size
        2    # C constant
    )
    
    return binary


def load_anchor(stamp_type: str) -> np.ndarray:
    """
    Load and preprocess the anchor/template image for matching.
    
    Args:
        stamp_type: Type of stamp ("id" or "business")
        
    Returns:
        Preprocessed anchor image
    """
    if stamp_type not in ANCHOR_FILES:
        raise ValueError(f"Unknown stamp type: {stamp_type}. Use 'id' or 'business'")
    
    anchor_path = os.path.join(ANCHORS_DIR, ANCHOR_FILES[stamp_type])
    
    if not os.path.exists(anchor_path):
        raise FileNotFoundError(
            f"Anchor file not found: {anchor_path}\n"
            f"Please add {ANCHOR_FILES[stamp_type]} to the anchors/ folder"
        )
    
    anchor = cv2.imread(anchor_path, cv2.IMREAD_COLOR)
    
    if anchor is None:
        raise ValueError(f"Failed to load anchor image: {anchor_path}")
    
    # Preprocess anchor the same way as the document
    return preprocess_image(anchor)


# ============================================================================
# 🔍 MULTI-SCALE TEMPLATE MATCHING
# ============================================================================

def multi_scale_template_match(
    document: np.ndarray,
    template: np.ndarray,
    scales: np.ndarray = SCALE_RANGE
) -> tuple:
    """
    Perform multi-scale template matching to find the stamp in the document.
    
    This algorithm:
    1. Scales the template to different sizes
    2. Performs template matching at each scale
    3. Returns the best match score across all scales
    
    Args:
        document: Preprocessed document image (binary)
        template: Preprocessed template/anchor image (binary)
        scales: Array of scale factors to try
        
    Returns:
        Tuple of (best_score, best_location, best_scale)
    """
    best_score = 0
    best_location = None
    best_scale = 1.0
    
    # Get template dimensions
    tH, tW = template.shape[:2]
    
    # Get document dimensions
    dH, dW = document.shape[:2]
    
    for scale in scales:
        # Resize template
        new_width = int(tW * scale)
        new_height = int(tH * scale)
        
        # Skip if template is larger than document
        if new_width >= dW or new_height >= dH:
            continue
            
        # Skip if template is too small
        if new_width < 20 or new_height < 20:
            continue
        
        resized_template = cv2.resize(
            template, 
            (new_width, new_height),
            interpolation=cv2.INTER_AREA if scale < 1 else cv2.INTER_LINEAR
        )
        
        # Perform template matching using normalized cross-correlation
        result = cv2.matchTemplate(
            document, 
            resized_template, 
            cv2.TM_CCOEFF_NORMED
        )
        
        # Find the best match location and score
        min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(result)
        
        if max_val > best_score:
            best_score = max_val
            best_location = max_loc
            best_scale = scale
    
    return best_score, best_location, best_scale


def verify_stamp(document_url: str, stamp_type: str) -> dict:
    """
    Main function to verify if an official stamp exists in the document.
    
    Args:
        document_url: URL of the document image
        stamp_type: Type of stamp to look for ("id" or "business")
        
    Returns:
        Dictionary with verification results
    """
    result = {
        "found": False,
        "score": 0.0,
        "error": None,
        "threshold": THRESHOLDS.get(stamp_type, 0.5),
        "stamp_type": stamp_type
    }
    
    try:
        # Step 1: Download document image
        document = download_image(document_url)
        
        # Step 2: Preprocess document
        processed_doc = preprocess_image(document)
        
        # Step 3: Load and preprocess anchor/template
        anchor = load_anchor(stamp_type)
        
        # Step 4: Perform multi-scale template matching
        score, location, scale = multi_scale_template_match(
            processed_doc, 
            anchor, 
            SCALE_RANGE
        )
        
        # Step 5: Evaluate result
        threshold = THRESHOLDS[stamp_type]
        result["score"] = round(float(score), 4)
        result["found"] = score >= threshold
        result["matched_scale"] = round(float(scale), 2)
        
        if location:
            result["location"] = {
                "x": int(location[0]),
                "y": int(location[1])
            }
        
    except FileNotFoundError as e:
        result["error"] = str(e)
        result["found"] = False
        
    except Exception as e:
        result["error"] = f"Verification failed: {str(e)}"
        result["found"] = False
    
    return result


# ============================================================================
# 🚀 MAIN ENTRY POINT
# ============================================================================

def main():
    """
    Main entry point for CLI usage.
    
    Usage:
        python stamp_matcher.py <document_url> <stamp_type>
    """
    if len(sys.argv) < 3:
        print(json.dumps({
            "found": False,
            "score": 0,
            "error": "Usage: python stamp_matcher.py <document_url> <stamp_type>"
        }))
        sys.exit(1)
    
    document_url = sys.argv[1]
    stamp_type = sys.argv[2].lower()
    
    # Validate stamp type
    if stamp_type not in ["id", "business"]:
        print(json.dumps({
            "found": False,
            "score": 0,
            "error": f"Invalid stamp_type '{stamp_type}'. Use 'id' or 'business'"
        }))
        sys.exit(1)
    
    # Perform verification
    result = verify_stamp(document_url, stamp_type)
    
    # Output JSON result
    print(json.dumps(result))
    
    # Exit with appropriate code
    sys.exit(0 if result["found"] else 1)


if __name__ == "__main__":
    main()
