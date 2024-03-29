# code to visualize long term conductivity in lake sunapee

source('conductivity_summary.R')

library(sf)
library(tmap)
library(raster)
library(gifski)
library(ggthemes)

#point to local spatial files folder
gis_dir <- 'C:/Users/steeleb/Dropbox/travel/gis/project/Sunapee/'

stream_pal = c('#f2f0f7','#dadaeb','#bcbddc','#9e9ac8','#756bb1','#54278f')
lake_pal = c('#fef0d9','#fdd49e','#fdbb84','#fc8d59','#e34a33')

#point to dump directory
dump_dir <- 'C:/Users/steeleb/Dropbox/Lake Sunapee/misc/state of the lake/figs/summer_cond/'

final_theme=theme_bw() +
  theme(axis.text=element_text(size=12),
        axis.title=element_text(size=14,face="bold"),
        plot.title=element_text(size=16, face='bold', hjust=0.5)) #save as a grom

## load the spatial layers ####

#sunapee shoreline
sunapee_shore = st_read(file.path(gis_dir, 'hydrography/LS_shore_WGS.shp'))
#bathy
sun_bathy <- raster(file.path(gis_dir, 'Sunapee Bathymetry/raster_files/originals/sun_ras_z_m'))
#sunpaee streams
sun_stream <- st_read(file.path(gis_dir, 'hydrography/streams.shp'))
sun_stream_wgs <- st_transform(sun_stream, crs = 'EPSG:4326')
#sunapee open water
sun_ws_water <- st_read(file.path(gis_dir, 'hydrography/waterbodies open water.shp'))
sun_ws_water_wgs <- st_transform(sun_ws_water, crs = 'EPSG:4326')

#table to sf for med and max cond
aggcond <- st_as_sf(lmp_agg_lake, coords = c('lon_dd', 'lat_dd'), crs = 'EPSG:4326')

#define bounding box fo vis
#get bounding box of bathy
bbox_sunapee <- st_bbox(sun_bathy) # current bounding box

xrange <- bbox_sunapee$xmax - bbox_sunapee$xmin # range of x values
yrange <- bbox_sunapee$ymax - bbox_sunapee$ymin # range of y values

#create a new one and modify
bbox_sun_new <- st_bbox(sun_bathy) 
bbox_sun_new[1] <- bbox_sun_new[1] - (0.1 * xrange) # xmin - left
bbox_sun_new[3] <- bbox_sun_new[3] + (0.1 * xrange) # xmax - right
bbox_sun_new[2] <- bbox_sun_new[2] - (0.025 * yrange) # ymin - bottom
bbox_sun_new[4] <- bbox_sun_new[4] + (0.05 * yrange) # ymax - top

## visualize in paneled plots ####

paneled_meancond = tm_shape(sunapee_shore, bbox = bbox_sun_new) + tm_borders() +tm_fill() +
  tm_shape(subset(aggcond, subset = year >=1997)) +
  tm_bubbles(col = 'mean_cond_uScm',
             shape = 24,
             palette = lake_pal,
             title.col = 'mean summer\nconductivity\n(uS/cm)',
             border.col = 'black') +
  tm_facets(by = 'year',
            ncol = 8) +
  tm_layout(panel.label.size = 1.5,
            panel.label.fontface = 'bold')
paneled_meancond

tmap_save(paneled_meancond, 
          filename = file.path(dump_dir, 'mean_cond_summer_paneled_1997_2020.png'),
          width = 8,
          height = 6,
          dpi = 300)


paneled_medcond = tm_shape(sunapee_shore, bbox = bbox_sun_new) + tm_borders() +tm_fill() +
  tm_shape(subset(aggcond, subset = year >=1997)) +
  tm_bubbles(col = 'med_cond_uScm',
             shape = 24,
             palette = lake_pal,
             title.col = 'median summer\nconductivity\n(uS/cm)',
             border.col = 'black') +
  tm_facets(by = 'year',
            ncol = 8) +
  tm_layout(panel.label.size = 1.5,
            panel.label.fontface = 'bold')
paneled_medcond

tmap_save(paneled_medcond, filename = file.path(dump_dir, 'med_cond_summer_paneled_1997_2020.png'),
          width = 8,
          height = 6,
          dpi = 300)

## visualize in animated plot ####

