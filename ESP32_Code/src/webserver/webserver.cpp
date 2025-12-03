#include "webserver.h"
#include "../defines.h"
#include <esp_wifi.h>			//Used for mpdu_rx_disable android workaround
#include <stdlib.h>

DNSServer webserver::dnsServer;
AsyncWebServer webserver::server(80);

void webserver::begin()
{
    WiFi.mode(WIFI_MODE_AP);
    WiFi.softAPConfig(IPAddress(LOCAL_IP), IPAddress(GATEWAY_IP), IPAddress(SUBNET_MASK));
    WiFi.softAP(WIFI_SSID, WIFI_PASSWORD, WIFI_CHANNEL, 0, WIFI_MAX_CONNECTIONS);
    // Disable AMPDU RX on the ESP32 WiFi to fix a bug on Android
	esp_wifi_stop();
	esp_wifi_deinit();
	wifi_init_config_t my_config = WIFI_INIT_CONFIG_DEFAULT();
	my_config.ampdu_rx_enable = false;
	esp_wifi_init(&my_config);
	esp_wifi_start();
	vTaskDelay(100 / portTICK_PERIOD_MS);  // Add a small delay

    setupDNS();
    serve();
}
void webserver::setupDNS()
{
    dnsServer.setTTL(DNS_TTL);
    dnsServer.start(53, "*", IPAddress(LOCAL_IP));
}
void webserver::serve()
{
    //======================== Webserver ========================
	// WARNING IOS (and maybe macos) WILL NOT POP UP IF IT CONTAINS THE WORD "Success" https://www.esp8266.com/viewtopic.php?f=34&t=4398
	// SAFARI (IOS) IS STUPID, G-ZIPPED FILES CAN'T END IN .GZ https://github.com/homieiot/homie-esp8266/issues/476 this is fixed by the webserver serve static function.
	// SAFARI (IOS) there is a 128KB limit to the size of the HTML. The HTML can reference external resources/images that bring the total over 128KB
	// SAFARI (IOS) popup browser has some severe limitations (javascript disabled, cookies disabled)

	// Required
	server.on("/connecttest.txt", [](AsyncWebServerRequest *request) { request->redirect("http://logout.net"); });	// windows 11 captive portal workaround
	server.on("/wpad.dat", [](AsyncWebServerRequest *request) { request->send(404); });								// Honestly don't understand what this is but a 404 stops win 10 keep calling this repeatedly and panicking the esp32 :)

	// Background responses: Probably not all are Required, but some are. Others might speed things up?
	// A Tier (commonly used by modern systems)
	server.on("/generate_204", [](AsyncWebServerRequest *request) { request->redirect(LOCAL_IP_STRING); });		   // android captive portal redirect
	server.on("/redirect", [](AsyncWebServerRequest *request) { request->redirect(LOCAL_IP_STRING); });			   // microsoft redirect
	server.on("/hotspot-detect.html", [](AsyncWebServerRequest *request) { request->redirect(LOCAL_IP_STRING); });  // apple call home
	server.on("/canonical.html", [](AsyncWebServerRequest *request) { request->redirect(LOCAL_IP_STRING); });	   // firefox captive portal call home
	server.on("/success.txt", [](AsyncWebServerRequest *request) { request->send(200); });					   // firefox captive portal call home
	server.on("/ncsi.txt", [](AsyncWebServerRequest *request) { request->redirect(LOCAL_IP_STRING); });			   // windows call home

	// B Tier (uncommon)
	//  server.on("/chrome-variations/seed",[](AsyncWebServerRequest *request){request->send(200);}); //chrome captive portal call home
	//  server.on("/service/update2/json",[](AsyncWebServerRequest *request){request->send(200);}); //firefox?
	//  server.on("/chat",[](AsyncWebServerRequest *request){request->send(404);}); //No stop asking Whatsapp, there is no internet connection
	//  server.on("/startpage",[](AsyncWebServerRequest *request){request->redirect(localIPURL);});

	// return 404 to webpage icon
	server.on("/favicon.ico", [](AsyncWebServerRequest *request) { request->send(404); });	// webpage icon

	// the catch all
	server.onNotFound([](AsyncWebServerRequest *request) {
		request->redirect(LOCAL_IP_STRING);
		Serial.print("onnotfound ");
		Serial.print(request->host());	// This gives some insight into whatever was being requested on the serial monitor
		Serial.print(" ");
		Serial.print(request->url());
		Serial.print(" sent redirect to ");
        Serial.println(LOCAL_IP_STRING);
	});

    server.on("/", HTTP_ANY, [] (AsyncWebServerRequest *request)
    {
        Serial.println("Client get /");
        request->send(200, "text/html", "<!DOCTYPE HTML>\n<html>\n<title>T.I.P</title><p>You are connected to the T.I.P</p>\n</html>");
    });

	configAPI();

    server.begin();
}


