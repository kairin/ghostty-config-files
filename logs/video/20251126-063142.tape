# VHS Tape - Replay of start
Output "/home/kkk/Apps/ghostty-config-files/logs/video/20251126-063142.gif"
Set Shell "bash"
Set FontSize 14
Set Width 1900
Set Height 1300
Set Theme "Catppuccin Mocha"
Set PlaybackSpeed 0.5 
Set Padding 20

# Replay the recorded session
# We use scriptreplay to play back the timing and log files
# We speed it up by 2x during recording to save time
# Then we slow down playback by 0.5x (which is 1/2) to compensate? 
# No, Set PlaybackSpeed 1.0 means 1 second of video = 1 second of real time.
# If we record at 2x speed, 10s real time becomes 5s video.
# If we want the video to look normal speed, we need to slow it down?
# Actually, usually people WANT the demo to be faster than real time.
# So recording at 2x speed and playing at 1x speed results in a 2x speed video.
# This is good.

Hide
Type "scriptreplay --divisor 2 --timing='/home/kkk/Apps/ghostty-config-files/logs/video/20251126-063142.timing' '/home/kkk/Apps/ghostty-config-files/logs/video/20251126-063142.log'"
Enter
Show
Sleep 100ms

# Wait for replay to finish
Sleep 146s
