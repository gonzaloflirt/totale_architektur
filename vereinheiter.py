#!/usr/bin/env python3

import ast, argparse, configparser, datetime, io, os, time
from pydub import AudioSegment, effects, silence
from pythonosc import udp_client
from random import randint
from database import *

def date():
    return datetime.datetime.now().strftime("%Y-%m-%d")

def panClips(clips):
    numClips = len(clips)
    if numClips == 0:
        return []
    elif numClips == 1:
        return [clips[0].pan(0)]
    else:
        diff = 2 / (numClips - 1)
        pos = [-1 + (i * diff) for i in range(0, numClips)]
        result = []
        for i in range(0, numClips):
            clips[i] = clips[i].pan(pos[i])
        return clips

def daily():
    sumAttenuation = config.getint('vereinheiter', 'dailiesSumAttenuation')
    print(sumAttenuation)
    daily = AudioSegment.silent(100)
    for einheit in range(1, 16):
        [clips, sums] = database.readEinheit(einheit)
        if len(clips) > 0:
            audio = [AudioSegment.from_wav(clip) for clip in clips]
            audio = panClips(audio)
            sumsAudio = [AudioSegment.from_wav(sum) for sum in sums]
            sumsAudio = panClips(sumsAudio)
            [audio.append(sum - sumAttenuation) for sum in sumsAudio]
            duration = max([len(clip) for clip in audio])
            result = AudioSegment.silent(duration = duration)
            for clip in audio:
                result = result.overlay(clip - 30, position = randint(0, duration - len(clip)))
            result = effects.normalize(result, 0.5)
            result = result.remove_dc_offset()
            daily = daily.append(result)
    name = os.path.join(dailiesDir, date())
    daily.export(name + '.wav', format = 'wav')
    daily.export(name + '.mp3', format = 'mp3', bitrate="128k")
    print('new daily:', name + '.mp3')
    database.writeDaily(date(), (name + '.wav'))

def dailyJob():
    cur = database.readDaily(date())
    if cur is None:
        database.backup(date() + '.db')
        daily()

def newRecordings():
    files = [file for file in os.listdir(recordingsDir)
        if (os.path.isfile(os.path.join(recordingsDir, file)))]
    recordings = [file for file in files if (file.endswith('.wav'))]
    newRecs = sorted([file for file in recordings if file not in database.readRecs()])
    [database.writeRec(rec) for rec in newRecs]
    return newRecs

def createClipFromRecording(fileName):
    fade = config.getfloat('vereinheiter', 'fadeDur') * 1000
    silenceLen = int(config.getfloat('vereinheiter', 'silenceLen') * 1000)
    silenceTresh = config.getfloat('vereinheiter', 'silenceTresh')
    treshold = config.getfloat('vereinheiter', 'compressorTreshold')
    ratio = config.getfloat('vereinheiter', 'compressorRatio')
    attack = config.getfloat('vereinheiter', 'compressorAttack')
    release = config.getfloat('vereinheiter', 'compressorRelease')
    frames = AudioSegment.from_wav(os.path.join(recordingsDir, fileName))
    frames = frames.set_sample_width(4)
    frames = frames.fade_in(fade)
    frames = frames.fade_out(fade)
    frames = effects.normalize(frames)
    frames = frames.remove_dc_offset()
    nonsilent = silence.detect_nonsilent(frames, silenceLen, silenceTresh)
    chunks = [frames[chunk[0]:chunk[1]] for chunk in nonsilent]
    frames = AudioSegment.silent(100)
    for chunk in chunks:
        if len(chunk) > 100:
            chunk = chunk.fade_in(100)
            chunk = chunk.fade_out(100)
            frames = frames.append(AudioSegment.silent(250))
            frames = frames.append(chunk)
    frames = effects.compress_dynamic_range(
        frames, threshold = treshold, ratio = ratio, attack = attack, release = release)
    frames = effects.normalize(frames)
    if (len(frames) > config.getfloat('vereinheiter', 'minClipLen') * 1000):
        clipName = os.path.join(clipsDir, fileName)
        frames.export(clipName, format = 'wav')
        einheit = os.path.basename(fileName).split('_')[0]
        database.writeClip(einheit, clipName)
        print('new clip:', clipName)
        return [einheit, clipName]
    else:
        print('recording too short:', fileName)
        return [None, None]

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
        result = result.remove_dc_offset()
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
        if clip is not None:
            [clips, sums] = database.readEinheit(einheit)
            if len(clips) >= config.getint('vereinheiter', 'numSpeakers'):
                sums = addClipsToSums(einheit, clips, sums)
                clips = [clip]
            else:
                clips.append(clip)
            database.writeEinheit(einheit, clips, sums)

def setSCVolume():
    dayStart = config.getint('vereinheiter', 'dayStart')
    dayEnd = config.getint('vereinheiter', 'dayEnd')
    currentHour = int(datetime.datetime.now().strftime("%H"))
    if currentHour > dayStart and currentHour < dayEnd:
        volume = config.getint('vereinheiter', 'dayVolume')
    else:
        volume = config.getint('vereinheiter', 'nightVolume')
    oscClient.send_message('/volume', volume)

config = configparser.ConfigParser()
config.read('totale_architektur.config')
recordingsDir = os.path.realpath(config.get('vereinheiter', 'recsDir'))
if not os.path.exists(recordingsDir):
    os.makedirs(recordingsDir)
clipsDir = os.path.realpath(config.get('vereinheiter', 'clipsDir'))
if not os.path.exists(clipsDir):
    os.makedirs(clipsDir)
sumsDir = os.path.realpath(config.get('vereinheiter', 'sumsDir'))
if not os.path.exists(sumsDir):
    os.makedirs(sumsDir)
dailiesDir = os.path.realpath(config.get('vereinheiter', 'dailiesDir'))
if not os.path.exists(dailiesDir):
    os.makedirs(dailiesDir)
oscClient = udp_client.SimpleUDPClient(
    config.get('vereinheiter', 'scIP'),
    config.getint('vereinheiter', 'scPort'))

try:
    while True:
        dailyJob()
        updateDatabase()
        setSCVolume()
        time.sleep(1)
except KeyboardInterrupt:
    pass

