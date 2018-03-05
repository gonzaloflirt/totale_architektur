# totale_architektur

Tools for a sound installation

### Dependencies
- Python3 with pyaudio, pydub, python-osc, and sqlitebck installed
- SuperCollider

### Modules
- `record.py` Python script to record audio clips
- `vereinheiter.py` Python script that processes the recordings
- `totale_architektur.scd` SuperCollider script to play and spatialize audio

### PI
Disable Screen Off:
Add
```
@xset s noblank
@xset s off
@xset -dpms
```

to `.config/lxsession/LXDE-pi/autostart`
