#include "thermal_printer/thermal_printer.h"
#include "webserver/webserver.h"
#include "defines.h"

void setup() {
  Serial.begin(115200);
  pinMode(ERROR_LED_PIN, OUTPUT);
  thermal_printer::setup();
  webserver::begin();
}

void loop() {
  webserver::setupWiFi();
  vTaskDelay(1000 / portTICK_PERIOD_MS);
}