void webserver::configAPI()
{
	server.on("/api/tip/print", HTTP_POST, [] (AsyncWebServerRequest *request)
	{
		Serial.println("/api/tip/print");
		if(!(request->hasParam("data")))
		{
			Serial.println("Missing param 'data' -> 400");
			request->send(400, "text", "Missing param 'data'");
			return;
		}
		String data = request->getParam("data")->value();

		Serial.println(data);
		request->send(200);
	});
	server.on("/api/tip/println", HTTP_POST, [] (AsyncWebServerRequest *request)
	{
		Serial.println("/api/tip/println");
		String data = "";
		if(request->hasParam("data"))
		{
			data = request->getParam("data")->value();
		}
		
		Serial.println(data);
		request->send(200);
	});

	server.on("/api/tip/printQRCode", HTTP_POST, [] (AsyncWebServerRequest *request)
	{
		Serial.println("/api/tip/printQRCode");
		if(!(request->hasParam("data")))
		{
			Serial.println("Missing param 'data' -> 400");
			request->send(400, "text", "Missing param 'data'");
			return;
		}
		String data = request->getParam("data")->value();

		Serial.println(data);
		request->send(200);
	});

	server.on("/api/tip/printBarcode_CODE128", HTTP_POST, [] (AsyncWebServerRequest *request)
	{
		Serial.println("/api/tip/printBarcode_CODE128");
		if(!(request->hasParam("data")))
		{
			Serial.println("Missing param 'data' -> 400");
			request->send(400, "text", "Missing param 'data'");
			return;
		}
		String data = request->getParam("data")->value();
		
		Serial.println(data);
		request->send(200);
	});

	server.on("/api/tip/printBarcode_UPCA", HTTP_POST, [] (AsyncWebServerRequest *request)
	{
		Serial.println("/api/tip/printBarcode_UPCA");
		if(!(request->hasParam("data")))
		{
			Serial.println("Missing param 'data' -> 400");
			request->send(400, "text", "Missing param 'data'");
			return;
		}
		String data = request->getParam("data")->value();
		
		Serial.println(data);
		request->send(200);
	});

	server.on("/api/tip/printBarcode_EAN13", HTTP_POST, [] (AsyncWebServerRequest *request)
	{
		Serial.println("/api/tip/printBarcode_EAN13");
		if(!(request->hasParam("data")))
		{
			Serial.println("Missing param 'data' -> 400");
			request->send(400, "text", "Missing param 'data'");
			return;
		}
		String data = request->getParam("data")->value();
		
		Serial.println(data);
		request->send(200);
	});

	server.on("/api/tip/feedLines", HTTP_POST, [] (AsyncWebServerRequest *request)
	{
		Serial.println("/api/tip/feedLines");
		if(!(request->hasParam("data")))
		{
			Serial.println("Missing param 'data' -> 400");
			request->send(400, "text", "Missing param 'data'");
			return;
		}
		String data = request->getParam("data")->value();
		
		if(data.length() > 2)
		{
			Serial.println("Invalid value > 99 -> 400");
			request->send(400, "text", "Invalid value > 100");
			return;
		}

		for (uint8_t i = 0; i < data.length(); i++)
		{
			if(!isDigit(data[i]))
			{
				Serial.println("Invalid value not digit -> 400");
				request->send(400, "text", "Invalid value not digit");
				return;
			}
		}
		
		uint8_t lines = strtoul(data.c_str(), NULL, 10);

		Serial.println(lines);
		request->send(200);
	});
	
	server.on("/api/tip/spitOut", HTTP_POST, [] (AsyncWebServerRequest *request)
	{
		Serial.println("/api/tip/spitOut");
		
		request->send(200);
	});
}