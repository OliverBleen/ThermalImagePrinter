#include <ESPAsyncWebServer.h>
#include <DNSServer.h>
#include <WiFi.h>

class webserver
{
    private:
    static DNSServer dnsServer;
    static AsyncWebServer server;
    static void setupDNS();
    static void serve();

    static void configAPI();

    public:
    static void begin();
};