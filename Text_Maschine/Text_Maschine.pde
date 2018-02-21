// DEBUGGING: Use LEFT arrow key or OSC messages to change Einheit

import netP5.*;
import oscP5.*;

OscP5 osc;
int inPort = 6666;
NetAddress receiver;
int sendToPort = 7777;
String sendToAddress = "127.0.0.1";
String oscIdPath = "/bauhaus/einheit/id";
String oscNamePath = "/bauhaus/name";
String oscGetNamesPath = "/bauhaus/names/get";
String oscNamesPath = "/bauhaus/names";

int hSpace = 10;
int vSpace = 10;
int textFeldWidth = 0;
int feldHeight = 0;
int langWidth = 200;

PFont fontLang;
PFont font;
int languageFontSize = 90;
int einheitenFontSize = 50;
int backgroundColor = 245;
int textColor0 = 100;
int textColor1 = 50;
Akteure akteure;
StringList names;
StringList languages;

String previousName = "";
String currentName = "";

void setup() {
  try {
    akteure = new Akteure(sketchPath() + "/Einheiten/");
  } catch(Exception e) {
    println("Error reading txt files: " + e.getMessage());
    exit();
  }
  languages = akteure.languages();
  names = akteure.names();
  currentName = names.get(0);
  
  background(backgroundColor);
  fullScreen();
  noStroke();
  
  fontLang = createFont("Futura-Bold", 90);
  font = createFont("Futura", 90);
  
  textFeldWidth = width - langWidth - 3 * hSpace;
  feldHeight = (height / 2) - 2 * vSpace;
  
  osc = new OscP5(this, inPort);
  receiver = new NetAddress(sendToAddress, sendToPort);
}

void draw() {
  if (currentName != previousName) {
    background(backgroundColor);
    
    drawLanguage();

    ApiEinheit einheit = akteure.einheit(currentName);
    drawEinheiten(einheit);
    
    previousName = currentName;
    
    OscMessage message = new OscMessage(oscIdPath);
    message.add(einheit.id);
    osc.send(message, receiver);
  }
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

void drawEinheiten(ApiEinheit einheit) {
  textFont(font);
    textSize(einheitenFontSize);
    textAlign(LEFT, TOP);
    Feld feld0 = new Feld(langWidth + 2 * hSpace, vSpace, textFeldWidth,  feldHeight);
    fill(textColor1);
    if (einheit != null) {
      text(einheit.get(languages.get(0)), feld0.x, feld0.y, feld0.width, feld0.height);
    }

    Feld feld1 = new Feld(langWidth + 2 * hSpace, (height / 2) + vSpace, textFeldWidth,  feldHeight);
    fill(textColor0);
    if (einheit != null) {
      text(einheit.get(languages.get(1)), feld1.x, feld1.y, feld1.width, feld1.height);
    }
}

void oscEvent(OscMessage inMessage) {
  String pattern = inMessage.addrPattern();
  if (pattern.equals(oscNamePath)) {
    currentName = inMessage.get(0).stringValue();
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
  if (key == CODED && keyCode == RIGHT) {
    int index = 0;
    while(currentName != names.get(index)) { ++index; }
    index = (index + 1) % names.size();
    currentName = names.get(index);
  }
}