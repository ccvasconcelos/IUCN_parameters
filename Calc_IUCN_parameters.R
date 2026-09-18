########################################################################
# CALCULATION OF PARAMETERS FOR A PRELIMINARY CONSERVATION STATUS
# ASSESSMENT (IUCN Red List, Criterion B) using the ConR package
#
# WHAT THIS SCRIPT DOES:
#   From georeferenced occurrence records, it calculates the geographic
#   and population parameters used under IUCN Criterion B:
#     - EOO  (Extent of Occurrence)
#     - AOO  (Area of Occupancy)
#     - number of subpopulations
#     - number of "locations" sensu IUCN
#     - severe fragmentation of the distribution
#
# WHAT THIS SCRIPT DOES *NOT* DO:
#   It does not assign a threat category (e.g. CR, EN, VU, LC). The
#   parameters calculated here must be interpreted manually against the
#   thresholds and decision rules described in the IUCN guidelines
#   (IUCN Standards and Petitions Committee - Guidelines for Using the
#   IUCN Red List Categories and Criteria), available at:
#   https://www.iucnredlist.org/resources/redlistguidelines
#
# EXAMPLE DATA:
#   georeferenced_specimens.csv - occurrence records of a single species (illustrative).
#   Columns expected by ConR (column POSITION, not name, is what matters):
#     tax    -> taxon name
#     ddlat  -> latitude in decimal degrees
#     ddlon  -> longitude in decimal degrees
#   ("voucher" and "source" are metadata of the example dataset and are
#   not used in the calculations)
#
# PACKAGE:
# Use citation("ConR") for details
########################################################################

# install.packages("devtools")
# devtools::install_github("gdauby/ConR")

library(ConR)
library(sf)             # needed to handle/plot the EOO geometry
library(rnaturalearth)  # provides the world map used for plotting

# ----------------------------------------------------------------------
# 1) READING AND PREPARING THE OCCURRENCE DATA
# ----------------------------------------------------------------------

# The example file must be in the same folder as this script.
MyData <- read.csv("georeferenced_specimens.csv", sep = ",") ; head(MyData)
str(MyData)

# ConR requires the first 3 columns of the input data.frame to be, IN
# THIS ORDER: latitude, longitude, taxon name.
# Here we reorder the columns of the original file (tax, voucher, ddlat,
# ddlon, source) into the format required by ConR (ddlat, ddlon, tax).
occs <- MyData[, c(3, 4, 1)] ; head(occs)

# ----------------------------------------------------------------------
# 2) COORDINATE VALIDATION
# ----------------------------------------------------------------------
# coord.check() flags invalid coordinates (e.g. outside the lat/lon
# range, at (0,0), duplicated) and returns the number of spatially
# unique and valid occurrences per taxon - the basis for all
# calculations below.
nb.occs <- coord.check(XY = occs)
nb.occs <- nb.occs$unique_occs
nb.occs

# ----------------------------------------------------------------------
# 3) EXTENT OF OCCURRENCE (EOO)
# ----------------------------------------------------------------------
# EOO = area of the smallest convex polygon ("convex hull") enclosing
# all records. It is one of the two core geographic parameters of
# Criterion B (subcriterion B1).
# ?EOO.computing
EOO.hull <- EOO.computing(
  XY = occs,
  method.range = "convex.hull", # delimitation method (alternative: "alpha.hull")
  export_shp = TRUE,            # also returns the EOO polygon geometry, used for the map below
  show_progress = FALSE
) ; print(EOO.hull)

# ----------------------------------------------------------------------
# 4) AREA OF OCCUPANCY (AOO)
# ----------------------------------------------------------------------
# AOO = sum of the area of the grid cells (here, 2x2 km) that contain
# at least one record. Corresponds to IUCN subcriterion B2.
# ?AOO.computing
AOO <- AOO.computing(
  occs,
  cell_size_AOO = 2,        # grid cell size, in km (IUCN standard = 2 km)
  nbe.rep.rast.AOO = 30,    # number of random grid shifts tested, so
                             # that the arbitrary position of the grid
                             # does not underestimate the true AOO
  show_progress = FALSE
) ; AOO

