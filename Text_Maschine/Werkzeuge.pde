import java.io.FilenameFilter;

class FileNameFilter implements FilenameFilter {
  FileNameFilter(String regExp) {
    this.regExp = regExp;
  }

  @Override
  public boolean accept(File dir, String name) {
    return match(name, this.regExp) != null;
  }

  private String regExp;
}
  
String[] listFilenames(String dir, String regExp) {
  File file = new File(dir);
  if (file.isDirectory()) {
    String names[] = file.list(new FileNameFilter(regExp));
    return sort(names);
  } else {
    return null;
  }
}

int stringToInt(String number) {
  return Integer.parseInt(number.replaceFirst("^0+(?!$)", ""));
}