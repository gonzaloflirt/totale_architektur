#!/usr/bin/env python3

import ast, argparse, configparser, io, os
from pydub import AudioSegment
from pydub import effects
from database import *

def allClips():
    files =  [file for file in os.listdir(clipsDir)
        if (os.path.isfile(os.path.join(clipsDir, file)))]
    return [file for file in files if (file.endswith('.wav'))]

def clipsForEinheit(i):
     return [einheit for einheit in allClips() if einheit.startswith(str(i) + '_')]

def newRecordings():
    files = [file for file in os.listdir(recordingsDir)
        if (os.path.isfile(os.path.join(recordingsDir, file)))]
    recordings = [file for file in files if (file.endswith('.wav'))]
    return sorted([file for file in recordings if file not in allClips()])

def createClipFromRecording(fileName):
    treshold = config.getfloat('vereinheiter', 'compressorTreshold')
    ratio = config.getfloat('vereinheiter', 'compressorRatio')
    attack = config.getfloat('vereinheiter', 'compressorAttack')
    release = config.getfloat('vereinheiter', 'compressorRelease')
    frames = AudioSegment.from_wav(os.path.join(recordingsDir, fileName))
    frames = effects.normalize(frames)
    frames = effects.compress_dynamic_range(
        frames, threshold = treshold, ratio = ratio, attack = attack, release = release)
    frames = effects.normalize(frames)
    frames.export(os.path.join(clipsDir, fileName), format = 'wav')
    print("new clip: ", fileName)

def createClipsFromNewRecordings():
    [createClipFromRecording(recording) for recording in newRecordings()]

def updateDatabase():
    for i in range(0, config.getint('vereinheiter', 'numEinheiten')):
        paths = [os.path.join(clipsDir, file) for file in clipsForEinheit(i)]
        database.write(i, paths)

config = configparser.ConfigParser()
config.read('totale_architektur.config')
recordingsDir = os.path.realpath(config.get('recorder', 'direcory'))
if not os.path.exists(recordingsDir):
    os.makedirs(recordingsDir)
clipsDir = os.path.realpath(config.get('vereinheiter', 'clipsDir'))
if not os.path.exists(clipsDir):
    os.makedirs(clipsDir)

createClipsFromNewRecordings()
updateDatabase()


