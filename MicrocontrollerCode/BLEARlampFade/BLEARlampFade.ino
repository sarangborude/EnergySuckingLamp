#include <Adafruit_NeoPixel.h>

/*********************************************************************
 This is an example for our nRF51822 based Bluefruit LE modules

 Pick one up today in the adafruit shop!

 Adafruit invests time and resources providing this open source code,
 please support Adafruit and open-source hardware by purchasing
 products from Adafruit!

 MIT license, check LICENSE for more information
 All text above, and the splash screen below must be included in
 any redistribution
*********************************************************************/

#include <Arduino.h>
#include <SPI.h>
#include <Adafruit_NeoPixel.h>
#include "Adafruit_BLE.h"
#include "Adafruit_BluefruitLE_SPI.h"
#include "Adafruit_BluefruitLE_UART.h"

#include "BluefruitConfig.h"

#if SOFTWARE_SERIAL_AVAILABLE
  #include <SoftwareSerial.h>
#endif

/*=========================================================================
    APPLICATION SETTINGS

    FACTORYRESET_ENABLE       Perform a factory reset when running this sketch
   
                              Enabling this will put your Bluefruit LE module
                              in a 'known good' state and clear any config
                              data set in previous sketches or projects, so
                              running this at least once is a good idea.
   
                              When deploying your project, however, you will
                              want to disable factory reset by setting this
                              value to 0.  If you are making changes to your
                              Bluefruit LE device via AT commands, and those
                              changes aren't persisting across resets, this
                              is the reason why.  Factory reset will erase
                              the non-volatile memory where config data is
                              stored, setting it back to factory default
                              values.
       
                              Some sketches that require you to bond to a
                              central device (HID mouse, keyboard, etc.)
                              won't work at all with this feature enabled
                              since the factory reset will clear all of the
                              bonding data stored on the chip, meaning the
                              central device won't be able to reconnect.
    MINIMUM_FIRMWARE_VERSION  Minimum firmware version to have some new features
    MODE_LED_BEHAVIOUR        LED activity, valid options are
                              "DISABLE" or "MODE" or "BLEUART" or
                              "HWUART"  or "SPI"  or "MANUAL"
    -----------------------------------------------------------------------*/
    #define FACTORYRESET_ENABLE         1
    #define MINIMUM_FIRMWARE_VERSION    "0.6.6"
    #define MODE_LED_BEHAVIOUR          "MODE"

    #define PIN                         5
    #define NUMPIXELS                   24
/*=========================================================================*/

Adafruit_NeoPixel pixel = Adafruit_NeoPixel(NUMPIXELS, PIN);

// Create the bluefruit object, either software serial...uncomment these lines
/*
SoftwareSerial bluefruitSS = SoftwareSerial(BLUEFRUIT_SWUART_TXD_PIN, BLUEFRUIT_SWUART_RXD_PIN);

Adafruit_BluefruitLE_UART ble(bluefruitSS, BLUEFRUIT_UART_MODE_PIN,
                      BLUEFRUIT_UART_CTS_PIN, BLUEFRUIT_UART_RTS_PIN);
*/

/* ...or hardware serial, which does not need the RTS/CTS pins. Uncomment this line */
// Adafruit_BluefruitLE_UART ble(Serial1, BLUEFRUIT_UART_MODE_PIN);

/* ...hardware SPI, using SCK/MOSI/MISO hardware SPI pins and then user selected CS/IRQ/RST */
Adafruit_BluefruitLE_SPI ble(BLUEFRUIT_SPI_CS, BLUEFRUIT_SPI_IRQ, BLUEFRUIT_SPI_RST);

/* ...software SPI, using SCK/MOSI/MISO user-defined SPI pins and then user selected CS/IRQ/RST */
//Adafruit_BluefruitLE_SPI ble(BLUEFRUIT_SPI_SCK, BLUEFRUIT_SPI_MISO,
//                             BLUEFRUIT_SPI_MOSI, BLUEFRUIT_SPI_CS,
//                             BLUEFRUIT_SPI_IRQ, BLUEFRUIT_SPI_RST);


// A small helper
void error(const __FlashStringHelper*err) {
  Serial.println(err);
  while (1);
}

/**************************************************************************/
/*!
    @brief  Sets up the HW an the BLE module (this function is called
            automatically on startup)
*/
/**************************************************************************/



bool isZeroSent = false;
int currentR = 0;
int currentG = 0;
int currentB = 0;

// Set the number of steps and delay between them
  int steps = 100;        // Number of interpolation steps
  int delayTime = 20;     // Delay in milliseconds between steps 