#store faceted med cond - ncol and nrow must be 1
cond_med_facet <- tm_shape(sun_bathy, bbox = bbox_sun_new) + tm_raster(palette = 'Blues',
                                                                       title = 'lake depth\n(meters)',
                                                                       contrast = c(0, 0.5)) +
  tm_shape(sunapee_shore) + tm_borders() +
  tm_shape(subset(aggcond, subset = year >=1997)) +
  tm_bubbles(col = 'med_cond_uScm',
             title.col = 'median summer\nconductivity\n(uS/cm)',
             border.col = 'black') +
  tm_facets(by = 'year',
            ncol = 1,
            nrow = 1)+
  tm_layout(panel.label.size = 1.5,
            panel.label.fontface = 'bold')


#export gif
tmap_animation(cond_med_facet,
               filename = file.path(dump_dir, 'med_cond_summer_ani_1997_2020_v3.gif'),
               fps = 1,
               dpi = 300)



#store faceted mean cond - ncol and nrow must be 1
cond_mean_facet <- tm_shape(sun_bathy, bbox = bbox_sun_new) + tm_raster(palette = 'Blues',
                                                                        title = 'lake depth\n(meters)',
                                                                        contrast = c(0, 0.5)) +
  tm_shape(sunapee_shore) + tm_borders() +
  tm_shape(subset(aggcond, subset = year >=1997)) +
  tm_bubbles(col = 'mean_cond_uScm',
             title.col = 'mean summer\nconductivity\n(uS/cm)',
             border.col = 'black') +
  tm_facets(by = 'year',
            ncol = 8) +
  tm_layout(panel.label.size = 1.5,
            panel.label.fontface = 'bold') +
  tm_facets(by = 'year',
            ncol = 1,
            nrow = 1)+
  tm_layout(panel.label.size = 1.5,
            panel.label.fontface = 'bold')


#export gif
tmap_animation(cond_mean_facet,
               filename = file.path(dump_dir, 'mean_cond_summer_ani_1997_2020_v3.gif'),
               fps = 1,
               dpi = 300)




## visualize stream cond in paneled plots ----

#table to sf for med and max cond
aggcond_stream <- st_as_sf(agg_cond_stream, coords = c('lon_dd', 'lat_dd'), crs = 'EPSG:4326')

# sunapee watershed
sun_ws <- st_read(file.path(gis_dir, 'watersheds/NH_hydro_Sunapee/Lake_Sunapee_watershed.shp'))
sun_ws_wgs <- st_transform(sun_ws, crs = 'EPSG:4326')

bbox_sun_ws <- st_bbox(sun_ws_wgs)

## visualize in paneled plots ####
paneled_maxcond_stream = tm_shape(sunapee_shore, bbox = bbox_sun_ws) + tm_polygons() +
  tm_shape(sun_ws_wgs) + tm_borders() +
  tm_shape(sun_stream_wgs) + tm_lines(col = 'grey') +
  tm_shape(sun_ws_water_wgs) + tm_polygons() +
  tm_shape(subset(aggcond_stream, subset = year >=1997)) +
  tm_bubbles(col = 'max_cond_uScm',
             palette = stream_pal,
             title.col = 'maximum summer\nconductivity\n(uS/cm)',
             border.col = 'black') +
  tm_facets(by = 'year',
            ncol = 8) +
  tm_layout(panel.label.size = 1.5,
            panel.label.fontface = 'bold')
paneled_maxcond_stream

tmap_save(paneled_maxcond_stream, 
          filename = file.path(dump_dir, 'max_cond_summer_stream_paneled_1997_2020.png'),
          width = 8,
          height = 6,
          dpi = 300)

paneled_meancond_stream = tm_shape(sunapee_shore, bbox = bbox_sun_ws) + tm_polygons() +
  tm_shape(sun_ws_wgs) + tm_borders() +
  tm_shape(sun_stream_wgs) + tm_lines(col = 'grey') +
  tm_shape(sun_ws_water_wgs) + tm_polygons() +
  tm_shape(subset(aggcond_stream, subset = year >=1997)) +
  tm_bubbles(col = 'mean_cond_uScm',
             palette = stream_pal,
             title.col = 'average summer\nconductivity\n(uS/cm)',
             border.col = 'black') +
  tm_facets(by = 'year',
            ncol = 8) +
  tm_layout(panel.label.size = 1.5,
            panel.label.fontface = 'bold')
