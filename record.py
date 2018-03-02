#!/usr/bin/env python3

import configparser, datetime, os, pyaudio, sys, threading, termios, wave
from pydub import AudioSegment
from pythonosc import dispatcher, osc_server

recording = False

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

def record(einheit):
    numChannels = config.getint('recorder', 'channels')
    sampleRate = config.getint('recorder', 'samplerate')
    frameSize = config.getint('recorder', 'framesize')
    deviceIndex = config.getint('recorder', 'deviceIndex')
    print('recording...')
    audio = pyaudio.PyAudio()
    stream = audio.open(
        format = pyaudio.paInt16,
        channels = numChannels,
        rate = sampleRate,
        input = True,
        frames_per_buffer = frameSize,
        input_device_index = deviceIndex)

    frames = AudioSegment.empty()
    global recording
    while recording:
        frames += AudioSegment(
            stream.read(frameSize), sample_width=2, frame_rate = sampleRate, channels=1)
    stream.stop_stream()
    stream.close()
    audio.terminate()
    print('finished recording')

    if (frames.duration_seconds > 0):
        filename = str(einheit) + '_' + datetime.datetime.now().isoformat()
        dataDir = config.get('recorder', 'direcory')
        if not os.path.exists(dataDir):
            os.makedirs(dataDir)
        frames.export(os.path.join(dataDir, filename) + '.wav', format = 'wav')
        print("wrote", filename, 'duration:', frames.duration_seconds, 'seconds')

def startRecording(key):
    global recording
    recording = True
    threading.Thread(target=record, args=(key)).start()

def stopRecording():
    global recording
    recording = False

def OSCrecordHandler(addr, args, key):
    startRecording(["{}".format(key)])

def OSCstopHandler(addr):
    stopRecording()

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

oscDispatcher = dispatcher.Dispatcher()
oscDispatcher.map("/record", OSCrecordHandler, 'key')
oscDispatcher.map("/stop", OSCstopHandler)
oscPort = config.getint('recorder', 'oscPort')
oscServer = osc_server.ThreadingOSCUDPServer(('127.0.0.1', oscPort), oscDispatcher)
print("OSC: {}".format(oscServer.server_address))
threading.Thread(target=oscServer.serve_forever).start()

while True:
    key = waitForKeypress()
    if key in '0123456789' and not recording:
        startRecording(key)
    else:
        stopRecording()
        if key == 'q':
            oscServer.shutdown()
            break
