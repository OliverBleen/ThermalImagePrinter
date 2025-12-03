#include <ESPAsyncWebServer.h>
#include <DNSServer.h>
#include <WiFi.h>

class webserver
{
    private:
    static DNSServer dnsServer;
    static AsyncWebServer server;
    static uint8_t bitmapData[];
    static void setupDNS();
    static void serve();
    static void handleBitmapData(AsyncWebServerRequest *request, uint8_t *data, size_t len);
    static bool areAllCharsDigits(const char* str);

    static void configAPI();

    public:
    static void begin();
};