paneled_meancond_stream

tmap_save(paneled_meancond_stream, filename = file.path(dump_dir, 'mean_cond_summer_stream_paneled_1997_2020.png'),
          width = 8,
          height = 6,
          dpi = 300)

paneled_medcond_stream = tm_shape(sunapee_shore, bbox = bbox_sun_ws) + tm_polygons() +
  tm_shape(sun_ws_wgs) + tm_borders() +
  tm_shape(sun_stream_wgs) + tm_lines(col = 'grey') +
  tm_shape(sun_ws_water_wgs) + tm_polygons() +
  tm_shape(subset(aggcond_stream, subset = year >=1997)) +
  tm_bubbles(col = 'med_cond_uScm',
             palette = stream_pal,
             title.col = 'median summer\nconductivity\n(uS/cm)',
             border.col = 'black') +
  tm_facets(by = 'year',
            ncol = 8) +
  tm_layout(panel.label.size = 1.5,
            panel.label.fontface = 'bold')
paneled_medcond_stream

tmap_save(paneled_medcond_stream, filename = file.path(dump_dir, 'med_cond_summer_stream_paneled_1997_2020.png'),
          width = 8,
          height = 6,
          dpi = 300)

paneled_thquancond_stream = tm_shape(sunapee_shore, bbox = bbox_sun_ws) + tm_polygons() +
  tm_shape(sun_ws_wgs) + tm_borders() +
  tm_shape(sun_stream_wgs) + tm_lines(col = 'grey') +
  tm_shape(sun_ws_water_wgs) + tm_polygons() +
  tm_shape(subset(aggcond_stream, subset = year >=1997)) +
  tm_bubbles(col = 'thquan_cond_uScm',
             palette = stream_pal,
             title.col = 'third quantile summer\nconductivity\n(uS/cm)',
             border.col = 'black') +
  tm_facets(by = 'year',
            ncol = 8) +
  tm_layout(panel.label.size = 1.5,
            panel.label.fontface = 'bold')
paneled_thquancond_stream

tmap_save(paneled_thquancond_stream, filename = file.path(dump_dir, 'thquan_cond_summer_stream_paneled_1997_2020.png'),
          width = 8,
          height = 6,
          dpi = 300)

## vis in animated plots ----

#store faceted max cond - ncol and nrow must be 1
cond_max_stream_facet <- tm_shape(sunapee_shore, bbox = bbox_sun_ws) + tm_polygons() +
  tm_shape(sun_ws_wgs) + tm_borders() +
  tm_shape(sun_stream_wgs) + tm_lines(col = 'blue') +
  tm_shape(sun_ws_water_wgs) + tm_polygons() +
  tm_shape(subset(aggcond_stream, subset = year >=1997)) +
  tm_bubbles('max_cond_uScm',
             col = 'green',
             title.size = 'maximum summer\nconductivity\n(uS/cm)',
             border.col = 'black',
             scale = 3) +
  tm_facets(by = 'year',
            ncol = 1,
            nrow = 1) +
  tm_layout(panel.label.size = 1.5,
            panel.label.fontface = 'bold')

#export gif
tmap_animation(cond_max_stream_facet,
               filename = file.path(dump_dir, 'max_cond_summer_stream_ani_1997_2020.gif'),
               fps = 1,
               dpi = 300)

#store faceted med cond - ncol and nrow must be 1
cond_med_stream_facet <- tm_shape(sunapee_shore, bbox = bbox_sun_ws) + tm_polygons() +
  tm_shape(sun_ws_wgs) + tm_borders() +
  tm_shape(sun_stream_wgs) + tm_lines(col = 'blue') +
  tm_shape(sun_ws_water_wgs) + tm_polygons() +
  tm_shape(subset(aggcond_stream, subset = year >=1997)) +
  tm_bubbles('med_cond_uScm',
             col = 'green',
             title.size = 'median summer\nconductivity\n(uS/cm)',
             border.col = 'black',
             scale = 3) +
  tm_facets(by = 'year',
            ncol = 1,
            nrow = 1) +
  tm_layout(panel.label.size = 1.5,
            panel.label.fontface = 'bold')

#export gif
tmap_animation(cond_med_stream_facet,
               filename = file.path(dump_dir, 'med_cond_summer_stream_ani_1997_2020.gif'),
               fps = 1,
               dpi = 300)

