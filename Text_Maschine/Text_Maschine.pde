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
Feld[] introductionFelder;
Feld[] languageFelder;
Feld[] einheitenFelder;

PFont fontLang;
PFont font;
int languageFontSize = 50;
int einheitenFontSize = 35;
int backgroundColor = 245;
int textColor0 = 100;
int textColor1 = 50;

Introduction introduction;
Akteure akteure;
StringList names;
StringList languages;

ApiEinheit currentEinheit;

boolean isRecording = false;
boolean hasStateChanged = true;

void setup() {
  String dataPath = sketchPath() + "/data/";
  try {
    introduction = new Introduction(dataPath);
    akteure = new Akteure(dataPath);
  } catch(Exception e) {
    println("Error reading txt files: " + e.getMessage());
    exit();
  }
  if (!areLanguagesCorrect(introduction.languages(), akteure.languages())) {
    println("Error! Einheiten and Introduction have not the same languages.");
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
  
  introductionFelder = new Feld[]{new Feld(hSpace, vSpace, width - 2 * hSpace,feldHeight), new Feld(hSpace, (height / 2), width - 2 * hSpace, feldHeight)};
  languageFelder = new Feld[]{new Feld(hSpace, vSpace, langWidth, feldHeight), new Feld(hSpace, (height / 2) + vSpace, langWidth, feldHeight)};
  einheitenFelder = new Feld[]{new Feld(langWidth + 2 * hSpace, vSpace, textFeldWidth,  feldHeight), new Feld(langWidth + 2 * hSpace, (height / 2) + vSpace, textFeldWidth,  feldHeight)};
  
  osc = new OscP5(this, inPort);
  receiver = new NetAddress(sendToAddress, sendToPort);
}

void draw() {
  if (hasStateChanged)
  {
    background(backgroundColor);
    if (isRecording) {
      drawLanguage();
      drawCurrentEinheit();
    }
    else if (!isRecording) {
      drawIntroduction();
    }
    hasStateChanged = false;
  }
}

void drawIntroduction() {
  textFont(fontLang);
  textSize(languageFontSize);
  textAlign(CENTER, CENTER);
  fill(textColor0);
  text(introduction.get(languages.get(0)), introductionFelder[0].x, introductionFelder[0].y, introductionFelder[0].width, introductionFelder[0].height);
  fill(textColor1);
  text(introduction.get(languages.get(1)), introductionFelder[1].x, introductionFelder[1].y, introductionFelder[1].width, introductionFelder[1].height);
}

void drawLanguage() {
  textFont(fontLang);
  textSize(languageFontSize);
  textAlign(LEFT, TOP);
  fill(textColor0);
  text(languages.get(0), languageFelder[0].x, languageFelder[0].y, languageFelder[0].width, languageFelder[0].height);
  fill(textColor1);
  text(languages.get(1), languageFelder[1].x, languageFelder[1].y, languageFelder[1].width, languageFelder[1].height);
}

void drawCurrentEinheit() {
  textFont(font);
  textSize(einheitenFontSize);
  textAlign(LEFT, TOP);
  fill(textColor1);
  if (currentEinheit != null) {
    text(currentEinheit.get(languages.get(0)), einheitenFelder[0].x, einheitenFelder[0].y, einheitenFelder[0].width, einheitenFelder[0].height);
  }
  fill(textColor0);
  if (currentEinheit != null) {
    text(currentEinheit.get(languages.get(1)), einheitenFelder[1].x, einheitenFelder[1].y, einheitenFelder[1].width, einheitenFelder[1].height);
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

boolean areLanguagesCorrect(StringList lhs, StringList rhs) {
  boolean areCorrect = false;
  if (lhs.size() == rhs.size() && lhs.size() == 2) {
    for (int i = 0; i < introduction.languages().size(); ++i) {
      if (lhs.get(i).equals(rhs.get(i))) {
        areCorrect = true;
      }
    }
  }
  return areCorrect;
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
        hasStateChanged = true;
      }
    }
  }
}

void keyReleased() {
  if (key == ' ') {
    isRecording = false;
    hasStateChanged = true;
    OscMessage message = new OscMessage(oscStopRecordingPath);
    osc.send(message, receiver);
  }
}