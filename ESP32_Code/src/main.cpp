#include "thermal_printer/thermal_printer.h"
#include "webserver/webserver.h"

void setup() {
  Serial.begin(115200);
  thermal_printer::setup();
  webserver::begin();
}

void loop() {
  
}