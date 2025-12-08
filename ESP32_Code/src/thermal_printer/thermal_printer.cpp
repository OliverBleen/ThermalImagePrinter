#include "thermal_printer.h"

HardwareSerial thermal_printer::printerSerial = HardwareSerial(2);
bool thermal_printer::globalUpsideDown = false;


void thermal_printer::setup()
{
    printerSerial.begin(9600, SERIAL_8N1, 16, 17);
    thermal_printer::align(ALIGN_MODE::CENTER);
    thermal_printer::setGlobalUpsideDown(false);

}

void thermal_printer::setGlobalUpsideDown(bool enable) {
  globalUpsideDown = enable;
  thermal_printer::upsideDownPrinting(enable ? 1 : 0);  // Apply to printer immediately
  Serial.print("Global upside-down set to: ");
  Serial.println(enable ? "ON" : "OFF");
}


// Set print darkness (% from 50 to 205%) and break delay (µs)
// This controls how dark the print appears and timing between print operations
void thermal_printer::setDarknessAndDelay(uint8_t densityPercent, uint16_t breakDelayUs)
{
  // Clamp density between 50% and 205% in steps of 5%
  if (densityPercent < 50) densityPercent = 50;
  if (densityPercent > 205) densityPercent = 205;

  // Convert % to value (0–31) where 50% + 5*x = density
  uint8_t densityLevel = (densityPercent - 50) / 5;

  // Clamp delay to nearest 250us step (max = 7 * 250 = 1750us)
  if (breakDelayUs > 1750) breakDelayUs = 1750;
  uint8_t breakTimeLevel = breakDelayUs / 250;

  // Merge both into single byte: D7–D5 = breakTimeLevel, D4–D0 = densityLevel
  uint8_t n = (breakTimeLevel << 5) | (densityLevel & 0x1F);

  // Send command: DC2 '#' n
  printerSerial.write(0x12);  // DC2
  printerSerial.write(0x23);  // '#'
  printerSerial.write(n);
}

// Print QR Code with specified data
// Uses the printer's built-in QR code generation capability
void thermal_printer::printQRCode(const char* data) {
  thermal_printer::upsideDownPrinting(thermal_printer::globalUpsideDown ? 1 : 0);

  // [1] Set QR code model (Model 2 is standard)
  printerSerial.write(0x1D);  // GS
  printerSerial.write(0x28);  // (
  printerSerial.write(0x6B);  // k
  printerSerial.write(0x04);  // pL
  printerSerial.write(0x00);  // pH
  printerSerial.write(0x31);  // cn
  printerSerial.write(0x41);  // fn
  printerSerial.write(0x32);  // Model 2
  printerSerial.write(0x00);  // n

  // [2] Set size of module (3–16 dots per module)
  printerSerial.write(0x1D);
  printerSerial.write(0x28);
  printerSerial.write(0x6B);
  printerSerial.write(0x03);
  printerSerial.write(0x00);
  printerSerial.write(0x31);
  printerSerial.write(0x43);
  printerSerial.write(0x06);  // module size = 6

  // [3] Set error correction level (L=48, M=49, Q=50, H=51)
  printerSerial.write(0x1D);
  printerSerial.write(0x28);
  printerSerial.write(0x6B);
  printerSerial.write(0x03);
  printerSerial.write(0x00);
  printerSerial.write(0x31);
  printerSerial.write(0x45);
  printerSerial.write(0x31);  // 'M' level (medium error correction)

  // [4] Store data in QR code buffer
  int len = strlen(data) + 3;  // +3 for command overhead
  byte pL = len & 0xFF;         // Low byte of length
  byte pH = (len >> 8) & 0xFF;  // High byte of length

  printerSerial.write(0x1D);
  printerSerial.write(0x28);
  printerSerial.write(0x6B);
  printerSerial.write(pL);
  printerSerial.write(pH);
  printerSerial.write(0x31);
  printerSerial.write(0x50);
  printerSerial.write(0x30);
  printerSerial.print(data);  // Actual QR code data

  // [5] Print the stored QR code
  printerSerial.write(0x1D);
  printerSerial.write(0x28);
  printerSerial.write(0x6B);
  printerSerial.write(0x03);
  printerSerial.write(0x00);
  printerSerial.write(0x31);
  printerSerial.write(0x51);
  printerSerial.write(0x30);

  Serial.print("Printed QR Code: ");
  Serial.println(data);
}

