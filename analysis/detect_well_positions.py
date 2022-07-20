# well detection code mainly taken from here:
# https://pyimagesearch.com/2014/07/21/detecting-circles-images-using-opencv-hough-circles

# import the necessary packages
import numpy as np
import argparse
import cv2
import kmeans1d

# construct the argument parser and parse the arguments
ap = argparse.ArgumentParser()
ap.add_argument("-i", "--image" , required = True, help = "Path to the image")
ap.add_argument("-c", "--cols"  , required = True, help = "number of well columns")
ap.add_argument("-r", "--rows"  , required = True, help = "number of well rows")
ap.add_argument("-o", "--output", required = True, help = "output image name")
args = vars(ap.parse_args())

nrows = int(args["rows"])
ncols = int(args["cols"])

# load the image, clone it for output, and then convert it to grayscale
image = cv2.imread(args["image"])
output = image.copy()
gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

# detect circles in the image

circles = cv2.HoughCircles(gray,cv2.HOUGH_GRADIENT,1.5,20,param1=10,param2=40,minRadius=27,maxRadius=35)

xpos = circles[0,:][:, 0]
ypos = circles[0,:][:, 1]
radius = np.round(np.mean(circles[0,:][:, 2])).astype("int")

xclusters, xcentroids = kmeans1d.cluster(xpos, ncols)
yclusters, ycentroids = kmeans1d.cluster(ypos, nrows)

xcentroids = np.round(xcentroids).astype("int")
ycentroids = np.round(ycentroids).astype("int")

if circles is not None:
    # loop over the (x, y) coordinates and radius of the circles
    #for (x, y, r) in circles:
    for xi in xcentroids:
        for yi in ycentroids:
            cv2.circle(output, (xi, yi), radius, (255, 0, 0), 4)

# show the output image
#cv2.imshow("output", np.hstack([image, output]))

# save the image for quality check
cv2.imwrite(args["output"], output)

# save xcenter, ycenter and radius
np.savetxt('xcenter.txt',xcentroids,'%d')
np.savetxt('ycenter.txt',ycentroids,'%d')
np.savetxt('radius.txt',[radius],'%d')


