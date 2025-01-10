#include <WiFi.h>
#include <HTTPClient.h>
#include <DHT.h>

// Konfigurasi WiFi
const char* ssid = "";     
const char* password = ""; 

// URL endpoint backend yang ada di Vercel
const char* serverName = "https://nodejs-with-vercel.vercel.app/api";

// Konfigurasi pin dan tipe sensor DHT
#define DHTPIN 4         // Pin data DHT terhubung ke GPIO 4
#define DHTTYPE DHT11    // Tipe sensor DHT (DHT11 atau DHT22)

// Konfigurasi pin sensor MQ135
#define MQ135PIN 34      // Pin analog sensor MQ135 terhubung ke GPIO 34

DHT dht(DHTPIN, DHTTYPE);

void setup() {
  Serial.begin(115200);

  // Menghubungkan ke WiFi
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.print(".");
  }
  Serial.println("\nConnected to WiFi");

  // Inisialisasi sensor DHT
  dht.begin();
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;

    // Membaca data dari sensor
    float temperature = dht.readTemperature();
    float humidity = dht.readHumidity();
    int mq135Value = analogRead(MQ135PIN); // Membaca nilai dari sensor MQ135

    // Periksa apakah pembacaan sensor valid
    if (isnan(temperature) || isnan(humidity)) {
      Serial.println("Failed to read from DHT sensor!");
    } else {
      // Buat payload JSON
      String jsonPayload = "{\"sensor\":\"DHT11\",\"value\":" + String(mq135Value) + ",\"temperature\":" + String(temperature) + ",\"humidity\":" + String(humidity) + "}";

      // Kirim data ke endpoint backend
      http.begin(serverName);
      http.addHeader("Content-Type", "application/json");
      int httpResponseCode = http.POST(jsonPayload);

      if (httpResponseCode > 0) {
        String response = http.getString();
        Serial.println("Response code: " + String(httpResponseCode));
        Serial.println("Response: " + response);
      } else {
        Serial.println("Error sending POST request: " + String(httpResponseCode));
      }

      http.end();
    }
  } else {
    Serial.println("WiFi disconnected");
  }

  delay(5000); // Kirim data setiap 5 detik
}
