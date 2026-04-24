#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// ================= CONFIGURATION =================
const char* ssid = "RUDRA PATEL";
const char* pass = "rudi121513";

// !!! SERVER CONFIG !!!
// Ensure your PC has a static IP or check it daily.
// Run server with: python manage.py runserver 0.0.0.0:8000
const char* SERVER_IP = "172.20.85.60:8000"; // <-- Change this to your PC's IP Address
const char* userId    = "9twZ7Lr4ImVb6hBEUadSkRfO74u2"; 

#define GAS_PIN        32   // MQ Gas Sensor (Analog)
#define FLAME_PIN      4    // Flame Sensor (Digital)
#define BUZZER_PIN     25   // Buzzer
#define STATUS_LED_PIN 26   // Always ON, OFF during danger
#define PUMP_PIN       27   // Relay Module (Water Pump) - Active LOW

// --- VARIABLES ---
int cleanAirValue = 0;
bool isSystemReady = false;

// FILTERING (Fast & Smooth)
const int NUM_READINGS = 5; 
int readings[NUM_READINGS];
int readIndex = 0;
long totalGas = 0;
int averageGas = 0;

// THRESHOLDS
const int GAS_THRESHOLD_HIGH = 15;
const int GAS_THRESHOLD_LOW  = 5;

// STATE FLAGS
bool alarmActive = false;
bool gasNotified = false;
bool fireNotified = false;

// TIMERS
unsigned long lastAlertTime = 0;
const long alertCooldown = 15000; // Reduced to 15s for faster follow-up alerts
unsigned long lastWiFiCheck = 0;

// ACTUATION LATCH
unsigned long stopActuationTime = 0;
const long minActuationDuration = 5000; 

