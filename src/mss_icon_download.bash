#!/bin/bash

set -x

# This directory should be set to location of this script. Necessary for cronjob
workdir='/home/mss/mss_data/src/'

# Give path to MSS prepro anaconda bin
conda_base_path=/home/mss/miniconda3
conda_prepro_instance=mss_prepro
conda_prepro_bin=${conda_base_path}/envs/${conda_prepro_instance}/bin
if [[ ${PATH} != *${conda_prepro_bin}* ]]
then
    export PATH=${conda_prepro_bin}:${PATH}
fi

# Number of processes used for uncompression *.bz2 files
nproc=6

# Get some time information 
hour=$(date +"%k")

# 12 hourly request
init_time_step=$(((($hour)/6)))
if [ $init_time_step -eq 0 ]
then
    date=`date -d "-1 day" '+%Y%m%d'`
    init_time="12"
elif [ $init_time_step -eq 1 ]
then
    date=`date -u '+%Y%m%d'`
    init_time="00"
elif [ $init_time_step -eq 2 ]
then
    date=`date -u '+%Y%m%d'`
    init_time="00"
elif [ $init_time_step -eq 3 ]
then
    date=`date -u '+%Y%m%d'`
    init_time="12"
fi

file_str=icon_${date}_${init_time}

# Create directory where 
icon_input_day=${workdir}/../icon_input/${file_str}
if [ ! -d  ${icon_input_day} ]
then
    mkdir -p ${icon_input_day}
fi

# Perpare regridding by creating weights if not allready available
grid_dir=${workdir}/../icon_grid
grid_file_icon=${grid_dir}/icon_grid_0026_R03B07_G.nc
target_grid=${grid_dir}/target_grid_svalbard_025.txt
weights_remap=${grid_dir}/weights_target_grid_svalbard_025.nc

if [ ! -f ${weights_remap} ]
then
     cdo gendis,${target_grid} ${grid_file_icon} ${weights_remap}
fi

# Download ICON data from https://opendata.dwd.de/
dwd_base_url=https://opendata.dwd.de/weather/nwp/icon/grib
cd ${icon_input_day}

# Surface variabels
if [ ! -e $workdir/../icon_input/${file_str}/${file_str}.sfc.nc ]
then
    for var in u_10m v_10m clct clcl clcm clch pmsl
    do
	for step_int in {0..72..3}
	do
	    if [ ${step_int} -lt 10 ]
	    then
		step=00${step_int}
	    elif [ ${step_int} -lt 100 ]
	    then
		step=0${step_int}
	    else
		step=${step_int}
	    fi
	    file_name=icon_global_icosahedral_single-level_${date}${init_time}_${step}_${var^^}.grib2.bz2
	    url_var=${dwd_base_url}/${init_time}/${var}/${file_name}
	    wget -q ${url_var}&
	done
	wait
	find -name "*.bz2" -print0 | xargs -0 -n1 -P${nproc} bzip2 -d
	cat *${var^^}.grib2 > ${var}_tmp.grib2
	cdo -P 2 -f nc remap,${target_grid},${weights_remap} ${var}_tmp.grib2  ${var}_tmp.nc
	# get rid of pressure dimension for leveled data
	case $var in
	    clcl|clcm|clch) cdo vertmean ${var}_tmp.nc ${var}_test_tmp.nc
			    ncap2 -O -s "${var^^}=${var^^}/100" ${var}_test_tmp.nc ${var}_tmp.nc
			    ncatted -O -a units,${var^^},o,c,"dimensionless" ${var}_tmp.nc
			    rm ${var}_test_tmp.nc ;;
	    u_10m|v_10m) cdo vertmean ${var}_tmp.nc ${var}_test_tmp.nc
			 mv ${var}_test_tmp.nc ${var}_tmp.nc ;;
	    clct) ncap2 -O -s "${var^^}=${var^^}/100" ${var}_tmp.nc ${var}_test_tmp.nc
		  mv ${var}_test_tmp.nc ${var}_tmp.nc
		  ncatted -O -a units,${var^^},o,c,"dimensionless" ${var}_tmp.nc			
	esac
	rm *.grib2
    done
    cdo merge *_tmp.nc ${file_str}.sfc.nc
    rm *_tmp.nc

    ncatted -O -a standard_name,prmsl,o,c,"air_pressure_at_sea_level" ${file_str}.sfc.nc
    ncatted -O -a standard_name,CLCT,o,c,"total_cloud_cover" ${file_str}.sfc.nc
    ncatted -O -a standard_name,CLCL,o,c,"low_cloud_area_fraction" ${file_str}.sfc.nc
    ncatted -O -a standard_name,CLCM,o,c,"medium_cloud_area_fraction" ${file_str}.sfc.nc
    ncatted -O -a standard_name,CLCH,o,c,"high_cloud_area_fraction" ${file_str}.sfc.nc
    ncatted -O -a standard_name,10u,o,c,"surface_eastward_wind" ${file_str}.sfc.nc
    ncatted -O -a standard_name,10v,o,c,"surface_northward_wind" ${file_str}.sfc.nc
