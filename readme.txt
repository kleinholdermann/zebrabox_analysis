The main program is 

> movement_detection.sh

which has to be called on a with the video in mp4 format as the only
argument:

> movement_detection.sh zebrabox_video.mp4

The script first creates a still image (still.png) from the video to
detect the wells. The wells are then detected with the Python script
detect_well_positions.py. This creates a control image (wells.png)
where you can see if the wells were detected correctly. Additionally
several files with the coordinates of the wells are created.
Afterwards the main analyses (splitting the video into smaller videos
for the wells, filtering, saving into single images and detection of
the larvae position) are done.

Requirements are python3 and the numpy, argparse, opencv (cv2) and
kmeans1d packages. Furthermore you need a fairly recent version of
ffmpeg (4.x) which has the tmix filter capability and also Image
Magick must be installed.

The larvae positions are then stored in a folder larvae_positions
(furthermore for each well there is a folder with the single images,
which you can actually delete and a folder vids with the single
videos, which you also don't need anymore. I kept those so far for
quality control). There is a text file for each well with the
positions and the size of the larvae (the latter is used to filter
out random fluctuations later on).

Then there is an R script

> extract_larvae_positions.R

that combines the data of all wells and contains the plot commands for
some plots (you have to select the plot you want by deleting
the comment '#' in front of it).


# Version info of this help file:
# 2022-08-03 - created (Urs Kleinholdermann)
