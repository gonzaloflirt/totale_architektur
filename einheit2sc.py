#!/usr/bin/env python3

from database import database
import sys

if len(sys.argv) != 2:
    print('invalid input')
    sys.exit()

[clips, sums] = database.readEinheit(sys.argv[1])
if len(clips) > 0:
    clips = '[\'' + '\',\n\''.join(path for path in clips) + '\']'
else:
    clips = '[]'
if len(sums) > 0:
    sums = '[\'' + '\',\n\''.join(path for path in sums) + '\']'
else:
    sums = '[]'
print('[' + clips + ',\n' + sums + ']')

