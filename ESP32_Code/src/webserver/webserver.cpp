#include "webserver.h"
#include "../defines.h"
#include <esp_wifi.h>			//Used for mpdu_rx_disable android workaround
#include <stdlib.h>
#include "webpages.h"

DNSServer webserver::dnsServer;
AsyncWebServer webserver::server(80);
uint8_t webserver::bitmapData[(384*10 +7)/8];

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
		if (request->url() == "/api/tip/uploadBitmapData")
      		return; // response object already created by onRequestBody

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

	server.onRequestBody([](AsyncWebServerRequest *request, uint8_t *data, size_t len, size_t index, size_t total){
		if (request->url() == "/api/tip/uploadBitmapData" && request->method() == HTTP_POST)
			handleBitmapData(request, data, len);
	});


	configAPI();
	configWebpages();

    server.begin();
}


void webserver::configAPI()
{
	server.on("/api/tip/print", HTTP_POST, [] (AsyncWebServerRequest *request)
	{
		Serial.println("/api/tip/print");
		webserver::parseAndApplyPrintSettings(request);
		if(!(request->hasParam("data")))
		{
			Serial.println("Missing param 'data' -> 400");
			request->send(400, "text", "Missing param 'data'");
			return;
		}
		String data = request->getParam("data")->value();

		thermal_printer::print(data.c_str());
		Serial.println(data);
		request->send(200);
	});
	server.on("/api/tip/println", HTTP_POST, [] (AsyncWebServerRequest *request)
	{
		Serial.println("/api/tip/println");
		webserver::parseAndApplyPrintSettings(request);
		String data = "";
		if(request->hasParam("data"))
		{
			data = request->getParam("data")->value();
		}
		
		thermal_printer::println(data.c_str());
		Serial.println(data);
		request->send(200);
	});

	server.on("/api/tip/printBitmap", HTTP_POST, [] (AsyncWebServerRequest *request)
	{
		Serial.println("/api/tip/printBitmap");
		webserver::parseAndApplyPrintSettings(request);
		if(!(request->hasParam("width")))
		{
			Serial.println("Missing param 'width' -> 400");
			request->send(400, "text", "Missing param 'width'");
			return;
		}
		if(!(request->hasParam("height")))
		{
			Serial.println("Missing param 'height' -> 400");
			request->send(400, "text", "Missing param 'height'");
			return;
		}
		String data = request->getParam("width")->value();
		
		if(data.length() > 3)
		{
			Serial.println("Invalid value for 'width' > 999 -> 400");
			request->send(400, "text", "Invalid value for 'width' > 999");
			return;
		}

		if(!areAllCharsDigits(data.c_str()))
		{
			Serial.println("Invalid value for 'width' not digit -> 400");
			request->send(400, "text", "Invalid value for 'width' not digit");
			return;
		}
		uint16_t width = strtoul(data.c_str(), NULL, 10);

		data = request->getParam("height")->value();
		
		if(data.length() > 3)
		{
			Serial.println("Invalid value for 'height' > 999 -> 400");
			request->send(400, "text", "Invalid value for 'height' > 999");
			return;
		}

		if(!areAllCharsDigits(data.c_str()))
		{
			Serial.println("Invalid value for 'height' not digit -> 400");
			request->send(400, "text", "Invalid value for 'height' not digit");
			return;
		}
		uint16_t height = strtoul(data.c_str(), NULL, 10);

		if(width > 384)
		{
			Serial.println("Invalid value for 'width' > 384");
			request->send(400, "text", "Invalid value for 'width' > 384");
			return;
		}
		if(height > 10)
		{
			Serial.println("Invalid value for 'height' > 10");
			request->send(400, "text", "Invalid value for 'height' > 10");
			return;
		}

		thermal_printer::printBitmap(bitmapData, width, height);

		request->send(200);
	});

	server.on("/api/tip/printQRCode", HTTP_POST, [] (AsyncWebServerRequest *request)
	{
		Serial.println("/api/tip/printQRCode");
		webserver::parseAndApplyPrintSettings(request);
		if(!(request->hasParam("data")))
		{
			Serial.println("Missing param 'data' -> 400");
			request->send(400, "text", "Missing param 'data'");
			return;
		}
		String data = request->getParam("data")->value();

		thermal_printer::printQRCode(data.c_str());
		Serial.println(data);
		request->send(200);
	});

	server.on("/api/tip/printBarcode_CODE128", HTTP_POST, [] (AsyncWebServerRequest *request)
	{
		Serial.println("/api/tip/printBarcode_CODE128");
		webserver::parseAndApplyPrintSettings(request);
		if(!(request->hasParam("data")))
		{
			Serial.println("Missing param 'data' -> 400");
			request->send(400, "text", "Missing param 'data'");
			return;
		}
		String data = request->getParam("data")->value();
		
		thermal_printer::printBarcode_CODE128(data.c_str());
		Serial.println(data);
		request->send(200);
	});

	server.on("/api/tip/printBarcode_UPCA", HTTP_POST, [] (AsyncWebServerRequest *request)
	{
		Serial.println("/api/tip/printBarcode_UPCA");
		webserver::parseAndApplyPrintSettings(request);
		if(!(request->hasParam("data")))
		{
			Serial.println("Missing param 'data' -> 400");
			request->send(400, "text", "Missing param 'data'");
			return;
		}
		String data = request->getParam("data")->value();
		
		thermal_printer::printBarcode_UPCA(data.c_str());
		Serial.println(data);
		request->send(200);
	});

	server.on("/api/tip/printBarcode_EAN13", HTTP_POST, [] (AsyncWebServerRequest *request)
	{
		Serial.println("/api/tip/printBarcode_EAN13");
		webserver::parseAndApplyPrintSettings(request);
		if(!(request->hasParam("data")))
		{
			Serial.println("Missing param 'data' -> 400");
			request->send(400, "text", "Missing param 'data'");
			return;
		}
		String data = request->getParam("data")->value();
		
		thermal_printer::printBarcode_EAN13(data.c_str());
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
			request->send(400, "text", "Invalid value > 99");
			return;
		}

		if(!areAllCharsDigits(data.c_str()))
		{
			Serial.println("Invalid value not digit -> 400");
			request->send(400, "text", "Invalid value not digit");
			return;
		}
		
		
		uint8_t lines = strtoul(data.c_str(), NULL, 10);

		thermal_printer::feedLines(lines);
		Serial.println(lines);
		request->send(200);
	});
	
	server.on("/api/tip/spitOut", HTTP_POST, [] (AsyncWebServerRequest *request)
	{
		Serial.println("/api/tip/spitOut");
		
		thermal_printer::spitOut();
		request->send(200);
	});
}