// Print CODE128 barcode - variable length alphanumeric
void thermal_printer::printBarcode_CODE128(const char* data) {
  thermal_printer::upsideDownPrinting(globalUpsideDown ? 1 : 0);
  
  // Set barcode height (in dots)
  printerSerial.write(0x1D);  // GS
  printerSerial.write(0x68);  // h
  printerSerial.write(0x50);  // Height = 80 dots
  delay(100);

  // Set barcode width (module width)
  printerSerial.write(0x1D);  // GS
  printerSerial.write(0x77);  // w
  printerSerial.write(0x02);  // Width = 2 dots per module
  delay(100);

  // Set HRI (Human Readable Interpretation) position
  printerSerial.write(0x1D);  // GS
  printerSerial.write(0x48);  // H
  printerSerial.write(0x02);  // HRI below barcode
  delay(100);

  // Print the barcode
  printerSerial.write(0x1D);           // GS
  printerSerial.write(0x6B);           // k
  printerSerial.write(0x49);           // CODE128 type
  printerSerial.write(strlen(data));  // Data length
  printerSerial.print(data);           // Barcode data

  Serial.print("Printed CODE128: ");
  Serial.println(data);
}

// Print UPC-A barcode - requires exactly 11 digits
void thermal_printer::printBarcode_UPCA(const char* data) {
  thermal_printer::upsideDownPrinting(globalUpsideDown ? 1 : 0);
  
  // Validate data length for UPC-A
  if (strlen(data) != 11) {
    Serial.println("UPC-A requires 11 digits");
    return;
  }

  // Set barcode parameters (same as CODE128)
  printerSerial.write(0x1D);  // GS
  printerSerial.write(0x68);  // h
  printerSerial.write(0x50);  // Height = 80 dots
  delay(100);

  printerSerial.write(0x1D);  // GS
  printerSerial.write(0x77);  // w
  printerSerial.write(0x02);  // Width = 2
  delay(100);

  printerSerial.write(0x1D);  // GS
  printerSerial.write(0x48);  // H
  printerSerial.write(0x02);  // HRI below
  delay(100);

  // Print UPC-A barcode
  printerSerial.write(0x1D);           // GS
  printerSerial.write(0x6B);           // k
  printerSerial.write(0x41);           // UPC-A type
  printerSerial.write(strlen(data));  // Data length
  printerSerial.print(data);

  Serial.print("Printed UPC-A: ");
  Serial.println(data);
}

// Print EAN13 barcode - requires exactly 12 digits
void thermal_printer::printBarcode_EAN13(const char* data) {
  thermal_printer::upsideDownPrinting(globalUpsideDown ? 1 : 0);
  
  // Validate data length for EAN13
  if (strlen(data) != 12) {
    Serial.println("EAN13 requires 12 digits");
    return;
  }

  // Set barcode parameters (same as others)
  printerSerial.write(0x1D);  // GS
  printerSerial.write(0x68);  // h
  printerSerial.write(0x50);  // Height = 80 dots
  delay(100);

  printerSerial.write(0x1D);  // GS
  printerSerial.write(0x77);  // w
  printerSerial.write(0x02);  // Width = 2
  delay(100);

  printerSerial.write(0x1D);  // GS
  printerSerial.write(0x48);  // H
  printerSerial.write(0x02);  // HRI below
  delay(100);

  // Print EAN13 barcode
  printerSerial.write(0x1D);           // GS
  printerSerial.write(0x6B);           // k
  printerSerial.write(0x43);           // EAN13 type
  printerSerial.write(strlen(data));  // Data length
  printerSerial.print(data);

  Serial.print("Printed EAN13: ");
  Serial.println(data);
}

// Print and feed n lines - creates vertical spacing
void thermal_printer::feedLines(uint8_t n) {
    for (uint8_t i = 0; i < n; i++)
    {
        println();
    }
}

// Turn upside-down printing mode on/off
void thermal_printer::upsideDownPrinting(bool b) {
  printerSerial.write(0x1B);  // ESC
  printerSerial.write(0x7B);  // {
  printerSerial.write(b);     // 0/1 - OFF/ON
}

