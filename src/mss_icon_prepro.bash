#!/bin/bash

conda_bin=/home_local/jkretzs/anaconda3/envs/cdo/bin/

# Get some time information
hour=$(date -d "14 hours" +"%k")
init_time_step=$(((($hour+1)/6)))

echo "hour:" $hour
echo "init_step:" $init_time_step


if [ $init_time_step -eq 0 ]
then
    date=`date -d "-1 day" '+%Y%m%d'`
    init_time="18"  
elif [ $init_time_step -eq 1 ]
then
    date=`date -u '+%Y%m%d'`
    init_time="00"
elif [ $init_time_step -eq 2 ]
then
    date=`date -u '+%Y%m%d'`
    init_time="06"
elif [ $init_time_step -eq 3 ]
then
    date=`date -u '+%Y%m%d'`
    init_time="12"
elif [ $init_time_step -eq 4 ]
then
    date=`date -u '+%Y%m%d'`
    init_time="18"
fi
mkdir icon_input/icon_${date}_${init_time}


# Perpare regridding by creating weights if not allready available
grid_dir=/home_local/jkretzs/mss/data/icon/grid
grid_file_icon=${grid_dir}/icon_grid_0026_R03B07_G.nc
target_grid=${grid_dir}/target_grid_eureca_025.txt
weights_remap=${grid_dir}/weights_target_grid_eureca_025.nc
if [ ! -f ${weights_remap} ]
then
    ${conda_bin}cdo gennn,${target_grid} ${grid_file_icon} ${weights_remap}
fi

# Download ICON data from https://opendata.dwd.de/
dwd_base_url=https://opendata.dwd.de/weather/nwp/icon/grib
cd icon_input

# for var in p clc t
# do
#     for step_int in {0..0}
#     do
# 	if [ ${step_int} -lt 10 ]
# 	then
# 	    step=00${step_int}
# 	elif [ ${step_int} -lt 100 ]
# 	then
# 	    step=0${step_int}
# 	else
# 	    step=${step_int}
# 	fi
# 	for lev in {25..90}
# 	do
# 	    file_name=icon_global_icosahedral_model-level_${date}${init_time}_${step}_${lev}_${var^^}.grib2.bz2
# 	    url_var=${dwd_base_url}/${init_time}/${var}/${file_name}
# 	    wget -q ${url_var}
# 	    bzip2 -dq ${file_name}
# 	done
#     done
#     cat *${var^^}.grib2 > ${var}_tmp.grib2
#     cdo -P 2 -f nc remap,${target_grid},${weights_remap} ${var}_tmp.grib2  ${var}_tmp.nc
#     case $var in
# 	clc)	${conda_bin}ncap2 -O -s "ccl=ccl/100" ${var}_tmp.nc ${var}_tmp1.nc
# 		rm ${var}_tmp.nc
# 		mv ${var}_tmp1.nc ${var}_tmp.nc
#     esac
#     rm *.grib2
# done
# cdo merge *_tmp.nc icon.ml.nc
# rm *_tmp.nc

# file_str=icon
# ${conda_bin}ncatted -O -a standard_name,height,o,c,"atmosphere_hybrid_sigma_pressure_coordinate" ${file_str}.ml.nc
# ${conda_bin}ncatted -O -a units,height,o,c,"sigma" ${file_str}.ml.nc
# ${conda_bin}ncatted -O -a standard_name,ccl,o,c,"cloud_area_fraction_in_atmosphere_layer" ${file_str}.ml.nc
# ${conda_bin}ncatted -O -a units,ccl,o,c,"dimensionless" ${file_str}.ml.nc
# ${conda_bin}ncatted -O -a standard_name,pres,c,c,"air_pressure" ${file_str}.ml.nc
# # remove not needed dimension
# ${conda_bin}ncwa -a bnds ${file_str}.ml.nc tmp1_${file_str}.ml.nc
# mv tmp1_${file_str}.ml.nc ${file_str}.ml.nc


# Surface variabels

# for var in u_10m v_10m clct clcl clcm clch pmsl
# do
#     for step_int in {0..9..3}
#     do
# 	if [ ${step_int} -lt 10 ]
# 	then
# 	    step=00${step_int}
# 	elif [ ${step_int} -lt 100 ]
# 	then
# 	    step=0${step_int}
# 	else
# 	    step=${step_int}
# 	fi
# 	file_name=icon_global_icosahedral_single-level_${date}${init_time}_${step}_${var^^}.grib2.bz2
# 	url_var=${dwd_base_url}/${init_time}/${var}/${file_name}
# 	wget -q ${url_var}
# 	bzip2 -dq ${file_name}
#     done
#     cat *${var^^}.grib2 > ${var}_tmp.grib2
#     cdo -P 2 -f nc remap,${target_grid},${weights_remap} ${var}_tmp.grib2  ${var}_tmp.nc
#     # get rid of pressure dimension for leveled data
#     case $var in
# 	clcl|clcm|clch) ${conda_bin}cdo vertmean ${var}_tmp.nc ${var}_test_tmp.nc
# 			${conda_bin}ncap2 -O -s "${var^^}=${var^^}/100" ${var}_test_tmp.nc ${var}_tmp.nc
# 			${conda_bin}ncatted -O -a units,${var^^},o,c,"dimensionless" ${var}_tmp.nc
# 			rm ${var}_test_tmp.nc ;;
# 	u_10m|v_10m) ${conda_bin}cdo vertmean ${var}_tmp.nc ${var}_test_tmp.nc
# 		     mv ${var}_test_tmp.nc ${var}_tmp.nc ;;
# 	clct) ${conda_bin}ncap2 -O -s "${var^^}=${var^^}/100" ${var}_tmp.nc ${var}_test_tmp.nc
# 	      mv ${var}_test_tmp.nc ${var}_tmp.nc
# 	      ${conda_bin}ncatted -O -a units,${var^^},o,c,"dimensionless" ${var}_tmp.nc			
#     esac
#     rm *.grib2
# done
# ${conda_bin}cdo merge *_tmp.nc icon.sfc.nc
# rm *_tmp.nc

# file_str=icon
# ${conda_bin}ncatted -O -a standard_name,prmsl,o,c,"air_pressure_at_sea_level" ${file_str}.sfc.nc
# ${conda_bin}ncatted -O -a standard_name,CLCT,o,c,"total_cloud_cover" ${file_str}.sfc.nc
# ${conda_bin}ncatted -O -a standard_name,CLCL,o,c,"low_cloud_area_fraction" ${file_str}.sfc.nc
# ${conda_bin}ncatted -O -a standard_name,CLCM,o,c,"medium_cloud_area_fraction" ${file_str}.sfc.nc
# ${conda_bin}ncatted -O -a standard_name,CLCH,o,c,"high_cloud_area_fraction" ${file_str}.sfc.nc
# ${conda_bin}ncatted -O -a standard_name,10u,o,c,"surface_eastward_wind" ${file_str}.sfc.nc
# ${conda_bin}ncatted -O -a standard_name,10v,o,c,"surface_northward_wind" ${file_str}.sfc.nc
