#!/usr/bin/env python3

from database import database
import sys

if len(sys.argv) != 2:
    print('invalid input')
    sys.exit()

print(database.readEinheit(sys.argv[1]))
