#!/usr/bin/env python3

from database import database
import sys

if len(sys.argv) != 3:
    print('invalid input')
    sys.exit()

if sys.argv[1] == 'e':
    [clips, sums] = database.readEinheit(sys.argv[2])
    if len(clips) > 0:
        clips = '[\'' + '\',\n\''.join(path for path in clips) + '\']'
    else:
        clips = '[]'
    if len(sums) > 0:
        sums = '[\'' + '\',\n\''.join(path for path in sums) + '\']'
    else:
        sums = '[]'
    print('[' + clips + ',\n' + sums + ']')
elif sys.argv[1] == 'c':
    clips = database.readClips(sys.argv[2])
    if len(clips) > 0:
        print('[\'' + '\',\n\''.join(path for path in clips) + '\']')
    else:
        print('[]')
else:
    print('invalid input')
    sys.exit()

