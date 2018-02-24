class Zitat {
  Zitat(String t, String q) {
    text = t;
    quelle = q;
  }
  
  String text;
  String quelle;
}

class Einheit extends HashMap<String, Zitat> {
};

Einheit[] getEinheiten(String path, String[] languages) throws Exception {
  String regExp = "(.*?)_(.*?)_(.*?).txt";
  String[] filenames = listFilenames(path, regExp);
  if (filenames == null) { throw new Exception("No Einheiten files!"); }

  int previousId = -1;
  Einheit[] einheiten = new Einheit[filenames.length];
  for (int i = 0; i < filenames.length; ++i) {
    String[] parsed = match(filenames[i], regExp);
    if (parsed == null) { throw new Exception(filenames[i] + ": Wrong format!"); }

    int id = stringToInt(parsed[1]);
    if ((previousId == -1 && id != 0) || ++previousId != id) {
      throw new Exception(filenames[i] + ": Einheiten Ids have to be consecutive numbers starting from 00. Eg. 00_Gropius_someInfo.txt");
    }
    
    println("Read Einheit file: " + filenames[i]);
    String[] lines = loadStrings(path + filenames[i]);
    if (lines.length != 2 * languages.length) { throw new Exception(filenames[i] + ": Language mismatch!"); }
    Einheit einheit = new Einheit();
    
    
    for (int j = 0; j < languages.length; ++j) {
      String[] text = match(lines[2 * j], languages[j] + "@(.*)");
      if (text == null || text.length != 2 || text[1].isEmpty()) { throw new Exception(filenames[i] + ": Too few lines!"); }
      
      String[] quelle = match(lines[(2 * j) + 1], languages[j] + "Quelle@(.*)");
      if (quelle == null || quelle.length != 2) { throw new Exception(filenames[i] + ": Too few lines!"); }
      Zitat zitat = new Zitat(text[1], quelle[1]);
      einheit.put(languages[j], zitat);
    }

    einheiten[i] = einheit;
  }
  return einheiten;
}