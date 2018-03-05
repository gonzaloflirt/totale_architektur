import netP5.*;
import oscP5.*;

boolean showLanguageIndicator = false;

OscP5 osc;
int inPort = 6666;
NetAddress receiver;
int sendToPort = 9000;
String sendToAddress = "127.0.0.1";
String oscStartRecordingPath = "/record";
String oscStopRecordingPath = "/stop";

int hSpace = 30;
int vSpace = 10;
int textFeldWidth = 0;
int feldHeight = 0;
int langWidth = 120;
Feld[] introductionFelder;
Feld[] languageFelder;
Feld[] einheitenFelder;

PFont[] fontLang;
PFont[] font;

int languageFontSize = 50;
int einheitenFontSize = 35;
int backgroundColor = 245;
int textColor0 = 100;
int textColor1 = 50;

StringDict introduction;
Einheit[] einheiten;
StringList names;
String[] languages;

Einheit currentEinheit;

boolean isRecording = false;
boolean hasStateChanged = true;

HashMap<Character, Integer> keyIdMapping;

void setup() {
  keyIdMapping = new HashMap<Character, Integer>();
  keyIdMapping.put('q', 0);
  keyIdMapping.put('w', 1);
  keyIdMapping.put('e', 2);
  keyIdMapping.put('r', 3);
  keyIdMapping.put('t', 4);
  
  keyIdMapping.put('a', 5);
  keyIdMapping.put('s', 6);
  keyIdMapping.put('d', 7);
  keyIdMapping.put('f', 8);
  keyIdMapping.put('g', 9);
  
  keyIdMapping.put('z', 10);
  keyIdMapping.put('x', 11);
  keyIdMapping.put('c', 12);
  keyIdMapping.put('v', 13);
  keyIdMapping.put('b', 14);
  
  String dataPath = sketchPath() + "/texte/";
  String fontDir = sketchPath() + "/gnu-freefont_freeserif/";
  languages = new String[]{"DE", "EN"};
  try {
    introduction = getIntroduction(dataPath, languages);
    einheiten = getEinheiten(dataPath, languages);
  } catch(Exception e) {
    println("Error reading Einheiten files: " + e.getMessage());
    exit();
  }
  
  background(backgroundColor);
  fullScreen();
  noStroke();
  noCursor();

  fontLang = new PFont[]{createFont(fontDir + "FreeSerifBold.ttf", 90), createFont(fontDir + "FreeSerifBoldItalic.ttf", 90)};
  font = new PFont[]{createFont(fontDir + "FreeSerif.ttf", 90), createFont(fontDir + "FreeSerifItalic.ttf", 90)};
  
  textFeldWidth = width - langWidth - 3 * hSpace;
  feldHeight = (height / 2) - 2 * vSpace;
  
  introductionFelder = new Feld[]{new Feld(hSpace, vSpace, width - 2 * hSpace, feldHeight), new Feld(hSpace, (height / 2), width - 2 * hSpace, feldHeight)};
  languageFelder = new Feld[]{new Feld(hSpace, vSpace, langWidth, feldHeight), new Feld(hSpace, (height / 2) + vSpace, langWidth, feldHeight)};
  if (showLanguageIndicator) {
    einheitenFelder = new Feld[]{new Feld(langWidth + 2 * hSpace, vSpace, textFeldWidth,  feldHeight), new Feld(langWidth + 2 * hSpace, (height / 2) + vSpace, textFeldWidth,  feldHeight)};
  } else {
    einheitenFelder = new Feld[]{new Feld(hSpace, vSpace, width - 2 * hSpace,  feldHeight), new Feld(hSpace, (height / 2) + vSpace, width - 2 * hSpace,  feldHeight)};
  }

  osc = new OscP5(this, inPort);
  receiver = new NetAddress(sendToAddress, sendToPort);
}

void draw() {
  if (hasStateChanged)
  {
    background(backgroundColor);
    if (isRecording) {
      drawCurrentEinheit();
      if (showLanguageIndicator) {
        drawLanguage();
      }
    }
    else if (!isRecording) {
      drawIntroduction();
    }
    hasStateChanged = false;
  }
}

void drawIntroduction() {
  textFont(font[0]);
  textSize(languageFontSize);
  textAlign(CENTER, CENTER);
  fill(textColor0);
  text(introduction.get(languages[0]), introductionFelder[0].x, introductionFelder[0].y, introductionFelder[0].width, introductionFelder[0].height);
  textFont(font[0]);
  textSize(languageFontSize);
  fill(textColor1);
  text(introduction.get(languages[1]), introductionFelder[1].x, introductionFelder[1].y, introductionFelder[1].width, introductionFelder[1].height);
}

void drawLanguage() {
  textFont(fontLang[0]);
  textSize(languageFontSize);
  textAlign(LEFT, TOP);
  fill(textColor0);
  text(languages[0], languageFelder[0].x, languageFelder[0].y, languageFelder[0].width, languageFelder[0].height);
  textFont(fontLang[0]);
  textSize(languageFontSize);
  fill(textColor1);
  text(languages[1], languageFelder[1].x, languageFelder[1].y, languageFelder[1].width, languageFelder[1].height);
}

void drawCurrentEinheit() {
  textFont(font[0]);
  textSize(einheitenFontSize);
  textAlign(LEFT, TOP);
  fill(textColor1);
  text(currentEinheit.get(languages[0]).text, einheitenFelder[0].x, einheitenFelder[0].y, einheitenFelder[0].width, einheitenFelder[0].height);

  textFont(font[0]);
  textSize(einheitenFontSize);
  fill(textColor0);
  text(currentEinheit.get(languages[1]).text, einheitenFelder[1].x, einheitenFelder[1].y, einheitenFelder[1].width, einheitenFelder[1].height);
}


void keyPressed() {
  if (!isRecording && keyIdMapping.containsKey(key)) {
    int id = keyIdMapping.get(key);
    currentEinheit = einheiten[id];
    OscMessage message = new OscMessage(oscStartRecordingPath);
    message.add(id);
    osc.send(message, receiver);
    isRecording = true;
    hasStateChanged = true;
  }
}

void keyReleased() {
  if (isRecording && keyIdMapping.containsKey(key) && getId(einheiten, currentEinheit) == keyIdMapping.get(key)) {
    isRecording = false;
    hasStateChanged = true;
    OscMessage message = new OscMessage(oscStopRecordingPath);
    osc.send(message, receiver);
  }
}