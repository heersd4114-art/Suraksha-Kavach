/*********************************************************
 Fireguard AI / Suraksha Kavach
 ESP32 Firmware v4.2 – LOGGING EDITION
 
 Features:
 - Real-time Dashboard Sync (liveData)
 - Historical Event Logging (logs collection)
 - EEPROM Calibration Saving
 - Watchdog Safety
**********************************************************/

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <ArduinoOTA.h>
#include <esp_task_wdt.h>
#include <EEPROM.h>
#include "addons/TokenHelper.h"

/* ================= CONFIGURATION ================= */

// WiFi
#define WIFI_SSID     "DALAL_4G"
#define WIFI_PASS     "shri7878"

// Firebase
#define API_KEY       "AIzaSyCycBjiRYqj6uzzgmba6MbP1zaAfswup9U"
#define PROJECT_ID    "fireguard-ai"
#define USER_EMAIL    "radha@gmail.com"
#define USER_PASS     "radha123"
#define DEVICE_ID     "VAYUSHURAKSHA_01"

// Pins
#define GAS_PIN       32
#define FLAME_PIN     4
#define BUZZER_PIN    25
#define LED_PIN       26
#define PUMP_PIN      27

// System Settings
#define WDT_TIMEOUT   25     // Seconds
#define EEPROM_SIZE   32
#define GAS_SAMPLES   40
#define FLAME_WINDOW  12

// Alarm Thresholds
#define GAS_WARN      30
#define GAS_CRIT      55

// Timing
#define CLOUD_INT     3000   // Live update interval
#define WIFI_RETRY    10000

/* ================= GLOBAL VARIABLES ================= */

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// Sensors
int gasBuf[GAS_SAMPLES];
int gasPos = 0;
long gasSum = 0;
int gasBase = 0;
int flameScore = 0;

// State Tracking
bool alarmActive = false;
bool lastAlarmState = false; 
unsigned long lastCloud = 0;
unsigned long lastWifi = 0;

/* ================= SETUP ================= */