# ----------------------------------------------------------------------
# 5) NUMBER OF SUBPOPULATIONS
# ----------------------------------------------------------------------
# subpop.radius() uses the observed spatial distribution of the points
# to estimate the radius (in km) to be used in the "circular buffer"
# method (Rivers et al. 2010) that delimits subpopulations. This radius
# is also used here as a proxy for the species' dispersal ability.
# ?subpop.radius
radius <- subpop.radius(
  XY = occs,
  quant.max = 0.9  # quantile of the distribution of nearest-neighbour
                    # distances between occurrences used to define the
                    # radius; 0.9 avoids a few very distant outliers
                    # inflating the estimated radius
) ; print(radius)

# subpop.comp() applies the radius estimated above: points whose
# buffers overlap are merged into a single subpopulation; isolated
# buffers form separate subpopulations.
# ?subpop.comp
sub <- subpop.comp(
  XY = occs,
  resol_sub_pop = radius[, c("tax", "radius")],
  show_progress = FALSE
) ; print(sub)

# ----------------------------------------------------------------------
# 6) NUMBER OF "LOCATIONS" (sensu IUCN)
# ----------------------------------------------------------------------
# "Location" is a concept distinct from subpopulation: it is a
# geographically/ecologically distinct area in which a single event
# (e.g. deforestation, fire) could rapidly affect all individuals of
# the taxon present there. Here it is estimated with a fixed grid, in
# the absence of a spatially explicit threat layer.
# ?locations.comp
locs <- locations.comp(
  occs,
  method = "fixed_grid",         # fixed grid (alternative: "sliding_scale")
  nbe_rep = 30,                  # replicates with random grid shifts
  cell_size_locations = 10,      # cell size, in km
  rel_cell_size = 0.05,          # used only if method = "sliding_scale"
  # threat_list = strict.ucs.spdf,     # shapefile of spatially explicit threats (not used in this example)
  # id_shape = "NAME",                 # ID field of the threat shapefile
  method_polygons = "no_more_than_one",
  show_progress = FALSE
) ; print(locs)

# ----------------------------------------------------------------------
# 7) SEVERE FRAGMENTATION
# ----------------------------------------------------------------------
# Assesses whether the distribution is severely fragmented, i.e.
# whether most individuals occur in subpopulations that are small and
# isolated from each other (an additional condition considered under
# B1/B2).
# ?severe_frag
sever.frag <- severe_frag(
  XY = occs,
  resol_sub_pop = radius[, c("tax", "radius")],
  dist_isolated = radius$radius, # distance (km) above which two
                                  # subpopulations are considered isolated
  show_progress = FALSE
) ; print(sever.frag)

# ----------------------------------------------------------------------
# 8) EOO MAP
# ----------------------------------------------------------------------
# Simple visualisation of the EOO polygon over the world map.
land <- ne_countries(scale = 50, returnclass = "sf")
red_col <- rgb(255, 0, 0, alpha = 127, maxColorValue = 255)

# Bounding box of the EOO, with an extra margin so the plot is zoomed in
# on the species' range instead of showing the whole world.
bbox <- sf::st_bbox(EOO.hull$spatial$geometry)
margin <- 6  # decimal degrees; increase/decrease depending on the extent of the area

plot(sf::st_geometry(land), col = "grey", border = "grey40",
     xlim = c(bbox["xmin"] - margin, bbox["xmax"] + margin),
     ylim = c(bbox["ymin"] - margin, bbox["ymax"] + margin))
plot(EOO.hull$spatial$geometry, col = red_col, add = TRUE)


# ----------------------------------------------------------------------
# 9) SUMMARY OF CALCULATED PARAMETERS
# ----------------------------------------------------------------------
# These are the raw values to be compared against the Criterion B
# thresholds in the IUCN guidelines to reach a preliminary category
# (this is NOT done by this script).
nb.occs                   # number of unique, valid occurrences
EOO.hull$results$eoo      # EOO, in km2
AOO$aoo                    # AOO, in km2
sub$subpop                 # number of subpopulations
locs$locations$locations  # number of locations
sever.frag                 # severe fragmentation result (logical/proportion, depending on ConR version)
