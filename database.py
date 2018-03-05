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
            '''CREATE TABLE IF NOT EXISTS einheiten (einheit INTEGER UNIQUE, clipPaths, sumPaths)''')
        db.execute(
            '''CREATE TABLE IF NOT EXISTS clips (einheit, path)''')
        db.execute(
            '''CREATE TABLE IF NOT EXISTS sums (einheit, path)''')
        db.execute(
            '''CREATE TABLE IF NOT EXISTS recs (path)''')
        db.execute(
            '''CREATE TABLE IF NOT EXISTS dailies (date STRING UNIQUE, path)''')
        return db

    @staticmethod
    def writeEinheit(einheit, clipPaths, sumPaths):
        db = database.connect()
        if len(clipPaths) > 0:
            clips = ','.join(clip for clip in clipPaths)
        else:
            clips = None
        if len(sumPaths) > 0:
            sums = ','.join(sum for sum in sumPaths)
        else:
            sums = None
        db.execute(
            '''INSERT OR REPLACE INTO einheiten (einheit, clipPaths, sumPaths) VALUES (?, ?, ?)''',
            [str(einheit), clips, sums])
        db.commit()
        db.close()

    @staticmethod
    def writeClip(einheit, path):
        db = database.connect()
        db.execute(
            '''INSERT OR REPLACE INTO clips (einheit, path) VALUES (?, ?)''',
            [str(einheit), path])
        db.commit()
        db.close()

    @staticmethod
    def writeSum(einheit, path):
        db = database.connect()
        db.execute(
            '''INSERT OR REPLACE INTO sums (einheit, path) VALUES (?, ?)''',
            [str(einheit), path])
        db.commit()
        db.close()

    @staticmethod
    def writeRec(path):
        db = database.connect()
        db.execute('''INSERT OR REPLACE INTO recs (path) VALUES (?)''', [path])
        db.commit()
        db.close()

    @staticmethod
    def writeDaily(date, path):
        db = database.connect()
        db.execute(
            '''INSERT OR REPLACE INTO dailies (date, path) VALUES (?, ?)''',
            [date, path])
        db.commit()
        db.close()

    @staticmethod
    def readEinheit(einheit):
        db = database.connect()
        entry = db.execute(
            '''SELECT clipPaths, sumPaths FROM einheiten WHERE (einheit IS ?)''',
            [einheit])
        daten = entry.fetchone()
        db.close()
        if daten is None or daten[0] is None:
            clips = []
        else:
            clips = daten[0].split(',')
        if daten is None or daten[1] is None:
            sums = []
        else:
            sums = daten[1].split(',')
        return [clips, sums]

    @staticmethod
    def readClips(einheit):
        db = database.connect()
        entry = db.execute('''SELECT path FROM clips WHERE (einheit IS ?)''', [einheit])
        daten = entry.fetchall()
        db.close()
        if daten is None:
            return []
        else:
            return [path[0] for path in daten]

    @staticmethod
    def readSums(einheit):
        db = database.connect()
        entry = db.execute('''SELECT path FROM sums WHERE (einheit IS ?)''', [einheit])
        daten = entry.fetchall()
        db.close()
        if daten is None:
            return []
        else:
            return [path[0] for path in daten]

    @staticmethod
    def readRecs():
        db = database.connect()
        entry = db.execute('''SELECT * FROM recs''')
        daten = entry.fetchall()
        db.close()
        if daten is None:
            return []
        else:
            return [path[0] for path in daten]

    @staticmethod
    def readDaily(date):
        db = database.connect()
        entry = db.execute('''SELECT path FROM dailies WHERE (date IS ?)''', [date])
        daten = entry.fetchone()
        db.close()
        if daten is None:
            return None
        else:
            return daten[0]
