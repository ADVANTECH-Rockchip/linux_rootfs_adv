
-------------------------------------------------------
## Find support sound cards ##
cat /proc/asound/cards
-------------------------------------------------------
## hdmi0 ##
# audio play 
/tools/test/adv/audio/audio_play_test.sh hdmi0
-------------------------------------------------------
## rt5640 ##
# audio play 
/tools/test/adv/audio/audio_play_test.sh rt5640

# audio record
/tools/test/adv/audio/audio_record_test.sh rt5640
-------------------------------------------------------