fi


if [ ! -e $workdir/../icon_input/${file_str}/${file_str}.ml.nc ]
then
    for var in p clc t qv  
    do
	for step_int in {0..72..3}
	do
	    if [ ${step_int} -lt 10 ]
	    then
		step=00${step_int}
	    elif [ ${step_int} -lt 100 ]
	    then
		step=0${step_int}
	    else
		step=${step_int}
	    fi
	    for lev in {36..90}
	    do
		file_name=icon_global_icosahedral_model-level_${date}${init_time}_${step}_${lev}_${var^^}.grib2.bz2
		url_var=${dwd_base_url}/${init_time}/${var}/${file_name}
		wget -q ${url_var} &
	    done
	    wait
          find -name "*.bz2" -print0 | xargs -0 -n1 -P${nproc} bzip2 -d
	done
	cat *${var^^}.grib2 > ${var}_tmp.grib2
	cdo -P 2 -f nc remap,${target_grid},${weights_remap} ${var}_tmp.grib2  ${var}_tmp.nc
	case $var in
	    clc)	ncap2 -O -s "ccl=ccl/100" ${var}_tmp.nc ${var}_tmp1.nc
			rm ${var}_tmp.nc
			mv ${var}_tmp1.nc ${var}_tmp.nc
	esac
	rm *.grib2
    done
    cdo merge *_tmp.nc ${file_str}.ml.nc
    rm *_tmp.nc
    ncatted -O -a standard_name,height,o,c,"atmosphere_hybrid_sigma_pressure_coordinate" ${file_str}.ml.nc
    ncatted -O -a units,height,o,c,"sigma" ${file_str}.ml.nc
    ncatted -O -a standard_name,ccl,o,c,"cloud_area_fraction_in_atmosphere_layer" ${file_str}.ml.nc
    ncatted -O -a units,ccl,o,c,"dimensionless" ${file_str}.ml.nc
    ncatted -O -a standard_name,pres,c,c,"air_pressure" ${file_str}.ml.nc
    # remove not needed dimension
    ncwa -a bnds ${file_str}.ml.nc tmp1_${file_str}.ml.nc
    mv tmp1_${file_str}.ml.nc ${file_str}.ml.nc
fi


# Only copy last 3 initialization times
rm $workdir/../mss_prepro/icon*.nc
icon_inits=($workdir/../icon_input/*)
icon_inits_list=(${icon_inits[-1]} ${icon_inits[-2]}  ${icon_inits[-3]})
for init_dir in ${icon_inits_list[@]}
do
    if [ -f ${init_dir}/*.sfc.nc -a  ${init_dir}/*.ml.nc ]
    then
	ln -s ${init_dir}/*.nc $workdir/../mss_prepro
    fi
done
