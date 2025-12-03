#include <Arduino.h>
#include <esp_heap_caps.h>

class thermal_printer
{
    private:
    static HardwareSerial printerSerial;
    static bool globalUpsideDown;
    static void createTestPattern(uint8_t* buffer, uint16_t width, uint16_t height, int pattern);
    static void printTestPattern(uint16_t width, uint16_t height, int pattern);
    static uint8_t* rotateBitmap1bpp_180(const uint8_t* src, uint16_t width, uint16_t height);
    static void printBitmapGS_Method(const unsigned char* progmemData, uint16_t width, uint16_t height);
    static void printBitmapDC2_Method(const unsigned char* progmemData, uint16_t width, uint16_t height);

    public:
    enum UNDERLINE_MODE
    {
        OFF = 0,
        ONE_DOT_THICK = 1,
        TWO_DOT_THICK = 2,
    };
    enum ALIGN_MODE
    {
        LEFT = 0,
        CENTER = 1,
        RIGHT = 2,
    };
    static void setup();

    static void feedLines(uint8_t n);
    static void align(ALIGN_MODE n);
    static void underlineMode(UNDERLINE_MODE n);
    static void inverseMode(bool enable);
    static void upsideDownPrinting(bool b);
    static void setGlobalUpsideDown(bool enable);
    static void setDarknessAndDelay(uint8_t densityPercent, uint16_t breakDelayUs);
    static void spitOut();

    static void printBitmap(uint8_t* imageData, uint16_t width, uint16_t height);
    static void printQRCode(const char* data);
    static void printBarcode_CODE128(const char* data);
    static void printBarcode_UPCA(const char* data);
    static void printBarcode_EAN13(const char* data);

    static void print(const char* data);
    static void println();
    static void println(const char* data);

    static void printTestPage();
};