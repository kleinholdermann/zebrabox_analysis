#!/bin/bash
# Purpose: Movement detection of zebrafish larvae in Zebrabox wells
# Usage: movement_detection.sh PATH/TO/video.mp4
#
# V 0.1.0 2022-07-20 Urs Kleinholdermann
#
# TODO: has issues with mirroring on well wall, especially in the marginal wells

# Path must point to a recent version of ffmpeg (4.x) for using temporal filtering
# default Ubuntu is 3.x. Thus adapt this according to your setup:
if [ $USER == "urs" ]; then
export PATH="/home/urs/sync/projects/dystrophy/zebrabox_analysis/res/ffmpeg:$PATH"
fi

## extract one image from vid for well detection
ffmpeg -ss 00:00:00.01 -i $1 -frames:v 1 still.png

## call python script for well detection
python3 detect_well_positions.py -i still.png --cols 8 --rows 6 -o wells.png

## prepare directories for intermediate videos and results
[ -d "./vids" ] && rm -rf ./vids
mkdir vids
[ -d "./larvae_positions" ] && rm -rf ./larvae_positions
mkdir larvae_positions

## loop over detected wells and extract a movie for each well
rad=$(cat radius.txt)
((dia = rad*2))

## define main well processing function in order to enable parallel processing
process_well () {    

 # give sensible names to variables
  dia=$2
  xc=$3
  yc=$4
  i=$5

  ffmpeg -i $1 -filter:v "crop=${dia}:${dia}:${xc}:${yc}" ./vids/well_${i}.mp4

 ## apply a temporal filter for background removal and binarize video
  # temporal filtering, i.e. background removal
  ./temporal_filter.sh ./vids/well_${i}.mp4 ./vids/filtered_${i}.mp4

  # invert video
  ffmpeg -i ./vids/filtered_${i}.mp4 -vf negate ./vids/inverted_${i}.mp4

  #deflicker
  ffmpeg -i ./vids/inverted_${i}.mp4 -vf deflicker -y ./vids/deflickered_${i}.mp4

  # binarize
  ffmpeg -i ./vids/deflickered_${i}.mp4 -f lavfi -i color=LightGrey:s=${dia}x${dia} -f lavfi -i color=black:s=${dia}x${dia} -f lavfi -i color=white:s=${dia}x${dia} -filter_complex threshold ./vids/binarized_${i}.mp4

  # extract each frame of video as a picture and get the larvae position
  # remove old frames if present
  [ -d "./frames_${i}" ] && rm -rf ./frames    
  mkdir frames_${i}

  # extract frames
  ffmpeg -i ./vids/binarized_${i}.mp4 ./frames_${i}/frame%1d.png -hide_banner

  # loop over frames and get position for each frame
  tmp=$(ffprobe -select_streams v -show_streams ./vids/well_${i}.mp4|grep nb_frames)
  nframes=${tmp#*=} # get number of frames
  for fr in $(seq 1 $nframes); do
    mogrify ./frames_${i}/frame${fr}.png -threshold 50% 
    tmp=$(convert ./frames_${i}/frame${fr}.png -define connected-components:verbose=true \
		  -connected-components 4 frame_${i}.png| egrep -v "gray\(0\)"|sed '1d'|head -n1)
    if [ -z "$tmp" ]
    then
      tmp="NA NA NA NA NA"
    else
      tmp=${tmp#*:}
      tmp=${tmp/,/" "}
    fi
    echo $fr $tmp >> ./larvae_positions/well_${i}.txt
  done # loop over frames
} # end of well processing function definition


for x in $(cat xcenter.txt); do
  for y in $(cat ycenter.txt); do

   ## extract video of one particular well only
    ((i=i+1))
    ((xc=x-rad))
    ((yc=y-rad))
    process_well $1 $dia $xc $yc $i &
  done # loop over well rows
done # loop over well columns
 


# cleanup
#rm still.png
#rm frame.png
#rm -rf ./vids
#rm -rf ./frames  
