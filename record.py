#!/usr/bin/env python3

import configparser, datetime, os, pyaudio, sys, threading, termios, time, wave
from pythonosc import dispatcher, osc_server

recording = False

class Recorder:
    def __init__(self, einheit):
        self.einheit = einheit
        self.recording = True
        self.canceled = False
        threading.Thread(target=Recorder.record, args=[self]).start()

    def record(self):
        numChannels = config.getint('recorder', 'channels')
        sampleRate = config.getint('recorder', 'samplerate')
        frameSize = config.getint('recorder', 'framesize')
        deviceIndex = config.getint('recorder', 'deviceIndex')
        maxDuration = int(sampleRate / frameSize * config.getint('recorder', 'maxDuration'))
        filename = str(self.einheit) + '_' + datetime.datetime.now().isoformat()
        print('recording {} ...'.format(filename))
        audio = pyaudio.PyAudio()
        stream = audio.open(
            format = pyaudio.paInt16,
            channels = numChannels,
            rate = sampleRate,
            input = True,
            frames_per_buffer = frameSize,
            input_device_index = deviceIndex)

        frames = []
        while self.recording and not self.canceled:
            chunk = stream.read(frameSize)
            frames.append(chunk)
            if len(frames) > maxDuration:
                self.canceled = True

        stream.stop_stream()
        stream.close()
        audio.terminate()
        print('finished recording', filename)

        for i in range(0, config.getint('recorder', 'cancelPeriod')):
            if self.canceled:
                break
            time.sleep(1)

        frames = frames[2:]
        duration = frameSize * len(frames) / sampleRate
        if not self.canceled and duration > 0:
            waveFile = wave.open(os.path.join(dataDir, filename) + '.wav', 'wb')
            waveFile.setnchannels(numChannels)
            waveFile.setsampwidth(audio.get_sample_size(pyaudio.paInt16))
            waveFile.setframerate(sampleRate)
            waveFile.writeframes(b''.join(frames))
            waveFile.close()
            print('wrote', filename, 'duration:', duration, 'seconds')
            syncTarget = config.get('recorder', 'rsyncTarget')
            os.system('rsync -avrz {}/*.wav {}'.format(dataDir, syncTarget))
        else:
            print('canceled recording', filename)

def printDevices():
    audio = pyaudio.PyAudio()
    print('devices:')
    for i in range(0, audio.get_host_api_info_by_index(0).get('deviceCount')):
        device = audio.get_device_info_by_host_api_device_index(0, i)
        print('  ', i, device.get('name'),
                'ins:', device.get('maxInputChannels'),
                'outs:', device.get('maxOutputChannels'))
    deviceIndex = config.getint('recorder', 'deviceIndex')
    print('using:', audio.get_device_info_by_host_api_device_index(0, deviceIndex).get('name'))

def startRecording(einheit):
    global recorders
    global recordersLock
    recordersLock.acquire()
    keep = []
    for recorder in recorders:
        if not recorder.recording and not recorder.canceled:
            keep.append(recorder)
        else:
            recorder.canceled = True
    recorders = keep
    recorders.append(Recorder(einheit))
    recordersLock.release()

def stopRecording():
    global recorders
    global recordersLock
    recordersLock.acquire()
    for recorder in recorders:
        recorder.recording = False
    recordersLock.release()

def cancelRecording():
    global recorders
    global recordersLock
    recordersLock.acquire()
    for recorder in recorders:
        recorder.canceled = True
    recorders = []
    recordersLock.release()

def OSCrecordHandler(addr, args, einheit):
    startRecording('{}'.format(einheit))

def OSCstopHandler(addr):
    stopRecording()

def OSCcancelHandler(addr):
    cancelRecording()

def waitForKeypress():
    fd = sys.stdin.fileno()
    oldterm = termios.tcgetattr(fd)
    newattr = termios.tcgetattr(fd)
    newattr[3] = newattr[3] & ~termios.ICANON & ~termios.ECHO
    termios.tcsetattr(fd, termios.TCSANOW, newattr)
    try:
        result = sys.stdin.read(1)
    except IOError:
        pass
    finally:
        termios.tcsetattr(fd, termios.TCSAFLUSH, oldterm)
    return result

config = configparser.ConfigParser()
config.read('totale_architektur.config')
printDevices()

dataDir = config.get('recorder', 'direcory')
if not os.path.exists(dataDir):
    os.makedirs(dataDir)

oscDispatcher = dispatcher.Dispatcher()
oscDispatcher.map('/record', OSCrecordHandler, 'einheit')
oscDispatcher.map('/stop', OSCstopHandler)
oscDispatcher.map('/cancel', OSCcancelHandler)
oscPort = config.getint('recorder', 'oscPort')
oscServer = osc_server.ThreadingOSCUDPServer(('localhost', oscPort), oscDispatcher)
print('OSC: {}'.format(oscServer.server_address))
threading.Thread(target=oscServer.serve_forever).start()
recorders = []
recordersLock = threading.Lock()

try:
    while True:
        key = waitForKeypress()
        if key in '0123456789':
            startRecording(key)
        else:
            stopRecording()
except KeyboardInterrupt:
    cancelRecording()
    oscServer.shutdown()
    pass