void setup() {
  Serial.begin(115200);
  Serial.println("\n=== FIREGUARD v4.2 (LOGGING) BOOT ===");

  // Pin Modes
  pinMode(GAS_PIN, INPUT);
  pinMode(FLAME_PIN, INPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(LED_PIN, OUTPUT);
  pinMode(PUMP_PIN, OUTPUT);

  // Safe Start
  digitalWrite(BUZZER_PIN, LOW);
  digitalWrite(LED_PIN, HIGH);
  digitalWrite(PUMP_PIN, HIGH); // Relay OFF

  // Safety Watchdog
  esp_task_wdt_init(WDT_TIMEOUT, true);
  esp_task_wdt_add(NULL);

  // Calibration Memory
  EEPROM.begin(EEPROM_SIZE);

  // 1. Quick Sensor Fill
  for(int i=0; i<GAS_SAMPLES; i++) {
    gasBuf[i] = analogRead(GAS_PIN);
    gasSum += gasBuf[i];
  }

  // 2. Load or Calibrate
  if (!loadBaseline()) {
     Serial.println("Calibrating Sensor (First Run)...");
     blinkLED(10); 
     calibrateGas();
  }

  // 3. Connect Network
  connectWiFi();
  initFirebase();
  initOTA();

  // 4. Log Boot Event
  logToHistory("SYSTEM", "Device Restarted", 0);
}

/* ================= MAIN LOOP ================= */

void loop() {
  esp_task_wdt_reset();
  ArduinoOTA.handle();
  maintainWiFi();

  // 1. Read Sensors
  int gas = readGas();
  bool flame = readFlame();
  int gasPct = calcGas(gas);

  // 2. Check Danger
  bool warn = gasPct >= GAS_WARN;
  bool crit = gasPct >= GAS_CRIT;
  bool danger = crit || flame;

  // 3. Control Hardware
  controlActuators(danger, warn);

  // 4. Cloud Logic
  unsigned long now = millis();

  // A. EVENT LOGGING (Immediate on Change)
  if (danger != lastAlarmState) {
    if (danger) {
        String cause = flame ? "FIRE DETECTED" : "GAS LEAK";
        logToHistory("CRITICAL", cause, gasPct);
    } else {
        logToHistory("INFO", "Alarm Cleared - Safe", gasPct);
    }
    lastAlarmState = danger;
    
    // Force immediate live update too
    syncLiveData(gasPct, flame, danger);
    lastCloud = now;
  }
  
  // B. HEARTBEAT (Every few seconds)
  else if (now - lastCloud > CLOUD_INT) {
    syncLiveData(gasPct, flame, danger);
    lastCloud = now;
  }

  delay(40);
}

/* ================= LOGGING FUNCTION (NEW) ================= */

void logToHistory(String type, String msg, int gasVal) {
  if (WiFi.status() != WL_CONNECTED || !Firebase.ready()) return;

  FirebaseJson json;
  json.set("fields/device_id/stringValue", DEVICE_ID);
  json.set("fields/type/stringValue", type);       // "CRITICAL", "INFO", "SYSTEM"
  json.set("fields/message/stringValue", msg);     // Description
  json.set("fields/gas_level/integerValue", gasVal);
  json.set("fields/uptime_sec/integerValue", millis()/1000);
  
  // Create a Timestamp for creation time
  // Note: Firestore automatically adds a "createTime" metadata field, 
  // but we add a local server timestamp placeholder for easier sorting if needed.
  json.set("fields/timestamp/timestampValue", "SERVER_TIMESTAMP"); 

  Serial.print("[LOG] Writing to history... ");
  
  // We use createDocument (POST) to make a NEW entry every time
  // Collection: "logs"
  if (Firebase.Firestore.createDocument(&fbdo, PROJECT_ID, "" /* default db */, "logs", json.raw())) {
      Serial.println("OK");
  } else {
      Serial.printf("FAIL: %s\n", fbdo.errorReason().c_str());
  }
}

/* ================= LIVE DATA SYNC ================= */

void syncLiveData(int gas, bool flame, bool danger) {
  if (WiFi.status() != WL_CONNECTED || !Firebase.ready()) return;

  FirebaseJson json;
  String status = "SAFE";
  if (flame) status = "FIRE";
  else if (danger) status = "GAS_CRITICAL";
  else if (gas >= GAS_WARN) status = "WARNING";

  json.set("fields/gas/integerValue", gas);
  json.set("fields/flame/booleanValue", flame);
  json.set("fields/danger/booleanValue", danger);
  json.set("fields/status/stringValue", status);
  json.set("fields/uptime/integerValue", millis()/1000);

  // Path: liveData/DEVICE_ID
  String path = "liveData/" + String(DEVICE_ID);

  // We use patchDocument (PATCH) to update the SAME entry
  if (!Firebase.Firestore.patchDocument(&fbdo, PROJECT_ID, "", path.c_str(), json.raw(), "gas,flame,danger,status,uptime")) {
     Serial.print("."); // Fail silently to not clog serial
  }
}

/* ================= SENSORS & ACTUATORS ================= */

void calibrateGas() {
  Serial.println("Calibrating...");
  long calSum = 0;
  for (int i = 0; i < GAS_SAMPLES; i++) {
    calSum += analogRead(GAS_PIN);
    delay(50);
    esp_task_wdt_reset();
  }
  gasBase = calSum / GAS_SAMPLES;
  EEPROM.put(0, gasBase);
  EEPROM.commit();
  Serial.printf("Baseline Saved: %d\n", gasBase);
}

int readGas() {
  gasSum -= gasBuf[gasPos];
  gasBuf[gasPos] = analogRead(GAS_PIN);
  gasSum += gasBuf[gasPos];
  gasPos = (gasPos + 1) % GAS_SAMPLES;
  return gasSum / GAS_SAMPLES;
}

int calcGas(int v) {
  int d = v - gasBase;
  if (d < 0) d = 0;
  int pct = map(d, 0, 2000, 0, 100);
  if (pct > 100) pct = 100;
  return pct;
}

bool readFlame() {
  bool r = digitalRead(FLAME_PIN) == LOW;
  flameScore += r ? 1 : -1;
  flameScore = constrain(flameScore, 0, FLAME_WINDOW);
  return flameScore >= (FLAME_WINDOW * 0.75);
}

void controlActuators(bool danger, bool warn) {
  if (danger) {
    digitalWrite(BUZZER_PIN, HIGH);
    digitalWrite(PUMP_PIN, LOW); // ON
    digitalWrite(LED_PIN, LOW);
    alarmActive = true;
  }
  else if (warn) {
    digitalWrite(BUZZER_PIN, millis() % 800 < 150);
    digitalWrite(PUMP_PIN, HIGH); // OFF
    digitalWrite(LED_PIN, LOW);
    alarmActive = false;
  }
  else {
    digitalWrite(BUZZER_PIN, LOW);
    digitalWrite(PUMP_PIN, HIGH); // OFF
    digitalWrite(LED_PIN, HIGH);
    alarmActive = false;
  }
}

/* ================= HELPERS ================= */

void connectWiFi() {
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  Serial.print("WiFi");
  int tries = 0;
  while (WiFi.status() != WL_CONNECTED && tries < 20) {
    delay(400); Serial.print("."); tries++;
  }
  Serial.println(WiFi.status() == WL_CONNECTED ? " OK" : " FAIL");
}

void maintainWiFi() {
  if (WiFi.status() != WL_CONNECTED && millis() - lastWifi > WIFI_RETRY) {
    lastWifi = millis();
    WiFi.disconnect();
    WiFi.reconnect();
  }
}

void initFirebase() {
  config.api_key = API_KEY;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASS;
  config.token_status_callback = tokenStatusCallback;
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

bool loadBaseline() {
  int v;
  EEPROM.get(0, v);
  if (v > 100 && v < 4095) {
    gasBase = v;
    Serial.printf("Restored Baseline: %d\n", gasBase);
    return true;
  }
  return false;
}

void blinkLED(int times) {
  for(int i=0; i<times; i++) {
    digitalWrite(LED_PIN, !digitalRead(LED_PIN));
    delay(100);
    esp_task_wdt_reset();
  }
}

void initOTA() {
  ArduinoOTA.setHostname("Fireguard-ESP32");
  ArduinoOTA.begin();
}