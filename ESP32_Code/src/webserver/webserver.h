#include <ESPAsyncWebServer.h>
#include <DNSServer.h>
#include <WiFi.h>
#include "../thermal_printer/thermal_printer.h"

class webserver
{
    private:
    struct PRINT_SETTINGS
    {
        thermal_printer::ALIGN_MODE align_mode;
        thermal_printer::UNDERLINE_MODE underline_mode;
        bool inverse_mode;
        bool upside_down_printing;

    };

    static DNSServer dnsServer;
    static AsyncWebServer server;
    static uint8_t bitmapData[];
    static void setupDNS();
    static void serve();
    static void handleBitmapData(AsyncWebServerRequest *request, uint8_t *data, size_t len);
    static bool areAllCharsDigits(const char* str);
    static void parseAndApplyPrintSettings(AsyncWebServerRequest *request);
    static void appyPrintSettings(PRINT_SETTINGS *printSettings);

    static void configAPI();
    static void configWebpages();

    public:
    static void begin();
};