class ExtensionFilter implements FilenameFilter {
  ExtensionFilter(String ext) {
    this.extension = ext.toLowerCase();
  }

  @Override
  public boolean accept(File dir, String name) {
    return name.toLowerCase().endsWith(extension);
  }

  private String extension;
}
  
String[] listFilenames(String dir, String extension) {
  File file = new File(dir);
  if (file.isDirectory()) {
    String names[] = file.list(new ExtensionFilter(extension));
    return sort(names);
  } else {
    return null;
  }
}

int stringToInt(String number) {
  return Integer.parseInt(number.replaceFirst("^0+(?!$)", ""));
}