#store faceted mean cond - ncol and nrow must be 1
cond_mean_stream_facet <- tm_shape(sunapee_shore, bbox = bbox_sun_ws) + tm_polygons() +
  tm_shape(sun_ws_wgs) + tm_borders() +
  tm_shape(sun_stream_wgs) + tm_lines(col = 'blue') +
  tm_shape(sun_ws_water_wgs) + tm_polygons() +
  tm_shape(subset(aggcond_stream, subset = year >=1997)) +
  tm_bubbles('mean_cond_uScm',
             col = 'green',
             title.size = 'mean summer\nconductivity\n(uS/cm)',
             border.col = 'black',
             scale = 3) +
  tm_facets(by = 'year',
            ncol = 1,
            nrow = 1) +
  tm_layout(panel.label.size = 1.5,
            panel.label.fontface = 'bold')

#export gif
tmap_animation(cond_mean_stream_facet,
               filename = file.path(dump_dir, 'mean_cond_summer_stream_ani_1997_2020.gif'),
               fps = 1,
               dpi = 300)

#store faceted thquan cond - ncol and nrow must be 1
cond_thquan_stream_facet <- tm_shape(sunapee_shore, bbox = bbox_sun_ws) + tm_polygons() +
  tm_shape(sun_ws_wgs) + tm_borders() +
  tm_shape(sun_stream_wgs) + tm_lines(col = 'blue') +
  tm_shape(sun_ws_water_wgs) + tm_polygons() +
  tm_shape(subset(aggcond_stream, subset = year >=1997)) +
  tm_bubbles('thquan_cond_uScm',
             col = 'green',
             title.size = 'third quantile summer\nconductivity\n(uS/cm)',
             border.col = 'black',
             scale = 3) +
  tm_facets(by = 'year',
            ncol = 1,
            nrow = 1) +
  tm_layout(panel.label.size = 1.5,
            panel.label.fontface = 'bold')

#export gif
tmap_animation(cond_thquan_stream_facet,
               filename = file.path(dump_dir, 'thquan_cond_summer_stream_ani_1997_2020.gif'),
               fps = 1,
               dpi = 300)


# both together (paneled only) ----


#mean cond stream and lake
paneled_meancond_stream_lake = tm_shape(sunapee_shore, bbox = bbox_sun_ws) + tm_polygons() +
  tm_shape(sun_ws_wgs) + tm_borders() +
  tm_shape(sun_stream_wgs) + tm_lines(col = 'grey') +
  tm_shape(sun_ws_water_wgs) + tm_polygons() +
  tm_shape(subset(aggcond, subset = year >=1997)) +
  tm_symbols(col = 'mean_cond_uScm',
             shape = 24,
             pal = lake_pal,
             title.col = 'mean summer\nin lake\nconductivity\n(uS/cm)',
             border.col = 'black') +
  tm_facets(by = 'year',
            ncol = 8) +
  tm_shape(subset(aggcond_stream, subset = year >=1997)) +
    tm_symbols(col = 'mean_cond_uScm',
               pal = stream_pal,
               shape = 21,
               title.col = 'mean summer\nstream\nconductivity\n(uS/cm)',
               border.col = 'black') +
    tm_facets(by = 'year',
              ncol = 8) +
  tm_layout(panel.label.size = 1.5,
            panel.label.fontface = 'bold')
paneled_meancond_stream_lake

tmap_save(paneled_meancond_stream_lake, 
          filename = file.path(dump_dir, 'mean_cond_summer_streamlake_paneled_1997_2020.png'),
          width = 8,
          height = 6,
          dpi = 300)


#med cond stream and lake
paneled_medcond_stream_lake = tm_shape(sunapee_shore, bbox = bbox_sun_ws) + tm_polygons() +
  tm_shape(sun_ws_wgs) + tm_borders() +
  tm_shape(sun_stream_wgs) + tm_lines(col = 'grey') +
  tm_shape(sun_ws_water_wgs) + tm_polygons() +
  tm_shape(subset(aggcond_stream, subset = year >=1997)) +
  tm_symbols(col = 'med_cond_uScm',
             palette = stream_pal,
             shape = 21,
             title.col = 'median summer\nstream\nconductivity\n(uS/cm)',
             border.col = 'black') +
  tm_facets(by = 'year',
            ncol = 8) +
  tm_shape(subset(aggcond, subset = year >=1997)) +
  tm_symbols(col = 'med_cond_uScm',
             shape = 24,
             palette = lake_pal,
             title.col = 'median summer\nin lake\nconductivity\n(uS/cm)',
             border.col = 'black') +
  tm_facets(by = 'year',
            ncol = 8) +
  
  tm_layout(panel.label.size = 1.5,
            panel.label.fontface = 'bold')