void setup(void)
{

  pixel.begin();
  for(uint8_t i=0; i<NUMPIXELS; i++) {
    pixel.setPixelColor(i, pixel.Color(0,0,0)); // off
  }
  pixel.show();
  
  //while (!Serial);  // required for Flora & Micro
  //delay(500);

  Serial.begin(115200);
  Serial.println(F("Adafruit Bluefruit Command Mode Example"));
  Serial.println(F("---------------------------------------"));

  /* Initialise the module */
  Serial.print(F("Initialising the Bluefruit LE module: "));

  if ( !ble.begin(VERBOSE_MODE) )
  {
    error(F("Couldn't find Bluefruit, make sure it's in CoMmanD mode & check wiring?"));
  }
  Serial.println( F("OK!") );

  if ( FACTORYRESET_ENABLE )
  {
    /* Perform a factory reset to make sure everything is in a known state */
    Serial.println(F("Performing a factory reset: "));
    if ( ! ble.factoryReset() ){
      error(F("Couldn't factory reset"));
    }
  }

  /* Disable command echo from Bluefruit */
  ble.echo(false);

  Serial.println("Requesting Bluefruit info:");
  /* Print Bluefruit information */
  ble.info();

  Serial.println(F("Please use Adafruit Bluefruit LE app to connect in UART mode"));
  Serial.println(F("Then Enter characters to send to Bluefruit"));
  Serial.println();

  ble.verbose(false);  // debug info is a little annoying after this point!

  /* Wait for connection */
  while (! ble.isConnected()) {
      delay(500);
  }

  // LED Activity command is only supported from 0.6.6
  if ( ble.isVersionAtLeast(MINIMUM_FIRMWARE_VERSION) )
  {
    // Change Mode LED Activity
    Serial.println(F("******************************"));
    Serial.println(F("Change LED activity to " MODE_LED_BEHAVIOUR));
    ble.sendCommandCheckOK("AT+HWModeLED=" MODE_LED_BEHAVIOUR);
    Serial.println(F("******************************"));
  }
}

/**************************************************************************/
/*!
    @brief  Constantly poll for new command or response data
*/
/**************************************************************************/
void loop(void)
{

  
  // Check for user input
  char inputs[BUFSIZE+1];

  ble.println("AT+BLEUARTRX");
  ble.readline();
  if (strcmp(ble.buffer, "OK") == 0) {
    // no data
    return;
  }
  // Some data was found, its in the buffer
  Serial.println(ble.buffer);

  int r, g, b;

  int result = sscanf(ble.buffer, "%d,%d,%d", &r, &g, &b);

  Serial.println(r);
  Serial.println(g);
  Serial.println(b);

  interpolateColor(currentR, currentG, currentB, r, g, b, steps, delayTime);
  currentR = r;
  currentG = g;
  currentB = b;
  
  ble.waitForOK();

}
void DoBreakup(char s[], char delimit[], char *ptr[])
{
  char *p;
  int i = 0;
  
  p  = strtok(s, delimit);
  while (p) {
    ptr[i++] = p;
    p = strtok(NULL, delimit);
  }
}

int gammaCorrect(int value) {
    float gamma = 2.8;
    // Ensure the input value is within the valid range
    value = constrain(value, 0, 255);
    return (int)(pow((float)value / 255.0, gamma) * 255.0 + 0.5);
}

void interpolateColor(int rStart, int gStart, int bStart,
                      int rEnd, int gEnd, int bEnd,
                      int steps, int delayTime) {
    // Calculate the incremental changes for each color component
    float deltaR = (float)(rEnd - rStart) / steps;
    float deltaG = (float)(gEnd - gStart) / steps;
    float deltaB = (float)(bEnd - bStart) / steps;

    float r = rStart;
    float g = gStart;
    float b = bStart;

    for (int i = 0; i <= steps; i++) {
        // Update the color components
        r += deltaR;
        g += deltaG;
        b += deltaB;

        // Clamp the values and convert to integers
        int rInt = constrain((int)r, 0, 255);
        int gInt = constrain((int)g, 0, 255);
        int bInt = constrain((int)b, 0, 255);

        // Apply gamma correction
        int rGamma = gammaCorrect(rInt);
        int gGamma = gammaCorrect(gInt);
        int bGamma = gammaCorrect(bInt);

        // Set the gamma-corrected color to the strip
        uint32_t color = pixel.Color(rGamma, gGamma, bGamma);
        for (int j = 0; j < pixel.numPixels(); j++) {
            pixel.setPixelColor(j, color);
        }
        pixel.show();

        delay(delayTime);
    }

    // Ensure the final color is set precisely
    // Apply gamma correction to the final color components
    int rGammaEnd = gammaCorrect(rEnd);
    int gGammaEnd = gammaCorrect(gEnd);
    int bGammaEnd = gammaCorrect(bEnd);

    uint32_t endColor = pixel.Color(rGammaEnd, gGammaEnd, bGammaEnd);
    for (int j = 0; j < pixel.numPixels(); j++) {
        pixel.setPixelColor(j, endColor);
    }
    pixel.show();
}
