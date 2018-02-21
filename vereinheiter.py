#!/usr/bin/env python3

import ast, argparse, configparser, datetime, io, os
from pydub import AudioSegment
from pydub import effects
from random import randint
from database import *

def weekday():
    return datetime.datetime.now().strftime("%A")

def date():
    return pastDate(0)

def pastDate(days):
    return (datetime.datetime.now() - datetime.timedelta(days)).strftime("%Y-%m-%d")

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
    clipName = os.path.join(clipsDir, fileName)
    frames.export(clipName, format = 'wav')
    print('new clip:', clipName)
    return clipName

def sumClips(einheit, clipNames):
    files = [AudioSegment.from_wav(os.path.join(clipsDir, clipName))
            for clipName in clipNames]
    duration = max([len(file) for file in files])
    result = AudioSegment.silent(duration = duration)
    for file in files:
        result = result.overlay(file - 9, position = randint(0, duration - len(file)))
    result = effects.normalize(result)
    sumName = os.path.join(sumsDir,
        str(einheit) + '_' + datetime.datetime.now().isoformat() + '.wav')
    result.export(sumName, format = 'wav')
    print('new sum:', sumName)
    return sumName

def updateDatabase():
    for recording in newRecordings():
        clip = createClipFromRecording(recording)
        clipEinheit = os.path.basename(clip).split('_')[0]
        einheit = database.read(clipEinheit)
        if len(einheit) >= config.getint('vereinheiter', 'numSpeakers'):
            sum = sumClips(clipEinheit, einheit)
            database.write(clipEinheit, [sum, clip])
        else:
            einheit.append(clip)
            database.write(clipEinheit, einheit)

config = configparser.ConfigParser()
config.read('totale_architektur.config')
recordingsDir = os.path.realpath(config.get('recorder', 'direcory'))
if not os.path.exists(recordingsDir):
    os.makedirs(recordingsDir)
clipsDir = os.path.realpath(config.get('vereinheiter', 'clipsDir'))
if not os.path.exists(clipsDir):
    os.makedirs(clipsDir)
sumsDir = os.path.realpath(config.get('vereinheiter', 'sumsDir'))
if not os.path.exists(sumsDir):
    os.makedirs(sumsDir)

updateDatabase()

#print(date())

