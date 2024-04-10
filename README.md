# Tracks

DJ tracks manager

# Prereqs

1. ruby 3.x
1. ffmpeg
1. Set up "DESCRIPTION" as a displayed field in MP3Tag

- This is due to ffmpeg not correctly writing comment tags

# Usage

ruby main.rb [CMD]

to debug, set GLI_DEBUG=true

# Data pipeline

```mermaid
flowchart LR
  internet["Internet<br>(FLACs, MP3s, AIFFs)"]
  digital["Digital folder<br>~/Music/Digital"]
  vinyl["Vinyl rips folder<br>~/Music/Vinyl"]
  tracks["Tracks folder<br>~/Music/Tracks"]
  vinyl_script[/ruby main.rb vinyl/]
  export_script[/ruby main.rb export/]
  pdj[Pioneer DJ]
  mik[/Mixed in Key/]
  tag[/MP3Tag/]
  beats[(Beats.csv catalog)]
  discogs[(Discogs.com API)]

  internet --> digital
  digital --> tag --> mik --> digital
  vinyl --> vinyl_script --> digital
  digital --> export_script --> tracks --> pdj
  beats --> export_script
  discogs --> export_script
```

# Workflow (human script)

1. download beats (Google Sheets) => beats.csv
1. record vinyl to `~/Music/Vinyl`
1. de-noise vinyl with AudioLava / RX10 Repair Assistant to `~/Music/Track Originals/<serial>/cleaned`
1. have a cup of tea
1. download tracks + albums (flac, aiff, mp3) into `~/Music/Digital`
1. run `ruby main.rb reset`
1. have a cup of tea
1. edit tags in MP3Tag
1. reimport `~/Music/Tracks` in Rekordbox
1. have a cup of tea
1. export music library to `~/Music/rekordbox.xml`
1. open Mixed in Key, analyze tracks
1. in Rekordbox, re-import rekordbox.xml into collection
1. have a cup of tea

# Vinyl recording notes

## Recording settings:

Peak ampitude: -5.04 dB
Total RMS: -22.02 dB
Dynamic range: 44.00 dB
Loudness: -19.02 LUFS

96kHz, 32-bit float aup

## Cleanup:

1. High Pass Filter, 24 db/octave roll-off, 20Hz cutoff
1. Split tracks
1. Convert to wav
1. Remove crackles/pops w/AudioLava
1. Amplify to -5.04dB
