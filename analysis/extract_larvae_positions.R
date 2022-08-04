# set threshold for displacement area to be recognized as larave
# instead of random noise
areathresh = 8
fps = 30
framestominute = 1/fps/60
pixeltomm = 104 / 1146  # factor derived from well width
#pixeltomm = 78 / 858 factor derived from well height


# get paths of data files
files = dir("./larvae_positions", pattern = "*.txt")
files = paste("./larvae_positions",files,sep = "/")

# define function for data read in and preprocessing
read.trace <- function(fname, thresh){
  require(zoo) # for NA replacement function

 # read data and set sensible column names
  df = read.table(fname, sep = "", stringsAsFactors = FALSE)
  colnames(df) <- c("frame","bbox","x","y","area","color")
    
 # remove points where area is too small (very likely random noise)
  df[df$area <= thresh|is.na(df$area),c("x","y","area")] = NA

 # add well number
  df$well = as.numeric(gsub("\\D*([0-9]+)\\.txt", "\\1", fname))  
  
 # quit fcn now if every value is NA now
  if(all(is.na(df$x))) return(df)

 # replace NAs. First forward replacement of NA during measurement,
 # then backward replacment of the leading NAs (may result from
 # missing movement data but will also be present due to filtering
  df = zoo::na.locf(df, na.rm = FALSE, fromLast = TRUE)  # forward
  df = zoo::na.locf(df, na.rm = FALSE, fromLast = FALSE) # backward

  return(df)
}

# call data read function for all wells and concatenate data
# into a single dataframe
df = do.call(rbind, lapply(files, read.trace, areathresh))

# add time, convert pixel to mm
df$time = df$frame * framestominute
df$x = df$x * pixeltomm
df$y = df$y * pixeltomm

# add speed and distance to dataframe
df$speed = c(NA, sqrt(diff(df$x)^2 + diff(df$y)^2)) # distance per frame
df$speed[df$frame == 1] = NA
df$speed[is.na(df$speed)] = 0
df$speed_mm_per_s = df$speed * fps
df$distance = NA
for(wellno in unique(df$well)){
  df$distance[df$well == wellno] = cumsum(df$speed[df$well == wellno])
}


# create properly named factor for wells
df$wellf = factor( as.numeric(df$well)
                 , levels = sort(unique(as.numeric(df$well)))
                 , labels = as.vector(outer( LETTERS[seq( from = 1, to = 6 )]
                                           , seq(from =1, to = 8), paste, sep = "_")))

# add experimental condition
df$cond = "control"
df$cond[grepl("A|C|E", df$wellf)] = "COL6"

# plot movement data
require(lattice)
require(latticeExtra)
trellis.par.set(strip.background=list(col="white")) # ... the Tufte way

# construct layout for lattice plots such that it corresponds
# to the layout of zebrabox wells (only works for 6x8 layout)
cond = c(seq( 6, 48, 6)
        ,seq( 5, 47, 6)
        ,seq( 4, 46, 6)
        ,seq( 3, 45, 6)
        ,seq( 2, 44, 6)
        ,seq( 1, 43, 6))

# location plot
xyplot(-y~x|wellf, aspect = 1, pch  = ".", data = df
      , xlab = "x (mm)", ylab = "y (mm)"
      , layout = c(8, 6), index.cond = list(cond))
savePlot("../img/location_panels.png", type = "png")

# trace plot
xyplot(-y~x|wellf, aspect = 1, type = "l", data = df
      , xlab = "x (mm)", ylab = "y (mm)"
      , layout = c(8, 6), index.cond = list(cond))
savePlot("../img/trace_panels.png", type = "png")

# speed plot
xyplot(speed_mm_per_s ~ time|wellf, aspect = 1, pch = ".", data = df
      , layout = c(8, 6), index.cond = list(cond)
      , xlab = "time (min)", ylab = "speed (mm/s)")                    + 
      layer_(panel.xblocks(x, x <= 15, col = rgb(.9,.9,.9)))           +
      layer_(panel.xblocks(x, x >= 25 & x <= 35, col = rgb(.9,.9,.9))) +
      layer_(panel.xblocks(x, x >= 45 & x <= 55, col = rgb(.9,.9,.9))) +     
      layer_(panel.xblocks(x, x >= 65 & x <= 75, col = rgb(.9,.9,.9))) 
savePlot("../img/speed_panels.png", type = "png")

# distance plot
xyplot( distance~time|wellf, aspect = 1, type = "l", data = df
      , layout = c(8, 6), index.cond = list(cond)
      , xlab = "time (min)", ylab = "distance (mm)")                   + 
      layer_(panel.xblocks(x, x <= 15, col = rgb(.9,.9,.9)))           +
      layer_(panel.xblocks(x, x >= 25 & x <= 35, col = rgb(.9,.9,.9))) +
      layer_(panel.xblocks(x, x >= 45 & x <= 55, col = rgb(.9,.9,.9))) +     
      layer_(panel.xblocks(x, x >= 65 & x <= 75, col = rgb(.9,.9,.9)))
savePlot("../img/distance_panels.png", type = "png")

# condition comparison plot
  dfa = aggregate(speed~wellf*cond, data = df, sum)
  dfaa = do.call(data.frame, aggregate(speed~cond, data = dfa, function(x){c(m=mean(x),s=sd(x))}))
  dfaa$see = dfaa$speed.s/sqrt(48)*2

  with(dfa, plot(as.numeric(as.factor(cond))+runif(nrow(dfa))*.25-.125,speed,las=1
                ,xlim = c(0.5,2.5),xaxt = "n", pch = 19
                ,xlab = "condition", ylab = "distance (mm)"))
  axis(1, at = c(1, 2), labels = c("COL6", "control"))
  points(c(1,2), dfaa$speed.m, pch = 19, cex = 3, col = "red")
  arrows(c(1,2),dfaa$speed.m-dfaa$see,c(1,2),dfaa$speed.m+dfaa$see, code = 3, angle = 90
        ,col="red",lwd=2)
  t = t.test(speed~cond,dfa)
  text(1.5,4000,paste("p =",round(t$p.value,digits=3)))
savePlot("../img/distance_comparison.png", type = "png")
