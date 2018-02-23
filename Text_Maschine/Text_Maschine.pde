// DEBUGGING: Use SPACE key to change Einheit

import netP5.*;
import oscP5.*;

OscP5 osc;
int inPort = 6666;
NetAddress receiver;
int sendToPort = 9000;
String sendToAddress = "127.0.0.1";
String oscStartRecordingPath = "/record";
String oscStopRecordingPath = "/stop";
String oscNamePath = "/bauhaus/name";
String oscGetNamesPath = "/bauhaus/names/get";
String oscNamesPath = "/bauhaus/names";

int hSpace = 10;
int vSpace = 10;
int textFeldWidth = 0;
int feldHeight = 0;
int langWidth = 120;

PFont fontLang;
PFont font;
int languageFontSize = 50;
int einheitenFontSize = 35;
int backgroundColor = 245;
int textColor0 = 100;
int textColor1 = 50;
Akteure akteure;
StringList names;
StringList languages;

ApiEinheit currentEinheit;

boolean isRecording = false;

void setup() {
  try {
    akteure = new Akteure(sketchPath() + "/Einheiten/");
  } catch(Exception e) {
    println("Error reading txt files: " + e.getMessage());
    exit();
  }
  languages = akteure.languages();
  names = akteure.names();
  
  background(backgroundColor);
  fullScreen();
  noStroke();
  noCursor();
  
  fontLang = createFont("Futura-Bold", 90);
  font = createFont("Futura", 90);
  
  textFeldWidth = width - langWidth - 3 * hSpace;
  feldHeight = (height / 2) - 2 * vSpace;
  
  osc = new OscP5(this, inPort);
  receiver = new NetAddress(sendToAddress, sendToPort);
}

void draw() {
  background(backgroundColor);
  if (isRecording) {
    drawLanguage();
    drawCurrentEinheit();
  }
  else {
    drawLandingPage();
  }
}

void drawLandingPage() {
  textFont(fontLang);
  textSize(languageFontSize);
  textAlign(CENTER, CENTER);
  Feld feld0 = new Feld(hSpace, vSpace, langWidth, feldHeight);
  fill(textColor0);
  text("Wähle einen Akteur.", feld0.x, feld0.y, width - 2 * hSpace, feld0.height);
  
  Feld feld1 = new Feld(hSpace, (height / 2), width - 2 * hSpace, feldHeight);
  fill(textColor1);
  text("Choose an Akteur.", feld1.x, feld1.y, feld1.width, feld1.height);
}

void drawLanguage() {
  textFont(fontLang);
  textSize(languageFontSize);
  textAlign(LEFT, TOP);
  Feld feld0 = new Feld(hSpace, vSpace, langWidth, feldHeight);
  fill(textColor0);
  text(languages.get(0), feld0.x, feld0.y, feld0.width, feld0.height);
  
  Feld feld1 = new Feld(hSpace, (height / 2) + vSpace, langWidth, feldHeight);
  fill(textColor1);
  text(languages.get(1), feld1.x, feld1.y, feld1.width, feld1.height);
}

void drawCurrentEinheit() {
  textFont(font);
  textSize(einheitenFontSize);
  textAlign(LEFT, TOP);
  Feld feld0 = new Feld(langWidth + 2 * hSpace, vSpace, textFeldWidth,  feldHeight);
  fill(textColor1);
  if (currentEinheit != null) {
    text(currentEinheit.get(languages.get(0)), feld0.x, feld0.y, feld0.width, feld0.height);
  }

  Feld feld1 = new Feld(langWidth + 2 * hSpace, (height / 2) + vSpace, textFeldWidth,  feldHeight);
  fill(textColor0);
  if (currentEinheit != null) {
    text(currentEinheit.get(languages.get(1)), feld1.x, feld1.y, feld1.width, feld1.height);
  }
}

void oscEvent(OscMessage inMessage) {
  String pattern = inMessage.addrPattern();
  if (pattern.equals(oscNamePath)) {
    String name = inMessage.get(0).stringValue();
    currentEinheit = akteure.einheit(name);
    println(inMessage.get(0).stringValue());
  }
  if (pattern.equals(oscGetNamesPath)) {
    OscMessage outMessage = new OscMessage(oscNamesPath);
    StringList names = akteure.names();
    Iterator iter = names.iterator();
    while (iter.hasNext()) {
      outMessage.add(iter.next().toString());
    }
    osc.send(outMessage, receiver);
  }
}

void keyPressed() {
  if (key == ' ' && !isRecording) {
    int index = 0;
    if (currentEinheit == null) {
      currentEinheit = akteure.einheit(names.get(0));
    }
    while(akteure.akteurName(currentEinheit) != names.get(index)) { ++index; }
    index = (index + 1) % names.size();
    String name = names.get(index);
    if (!name.isEmpty()) {
      ApiEinheit einheit = akteure.einheit(name);
      if (einheit != null) {
        currentEinheit = einheit;
        OscMessage message = new OscMessage(oscStartRecordingPath);
        message.add(currentEinheit.id);
        osc.send(message, receiver);
        isRecording = true;
      }
    }
  }
}

void keyReleased() {
  if (key == ' ') {
    isRecording = false;
    OscMessage message = new OscMessage(oscStopRecordingPath);
    osc.send(message, receiver);
  }
}