// Set underline mode - 0=off, 1=1dot thick, 2=2dots thick
void thermal_printer::underlineMode(UNDERLINE_MODE n) {
  printerSerial.write(0x1B);  // ESC
  printerSerial.write(0x2D);  // -
  printerSerial.write(n);     // 0/1/2
}

// Set text justification - 0=left, 1=center, 2=right
void thermal_printer::align(ALIGN_MODE n) {
  printerSerial.write(0x1B);  // ESC
  printerSerial.write(0x61);  // a
  printerSerial.write(n);     // 0/1/2
}

// Turn inverse (white on black) mode on/off
void thermal_printer::inverseMode(bool enable) {
  printerSerial.write(0x1D);  // GS
  printerSerial.write(0x42);  // B
  printerSerial.write(enable);     // 0/1 - OFF/ON
}

// Print bitmap image using standard GS v command - optimized for memory usage
void thermal_printer::printBitmap(uint8_t* imageData, uint16_t width, uint16_t height) {
  // Validate dimensions to prevent printer damage or memory issues
  if (width <= 0 || height <= 0 || width > 512 || height > 1662) {
    Serial.println("Invalid image dimensions");
    return;
  }

  // Calculate bytes per line (width must be multiple of 8 for 1-bit images)
  int bytesPerLine = (width + 7) / 8;

  // Use normal mode (m=0) for standard density printing
  uint8_t m = 0;

  // Calculate command parameters for image size
  uint8_t xL = bytesPerLine & 0xFF;        // Low byte of horizontal bytes
  uint8_t xH = (bytesPerLine >> 8) & 0xFF; // High byte of horizontal bytes
  uint8_t yL = height & 0xFF;              // Low byte of vertical dots
  uint8_t yH = (height >> 8) & 0xFF;       // High byte of vertical dots

  // Send GS v command for bitmap printing
  printerSerial.write(0x1D);  // GS
  printerSerial.write(0x76);  // v
  printerSerial.write(0x30);  // 0
  printerSerial.write(m);     // mode
  printerSerial.write(xL);    // xL
  printerSerial.write(xH);    // xH
  printerSerial.write(yL);    // yL
  printerSerial.write(yH);    // yH

  // Send image data efficiently
  int totalBytes = bytesPerLine * height;
  for (int i = 0; i < totalBytes; i++) {
    printerSerial.write(imageData[i]);
  }

  Serial.println("Bitmap printed: " + String(width) + "x" + String(height));
}

// Create test pattern in bitmap buffer - useful for printer testing
void thermal_printer::createTestPattern(uint8_t* buffer, uint16_t width, uint16_t height, int pattern) {
  int bytesPerLine = (width + 7) / 8;

  // Generate different test patterns
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < bytesPerLine; x++) {
      uint8_t byte_val = 0;

      // Process 8 pixels at a time (1 byte)
      for (int bit = 0; bit < 8; bit++) {
        int pixel_x = x * 8 + bit;
        if (pixel_x >= width) break; // Don't exceed image width

        bool pixel = false;
        // Generate different patterns based on pattern parameter
        switch (pattern) {
          case 0:  // Checkerboard pattern
            pixel = ((pixel_x / 8) + (y / 8)) % 2 == 0;
            break;
          case 1:  // Horizontal lines
            pixel = (y % 4) < 2;
            break;
          case 2:  // Vertical lines
            pixel = (pixel_x % 4) < 2;
            break;
          case 3:  // Diagonal lines
            pixel = ((pixel_x + y) % 8) < 4;
            break;
          default: // Default diagonal pattern
            pixel = (pixel_x + y) % 2 == 0;
        }

        // Set bit in byte if pixel should be printed
        if (pixel) {
          byte_val |= (0x80 >> bit);
        }
      }

      buffer[y * bytesPerLine + x] = byte_val;
    }
  }
}

