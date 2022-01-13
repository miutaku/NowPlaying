#!/bin/bash
webhookurl=""
nowplaying_info="/tmp/post_nowplaying.txt"
nowplaying_info_old="/tmp/post_nowplaying.txt.old"
info="/tmp/hogehuga"

# cp info file
cp $nowplaying_info $nowplaying_info_old

# get nowplaying
osascript -e 'tell application "Music"
        set i_name to name of current track
        set i_artist to artist of current track
        set i_album to album of current track
end tell
log "Song: " & i_name & "\n" & "Artist: " & i_artist & "\n" & "Album: " & i_album & "\n\n#NowPlaying by <@UserID>"' &> ${nowplaying_info}

# get nowplaying url
osascript -e 'tell application "Music"
                        set i_name to name of current track
                        set i_artist to artist of current track
                        set i_album to album of current track
                end tell
                log i_name & "\n" & i_artist & "\n" & i_album' >& ${info}

name=`sed -n 1P ${info}`
artist=`sed -n 2P ${info}`
album=`sed -n 3P ${info}`
encorded_name=`echo "$name" | /opt/homebrew/bin/nkf -WwMQ | tr = %`
encorded_album=`echo "$album" | /opt/homebrew/bin/nkf -WwMQ | tr = %`
string="$name+$artist+$album"
#string="$name+$artist"
search=`echo ${string} | sed -e "s/ /+/g"`
echo ${search} # debug

curl "https://itunes.apple.com/search?term=${search}&country=JP&lang=ja_jp&media=music" | /opt/homebrew/bin/jq '.results[]| .trackViewUrl' | head -n 1 | sed -e 's/"//g' | grep "https://music.apple.com/jp/album/${encorded_name}/" >> ${nowplaying_info}

# diff info and post to slack
diff $nowplaying_info $nowplaying_info_old

if [ $? == 0 ]; then
 exit
else
 curl -X POST --data-urlencode \
 "payload={\"text\": \"`cat ${nowplaying_info}`\", \"unfurl_links\": true }" \
 ${webhookurl}
fi