paneled_medcond_stream_lake

tmap_save(paneled_medcond_stream_lake, 
          filename = file.path(dump_dir, 'med_cond_summer_streamlake_paneled_1997_2020.png'),
          width = 8,
          height = 6,
          dpi = 300)


# single-panel 10-year average ----
lmp_cond_lake <- left_join(lmp_cond_lake, lmp_locs)
cond <- full_join(lmp_cond_lake, lmp_summer_cond_stream) %>% 
  filter(year > 2010) 
  
unique(cond$month)

cond_summary <- cond %>% 
  group_by(station, site_type, lat_dd, lon_dd) %>% 
  summarize(n = n(),
            mean_cond_uScm = mean(value),
            med_cond_uScm = median(value)) %>% 
  filter(!is.na(lat_dd)) 

cond_summary_stream <- cond_summary %>% 
  filter(site_type == 'stream')
cond_summary_lake <- cond_summary %>% 
  filter(site_type == 'lake')
cond_summary_stream <- st_as_sf(cond_summary_stream, coords = c('lon_dd', 'lat_dd'), crs = 'EPSG:4326')
cond_summary_lake <- st_as_sf(cond_summary_lake, coords = c('lon_dd', 'lat_dd'), crs = 'EPSG:4326')


lt_cond_ave <- tm_shape(sunapee_shore, bbox = bbox_sun_ws) + tm_polygons() +
  tm_shape(sun_ws_wgs) + tm_borders() +
  tm_shape(sun_stream_wgs) + tm_lines(col = 'black') +
  tm_shape(sun_ws_water_wgs) + tm_polygons() +
  tm_shape(cond_summary_stream) +
  tm_symbols(col = 'mean_cond_uScm',
             palette = stream_pal,
             shape = 21,
             title.col = 'average summer\nconductivity (stream)\n(uS/cm)',
             border.col = 'black') +
  tm_shape(cond_summary_lake) +
  tm_symbols(col = 'mean_cond_uScm',
             palette = lake_pal,
             shape = 24,
             title.col = 'average summer\nconductivity (lake)\n(uS/cm)',
             border.col = 'black') +
  tm_layout(legend.outside = T,
            legend.title.fontface = 'bold',
            legend.title.size = 0.9,
            legend.text.size = 0.9,
            title = 'Average Summer\nConductivity\n(Jun-Sept,\n2011-2020)\n ',
            title.fontface = 'bold')
tmap_save(lt_cond_ave, filename = file.path(dump_dir, 'average_longterm_conductivity_2010-2020.png'),
          height = 6, width =5, dpi = 300)

lt_cond_med <- tm_shape(sunapee_shore, bbox = bbox_sun_ws) + tm_polygons() +
  tm_shape(sun_ws_wgs) + tm_borders() +
  tm_shape(sun_stream_wgs) + tm_lines(col = 'blue') +
  tm_shape(sun_ws_water_wgs) + tm_polygons() +
  tm_shape(cond_summary_stream) +
  tm_symbols(col = 'med_cond_uScm',
             palette = stream_pal,
             shape = 21,
             title.col = 'median summer\nconductivity (stream)\n(uS/cm)',
             border.col = 'black') +
  tm_shape(cond_summary_lake) +
  tm_symbols(col = 'med_cond_uScm',
             palette = lake_pal,
             shape = 24,
             title.col = 'median summer\nconductivity (lake)\n(uS/cm)',
             border.col = 'black') +
  tm_layout(legend.outside = T,
            legend.title.fontface = 'bold',
            legend.title.size = 0.9,
            legend.text.size = 0.9,
            title = 'Median Summer\nConductivity\n(Jun-Sept,\n2011-2020)\n ',
            title.fontface = 'bold')
tmap_save(lt_cond_med, filename = file.path(dump_dir, 'median_longterm_conductivity_2010-2020.png'),
          height = 6, width =5, dpi = 300)