void webserver::handleBitmapData(AsyncWebServerRequest *request, uint8_t *data, size_t len)
{
	Serial.println("Handle bitmap data");
	for (size_t i = 0; i < len; i++)
	{
		bitmapData[i] = data[i];
	}
	Serial.print(len);
	Serial.println(" bytes");
	
	request->send(200);
}

bool webserver::areAllCharsDigits(const char* str)
{
	for (uint8_t i = 0; i < strlen(str); i++)
	{
		if(!isDigit(str[i]))
		{
			return false;
		}
	}
	return true;
}

void webserver::configWebpages()
{
	server.on("/api/tip/doc.html", HTTP_GET,  [] (AsyncWebServerRequest *request)
	{
		Serial.println("/api/tip/doc.html");
		
		request->send(200, "text/html", webpages::API_TIP_DOC_HTML);
	});
}

void webserver::parseAndApplyPrintSettings(AsyncWebServerRequest *request)
{
	PRINT_SETTINGS printSettings;
	String data;
	
	// ALIGN MODE
	if(request->hasParam("align"))
		data = request->getParam("align")->value();
	else
		data = "";

	data.toLowerCase();
	if(data == "left") printSettings.align_mode = thermal_printer::ALIGN_MODE::LEFT;
	else if(data == "center") printSettings.align_mode = thermal_printer::ALIGN_MODE::CENTER;
	else if(data == "right") printSettings.align_mode = thermal_printer::ALIGN_MODE::RIGHT;
	else printSettings.align_mode = thermal_printer::ALIGN_MODE::LEFT;

	// UNDERLINE MODE
	if(request->hasParam("underline"))
		data = request->getParam("underline")->value();
	else
		data = "";

	data.toLowerCase();
	if(data == "off") printSettings.underline_mode = thermal_printer::UNDERLINE_MODE::OFF;
	else if(data == "onedot") printSettings.underline_mode = thermal_printer::UNDERLINE_MODE::ONE_DOT_THICK;
	else if(data == "twodot") printSettings.underline_mode = thermal_printer::UNDERLINE_MODE::TWO_DOT_THICK;
	else printSettings.underline_mode = thermal_printer::UNDERLINE_MODE::OFF;

	// INVERSE MODE
	if(request->hasParam("inverse"))
		data = request->getParam("inverse")->value();
	else
		data = "";

	data.toLowerCase();
	if(data == "true") printSettings.inverse_mode = true;
	else if(data == "false") printSettings.inverse_mode = false;
	else printSettings.inverse_mode = false;

	// UPSIDE DOWN PRINTING MODE
	if(request->hasParam("upside_down"))
		data = request->getParam("upside_down")->value();
	else
		data = "";

	data.toLowerCase();
	if(data == "true") printSettings.upside_down_printing = true;
	else if(data == "false") printSettings.upside_down_printing = false;
	else printSettings.upside_down_printing = false;

	webserver::appyPrintSettings(&printSettings);
}

void webserver::appyPrintSettings(PRINT_SETTINGS *printSettings)
{
	Serial.println("Print settings:");
	Serial.print("align: ");
	Serial.println(printSettings->align_mode);
	Serial.print("underline: ");
	Serial.println(printSettings->underline_mode);
	Serial.print("inverse: ");
	Serial.println(printSettings->inverse_mode);
	Serial.print("upside_down: ");
	Serial.println(printSettings->upside_down_printing);
	
	thermal_printer::align(printSettings->align_mode);
	delay(PRINT_SETTINGS_DELAY);
	thermal_printer::underlineMode(printSettings->underline_mode);
	delay(PRINT_SETTINGS_DELAY);
	thermal_printer::inverseMode(printSettings->inverse_mode);
	delay(PRINT_SETTINGS_DELAY);
	thermal_printer::setGlobalUpsideDown(printSettings->upside_down_printing);
	delay(PRINT_SETTINGS_DELAY);
}