void setup() {
  Serial.begin(115200);

  // --- PIN MODES ---
  pinMode(GAS_PIN, INPUT);
  pinMode(FLAME_PIN, INPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(STATUS_LED_PIN, OUTPUT);
  pinMode(PUMP_PIN, OUTPUT); 

  // ================= STARTUP TEST (5 SECONDS) =================
  // "Make sure it sounds only till 5seconds while just starting"
  Serial.println(">>> STARTUP SYSTEM TEST <<<");
  digitalWrite(BUZZER_PIN, HIGH);
  digitalWrite(PUMP_PIN, LOW);       // 💧 PUMP ON (Active Low)
  digitalWrite(STATUS_LED_PIN, LOW); // LED OFF
  
  delay(5000); // 5 Seconds Test
  
  digitalWrite(BUZZER_PIN, LOW);      // Buzzer OFF
  digitalWrite(PUMP_PIN, HIGH);       // 🛑 PUMP OFF
  digitalWrite(STATUS_LED_PIN, HIGH); // LED ON
  Serial.println(">>> TEST COMPLETE <<<");
  // ============================================================

  // --- WIFI (High Performance) ---
  WiFi.mode(WIFI_STA);
  WiFi.setSleep(false); // NO SLEEP -> Max Responsiveness
  WiFi.setAutoReconnect(true);
  
  connectToWiFi();

  // --- CALIBRATION (Silent) ---
  Serial.println(">>> CALIBRATING SENSORS (Please Wait) <<<");
  long calTotal = 0;
  // Read 20 times (approx 1 sec) to stabilize MQ sensor
  for (int i = 0; i < 20; i++) {
    calTotal += analogRead(GAS_PIN);
    delay(50);
  }
  cleanAirValue = (calTotal / 20) + 40; 
  isSystemReady = true;

  // Fill buffer
  for (int i = 0; i < NUM_READINGS; i++) readings[i] = cleanAirValue;
  totalGas = cleanAirValue * NUM_READINGS;

  Serial.printf("System Armed. Baseline: %d\n", cleanAirValue);
}

void loop() {
  // --- NON-BLOCKING WIFI CHECK ---
  if (WiFi.status() != WL_CONNECTED) {
    if (millis() - lastWiFiCheck > 2000) { 
      Serial.println("Reconnecting WiFi...");
      WiFi.reconnect();
      lastWiFiCheck = millis();
    }
  }

  // --- SENSOR PROCESSING ---
  totalGas -= readings[readIndex];
  readings[readIndex] = analogRead(GAS_PIN);
  totalGas += readings[readIndex];
  readIndex = (readIndex + 1) % NUM_READINGS;
  averageGas = totalGas / NUM_READINGS;

  int gasDiff = max(0, averageGas - cleanAirValue);
  int gasPercent = map(gasDiff, 0, 1000, 0, 100);

  // --- FLAME SENSOR ---
  bool flameDetected = (digitalRead(FLAME_PIN) == LOW);
  if (flameDetected) {
     delay(5); // Ultra-fast debounce
     if (digitalRead(FLAME_PIN) != LOW) flameDetected = false;
  }

  // --- DANGER TRIGGER ---
  bool gasDanger = (gasPercent >= GAS_THRESHOLD_HIGH) || (alarmActive && gasPercent > GAS_THRESHOLD_LOW);
  
  // IGNORE SENSORS if not ready (extra safety)
  if (!isSystemReady) {
    gasDanger = false;
    flameDetected = false;
  }

  bool dangerState = gasDanger || flameDetected;

  if (dangerState) {
    // ⚡ INTERRUPT-LEVEL RESPONSE
    stopActuationTime = millis() + minActuationDuration;
    alarmActive = true;
    
    // Immediate Physical Response
    digitalWrite(BUZZER_PIN, HIGH);
    digitalWrite(PUMP_PIN, LOW);       
    digitalWrite(STATUS_LED_PIN, LOW); 

    // --- ALERT ---
    if ((!gasNotified && gasDanger) || (!fireNotified && flameDetected) || (millis() - lastAlertTime > alertCooldown)) {
      String type = flameDetected ? "fire" : "gas";
      // Send Alert (Fastest possible way)
      sendAlert(type, gasPercent);
      
      lastAlertTime = millis();
      if (gasDanger) gasNotified = true;
      if (flameDetected) fireNotified = true;
    }
    
    Serial.printf("!!! ALERT !!! Gas: %d%% Fire: %d\n", gasPercent, flameDetected);
  }

  // --- HEARTBEAT / LIVE DATA (Every 3 Seconds) ---
  static unsigned long lastHeartbeat = 0;
  if (millis() - lastHeartbeat > 3000) {
      bool sprinklerStatus = (digitalRead(PUMP_PIN) == LOW); // Active Low
      int fakeTemp = 25 + (gasPercent / 10); // Simulation for now
      
      sendLiveStatus(gasPercent, fakeTemp, sprinklerStatus, flameDetected);
      lastHeartbeat = millis();
  }

  // --- LATCH LOGIC ---
  if (millis() < stopActuationTime) {
     // KEEP ON
     digitalWrite(BUZZER_PIN, HIGH);
     digitalWrite(PUMP_PIN, LOW);      
     digitalWrite(STATUS_LED_PIN, LOW);
  } else {
     // OFF
     alarmActive = false;
     gasNotified = false;
     fireNotified = false;
     digitalWrite(BUZZER_PIN, LOW);
     digitalWrite(PUMP_PIN, HIGH);       
     digitalWrite(STATUS_LED_PIN, HIGH); 
  }

  delay(10); // Minimal loop delay for max CPU
}

void connectToWiFi() {
  Serial.print("Connecting WiFi");
  WiFi.begin(ssid, pass);
  int tries = 0;
  // Quick check (2.5 sec max)
  while (WiFi.status() != WL_CONNECTED && tries < 25) {
    delay(100);
    Serial.print(".");
    tries++;
  }
  Serial.println(WiFi.status() == WL_CONNECTED ? " OK" : " Background");
}

void sendAlert(String type, int gasLevel) {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.setConnectTimeout(1000); 
    http.setTimeout(1000);        

    String url = String("http://") + SERVER_IP + "/api/broadcast-alert/";
    http.begin(url);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("X-User-ID", userId);

    // Optimized JSON string construction
    String payload = "{\"type\":\"" + type + "\",\"severity\":\"high\",\"society\":\"FireGuard HQ\",\"block\":\"A\",\"details\":{\"gas_level\":" + String(gasLevel) + "}}";

    int code = http.POST(payload);
    
    if (code > 0) {
      Serial.print("Alert Sent: "); Serial.println(code);
    } else {
      Serial.print("Alert Err: "); Serial.println(http.errorToString(code));
    }
    http.end();
  }
}

void sendLiveStatus(int gas, int temp, bool sprinkler, bool flame) {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.setConnectTimeout(1000); 
    http.setTimeout(1000);        

    // New Endpoint for Live Data
    String liveUrl = String("http://") + SERVER_IP + "/api/live/update/";
    
    http.begin(liveUrl);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("X-User-ID", userId);

    /* 
       JSON Payload:
       {
         "gas_level": 10,
         "temperature": 28,
         "sprinkler_status": true,
         "flame_detected": false
       }
    */
    String payload = "{\"gas_level\":" + String(gas) + 
                     ",\"temperature\":" + String(temp) + 
                     ",\"sprinkler_status\":" + (sprinkler ? "true" : "false") + 
                     ",\"flame_detected\":" + (flame ? "true" : "false") + "}";

    int code = http.POST(payload);
    
    if (code > 0) {
      // Serial.printf("Live: %d\n", code); // Uncomment to debug heartbeat
    } 
    http.end();
  }
}
