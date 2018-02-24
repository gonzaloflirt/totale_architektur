StringDict getIntroduction(String path, String[] languages) throws Exception {
  String filename = listFilenames(path, "Introduction.txt")[0];
  if (filename.isEmpty()) { throw new Exception("No Introduction file!"); }
  
  println("Read Introduction file: " + filename);
  String[] lines = loadStrings(path + filename);
  if (lines.length != languages.length) { throw new Exception(filename + ": Language mismatch!"); }
 
  StringDict introduction = new StringDict();
  for (int i = 0; i < languages.length; ++i) {
    String[] text = match(lines[i], "(" + languages[i] + ")@(.*)");
    if (text == null) { throw new Exception(filename + ": No text for " + languages[i] + "!"); }
    if (text.length != 3 || text[2].isEmpty()) { throw new Exception(filename + ": Too few lines!"); }
    introduction.set(text[1], text[2]);
  }
  
  return introduction;
}