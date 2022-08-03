# set threshold for displacement area to be recognized as larave
# instead of random noise
areathresh = 8

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

# add speed and distance to dataframe
df$speed = c(NA, sqrt(diff(df$x)^2 + diff(df$y)^2))
df$speed[df$frame == 1] = NA
df$speed[is.na(df$speed)] = 0
df$distance = NA
for(wellno in unique(df$well)){
  df$distance[df$well == wellno] = cumsum(df$speed[df$well == wellno])
}


# create properly named factor for wells
df$wellf = factor( as.numeric(df$well)
                 , levels = sort(unique(as.numeric(df$well)))
                 , labels = as.vector(outer( LETTERS[seq( from = 1, to = 6 )]
                                           , seq(from =1, to = 8), paste, sep = "_")))

# plot movement data
require(lattice)

# construct layout for lattice plots such that it corresponds
# to the layout of zebrabox wells (only works for 6x8 layout)
cond = c(seq( 6, 48, 6)
        ,seq( 5, 47, 6)
        ,seq( 4, 46, 6)
        ,seq( 3, 45, 6)
        ,seq( 2, 44, 6)
        ,seq( 1, 43, 6))

# location plot
#xyplot(-y~x|as.factor(well), aspect = 1, pch  = ".", data = df, layout = c(8, 6), index.cond = list(cond))

# trace plot
#xyplot(-y~x|as.factor(well), aspect = 1, type = "l", data = df, layout = c(8, 6), index.cond = list(cond))

# speed plot
#xyplot(speed~frame|as.factor(well), aspect = 1, pch = ".", data = df, layout = c(8, 6), index.cond = list(cond))

# distance plot
xyplot(distance~frame|wellf, aspect = 1, type = "l", data = df, layout = c(8, 6), index.cond = list(cond))

