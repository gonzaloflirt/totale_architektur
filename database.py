import configparser, os, sqlite3

class database:
    @staticmethod
    def connect():
        filePath = os.path.dirname(os.path.realpath(__file__))
        config = configparser.ConfigParser()
        config.read(os.path.join(filePath, 'totale_architektur.config'))
        path = os.path.join(filePath, config.get('database', 'path'))
        db = sqlite3.connect(path)
        db.execute(
            '''CREATE TABLE IF NOT EXISTS einheiten (einheit INTEGER UNIQUE, daten)''')
        return db

    @staticmethod
    def write(einheit, paths):
        db = database.connect()
        if len(paths) > 0:
            daten = ','.join(path for path in paths)
            db.execute("INSERT OR REPLACE INTO einheiten (einheit, daten) VALUES (?, ?)",
                [str(einheit), daten])
        else:
            db.execute("DELETE FROM einheiten WHERE einheit=?", [einheit])
        db.commit()
        db.close()

    @staticmethod
    def read(einheit):
        db = database.connect()
        entry = db.execute("SELECT daten FROM einheiten WHERE (einheit IS ?)", [einheit])
        daten = entry.fetchone()
        db.close()
        if daten is None:
            return []
        else:
            return daten[0].split(',')
