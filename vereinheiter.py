#!/usr/bin/env python3

import ast, argparse, configparser, datetime, io, os
from pydub import AudioSegment
from pydub import effects
from random import randint
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
    clipName = os.path.join(clipsDir, fileName)
    frames.export(clipName, format = 'wav')
    einheit = os.path.basename(fileName).split('_')[0]
    database.writeClip(einheit, clipName)
    print('new clip:', clipName)
    return [einheit, clipName]

def addClipsToSums(einheit, clips, sums):
    numSpeakers = config.getint('vereinheiter', 'numSpeakers')
    attenuation = config.getint('vereinheiter', 'sumAttenuation')
    clipsAudio = [AudioSegment.from_wav(clip) for clip in clips]
    sumsAudio = [AudioSegment.from_wav(sum) for sum in sums]
    while len(sumsAudio) < numSpeakers:
        sumsAudio.append(AudioSegment.silent(1))
    newSums = []
    for i in range(0, numSpeakers):
        sum = sumsAudio[i]
        clip = clipsAudio[i]
        duration = max(len(clip), len(sum))
        result = AudioSegment.silent(duration = duration)
        result = result.overlay(clip - 6, position = randint(0, duration - len(clip)))
        result = result.overlay(sum - 6 - attenuation, position = randint(0, duration - len(sum)))
        result = effects.normalize(result)
        sumName = os.path.join(sumsDir,
            str(einheit) + '_' + datetime.datetime.now().isoformat() + '.wav')
        result.export(sumName, format = 'wav')
        newSums.append(sumName)
    print('new sums for einheit', einheit)
    [print('  ', sum) for sum in newSums]
    return newSums

def updateDatabase():
    for recording in newRecordings():
        [einheit, clip] = createClipFromRecording(recording)
        [clips, sums] = database.readEinheit(einheit)
        if len(clips) >= config.getint('vereinheiter', 'numSpeakers'):
            sums = addClipsToSums(einheit, clips, sums)
            clips = [clip]
        else:
            clips.append(clip)
        database.writeEinheit(einheit, clips, sums)

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

