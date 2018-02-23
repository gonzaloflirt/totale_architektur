class Introduction extends StringDict {
  Introduction(String path) throws Exception {
    String[] filenames = listFilenames(path, "txt");
    for (int i = 0; i < filenames.length; ++i) {
      String[] parsed = match(filenames[i], "Introduction.txt");
      if (parsed != null && parsed.length == 1) {
        println("Read " + path + filenames[i]);
        String[] lines = loadStrings(path + filenames[i]);
        mLanguages = new StringList();
        
        for (int j = 0; j < lines.length; ++j) {
          String[] first = split(lines[j], "@");      
          this.set(first[0], first[1]);
          mLanguages.append(first[0]);
        }
      }
    }
  }
  
  StringList languages() {
    return mLanguages;
  }
  
  private StringList mLanguages;
}