// Print a test pattern - useful for testing printer functionality
void thermal_printer::printTestPattern(uint16_t width, uint16_t height, int pattern) {
  // Limit size to prevent memory issues on ESP32
  if (width > 384 || height > 400) {
    Serial.println("Image too large for ESP32 memory");
    return;
  }

  int bytesPerLine = (width + 7) / 8;
  int totalBytes = bytesPerLine * height;

  // Allocate memory for image data
  uint8_t* imageData = (uint8_t*)malloc(totalBytes);
  if (imageData == NULL) {
    Serial.println("Failed to allocate memory for image");
    return;
  }

  // Create the test pattern
  createTestPattern(imageData, width, height, pattern);

  // Print the bitmap
  printBitmap(imageData, width, height);

  // Free allocated memory
  free(imageData);
}

// Alternative bitmap printing method using DC2 * command
// This method prints line by line to avoid spacing issues
void thermal_printer::printBitmapDC2_Method(const unsigned char* progmemData, uint16_t width, uint16_t height) {
  upsideDownPrinting(globalUpsideDown ? 1 : 0);

  // Set printer to maximum darkness for bitmap printing
  printerSerial.write(0x12);  // DC2
  printerSerial.write(0x23);  // #
  printerSerial.write(0x9F);  // Maximum darkness setting
  delay(50);

  Serial.println("Using DC2 * method (Method 1)...");

  int bytesPerLine = (width + 7) / 8;

  // Print line by line to avoid spacing issues
  for (int line = 0; line < height; line++) {
    // Send DC2 * command for each line
    printerSerial.write(0x12);                 // DC2
    printerSerial.write(0x2A);                 // *
    printerSerial.write(0x01);                 // r = 1 line height
    printerSerial.write(bytesPerLine & 0xFF);  // n = bytes per line

    // Send one line of data from PROGMEM
    for (int i = 0; i < bytesPerLine; i++) {
      uint8_t byte_val = pgm_read_byte(progmemData + (line * bytesPerLine) + i);
      printerSerial.write(byte_val);
    }

    // Small delay between lines for printer processing
    delayMicroseconds(10);
  }

  Serial.println("DC2 * method completed!");
  
  // Reset printer darkness to normal
  printerSerial.write(0x12);  // DC2
  printerSerial.write(0x23);  // #
  printerSerial.write(0x58);  // Normal darkness setting
  delay(50);
}

// Helper function: Rotate a 1bpp bitmap by 180 degrees
// Returns a newly allocated buffer that caller must free()
// Used for upside-down printing when globalUpsideDown is enabled
uint8_t* thermal_printer::rotateBitmap1bpp_180(const uint8_t* src, uint16_t width, uint16_t height) {
  int bytesPerLine = (width + 7) / 8;
  int totalBytes = bytesPerLine * height;
  
  // Allocate destination buffer and clear it
  uint8_t* dst = (uint8_t*)calloc(totalBytes, 1);
  if (!dst) return nullptr;
  
  // Rotate each pixel by 180 degrees
  for (int y = 0; y < height; ++y) {
    for (int x = 0; x < width; ++x) {
      // Extract pixel from source
      int srcByte = y * bytesPerLine + (x / 8);
      int srcBit = 7 - (x % 8);
      bool pixel = (src[srcByte] >> srcBit) & 1;
      
      // Calculate rotated position
      int nx = width - 1 - x;
      int ny = height - 1 - y;
      
      // Set pixel in destination
      int dstByte = ny * bytesPerLine + (nx / 8);
      int dstBit = 7 - (nx % 8);
      if (pixel) dst[dstByte] |= (1 << dstBit);
    }
  }
  return dst;
}

