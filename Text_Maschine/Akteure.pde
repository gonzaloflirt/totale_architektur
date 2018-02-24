import java.io.FilenameFilter;
import java.util.*;


class Einheit extends StringDict {
};

class ApiEinheit {
  String get(String language) {
    return this.einheit.get(language);
  }
  Einheit einheit;
  int id;
}

class Einheiten extends HashMap<Integer, Einheit> {};

class Akteure extends HashMap<String, Einheiten> {
  Akteure(String path) throws Exception {
    int previousId = -1;
    Set<String> allLanguages = new HashSet();
    String[] filenames = listFilenames(path, "txt");
    for (int i = 0; i < filenames.length; ++i) {
      String[] parsed = match(filenames[i], "(.*?)_(.*?)_(.*?).txt");
      if (parsed != null && parsed.length == 4) {
        // Get name of Akteur
        String name = parsed[2];
        // Get Id of Einheit
        int id = stringToInt(parsed[1]);
        if ((previousId == -1 && id != 0) || ++previousId != id) {
          throw new Exception(filenames[i] + ": Einheiten Ids have to be consecutive numbers starting from 00. Eg. 00_Gropius_someInfo.txt");
        }
        
        // Get Einheit
        println("Read " + path + filenames[i]);
        String[] lines = loadStrings(path + filenames[i]);
        Einheit einheit = new Einheit();
        Set languages = new HashSet();
        for (int j = 0; j < lines.length; ++j) {
          String[] first = split(lines[j], "@");      
          einheit.set(first[0], first[1]);
          languages.add(first[0]);
        }
        if (!allLanguages.isEmpty() && allLanguages.hashCode() != languages.hashCode()) {
          throw new Exception(filenames[i] + ": All Einheiten have to provide versions of the same languages");
        }
        allLanguages = languages;
        
        // Add to Map
        if (this.containsKey(name)) {
          this.get(name).put(id, einheit);
        } else {
          Einheiten einheiten = new Einheiten();
          einheiten.put(id, einheit);
          this.put(name, einheiten);
        }
      }
    }
    
     mLanguages = new StringList();
     Iterator iter = allLanguages.iterator();
     while (iter.hasNext()) {
       mLanguages.append(iter.next().toString());
     }
  }
  
  StringList languages() {
    return mLanguages;
  }
  
  StringList names() {
     Set<String> keys = this.keySet();
     StringList names = new StringList();
     Iterator iter = keys.iterator();
     while (iter.hasNext()) {
       names.append(iter.next().toString());
     }
     return names;
  }
  
  ApiEinheit einheit(String name) {
    if (this.containsKey(name)) {
      Einheiten einheiten = this.get(name);
      Set<Integer> keys = einheiten.keySet();
      Integer[] array = keys.toArray(new Integer[keys.size()]);
      int index = (int)random(array.length);
      Integer id = array[index];
      if (einheiten.containsKey(id)) {
        ApiEinheit api = new ApiEinheit();
        api.id = id;
        api.einheit = einheiten.get(id);
        return api;
      } else {
        return null;
      }
    } else {
      return null;
    }
  }
  
  String akteurName(ApiEinheit apiEinheit) {
     Set<String> keys = this.keySet();
     String name = "";
     Iterator iter = keys.iterator();
     while (iter.hasNext()) {
       name = iter.next().toString();
       Einheiten einheiten = this.get(name);
       Set<Integer> einheitenKeys = einheiten.keySet();
       Iterator einheitenIter = einheitenKeys.iterator();
       while (einheitenIter.hasNext()) {
         Integer id = (Integer)einheitenIter.next();
         if (einheiten.containsKey(id)) {
           Einheit einheit = einheiten.get(id);
           if (einheit == apiEinheit.einheit) {
             return name;
           }
         }
       }
     }
    return "";
  }
  
  private StringList mLanguages;
};