// Main bitmap printing method using GS v command with chunking
// This is the primary method for printing large images efficiently
void thermal_printer::printBitmapGS_Method(const unsigned char* progmemData, uint16_t width, uint16_t height) {
  upsideDownPrinting(globalUpsideDown ? 1 : 0);
  align(ALIGN_MODE::CENTER);  // Center align for images
  
  // Set printer to maximum darkness for better image quality
  printerSerial.write(0x12);  // DC2
  printerSerial.write(0x23);  // #
  printerSerial.write(0x9F);  // Maximum darkness
  delay(50);

  const unsigned char* dataToPrint = progmemData;
  int w = width, h = height;
  uint8_t* rotated = nullptr;

  // Handle global upside-down printing by rotating the entire image
  if (globalUpsideDown) {
    // Copy from PROGMEM to RAM, then rotate 180°
    int bytesPerLine = (width + 7) / 8;
    int totalBytes = bytesPerLine * height;
    
    uint8_t* ramCopy = (uint8_t*)malloc(totalBytes);
    if (ramCopy) {
      // Copy image data from PROGMEM to RAM for rotation
      for (int i = 0; i < totalBytes; ++i)
        ramCopy[i] = pgm_read_byte(progmemData + i);
      
      // Rotate the image 180 degrees
      rotated = rotateBitmap1bpp_180(ramCopy, width, height);
      free(ramCopy);
      
      if (rotated) {
        dataToPrint = rotated;
      }
    }
  }

  // Validate image dimensions
  if (w <= 0 || h <= 0) {
    Serial.println("Invalid image size");
    if (rotated) free(rotated);
    return;
  }

  int bytesPerLine = (w + 7) / 8;
  int totalChunks = (h + 23) / 24;  // Process in 24-line chunks for memory efficiency

  // Set line spacing to 0 for seamless image printing
  printerSerial.write(0x1B);  // ESC
  printerSerial.write(0x33);  // '3'
  printerSerial.write(0x00);  // 0 dots line spacing

  // Process image in chunks to manage memory usage
  for (int chunk = 0; chunk < totalChunks; chunk++) {
    int linesInChunk = min(24, h - chunk * 24);  // Last chunk may be smaller
    
    // Calculate chunk parameters
    int yL = linesInChunk & 0xFF;
    int yH = (linesInChunk >> 8) & 0xFF;
    int xL = bytesPerLine & 0xFF;
    int xH = (bytesPerLine >> 8) & 0xFF;

    // Send GS v command for this chunk
    printerSerial.write(0x1D);  // GS
    printerSerial.write(0x76);  // 'v'
    printerSerial.write(0x30);  // '0'
    printerSerial.write(0x00);  // m = 0 (normal density)
    printerSerial.write(xL);
    printerSerial.write(xH);
    printerSerial.write(yL);
    printerSerial.write(yH);

    // Send chunk data
    for (int row = 0; row < linesInChunk; row++) {
      int baseIndex = (chunk * 24 + row) * bytesPerLine;
      for (int col = 0; col < bytesPerLine; col++) {
        printerSerial.write(dataToPrint[baseIndex + col]);
      }
    }
    
    delay(30);  // Allow printer to process chunk
  }

  // Feed paper and restore normal settings
  printerSerial.write(0x1B);  // ESC
  printerSerial.write(0x64);  // d
  printerSerial.write(3);     // Feed 3 lines

  Serial.println("Finished printing image in chunks.");
  
  // Reset printer darkness to normal
  printerSerial.write(0x12);  // DC2
  printerSerial.write(0x23);  // #
  printerSerial.write(0x58);  // Normal darkness
  delay(50);
  
  // Clean up rotated image memory if allocated
  if (rotated) free(rotated);
}

void thermal_printer::print(const char* data)
{
    printerSerial.print(data);
}

void thermal_printer::println()
{
    printerSerial.println();
}

void thermal_printer::println(const char* data)
{
    printerSerial.println(data);
}

void thermal_printer::spitOut()
{
    feedLines(3);
}

void thermal_printer::printTestPage()
{

    align(ALIGN_MODE::CENTER);
    println("CHARACTER MAP");
    align(ALIGN_MODE::LEFT);
    println("      01234567  89ABCDEF");
    for (uint8_t i = 0; i < 16; i++)
    {
        print("   ");
        if(i < 10)
            printerSerial.write(i+0x30);
        else
            printerSerial.write(i+0x37);
        print("-");

        if(i > 1)
        {
          for (uint8_t j = 0; j < 8; j++)
          {
              printerSerial.write(i << 4 | j);
          }
          print("  ");
          for (uint8_t j = 4; j < 16; j++)
          {
              printerSerial.write(i << 4 | j);
          }
        }
        println();
    }
    align(ALIGN_MODE::CENTER);
    delay(200);
    printTestPattern(200, 200, 0);
    delay(200);
    char code128[] = "1234567890";
    printBarcode_CODE128(code128);
    delay(200);
    char qrCode[] = "https://oliverbleen.net";
    printQRCode(qrCode);
}