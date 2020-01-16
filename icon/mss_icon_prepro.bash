#!/bin/bash

# Get some time information
hour=$(date +"%k")
init_time_step=$(((($hour)/6)-2))
if [ $init_time_step -eq -2 ]
then
    date=`date -d "12 hours ago" '+%Y%m%d'`
    init_time="12"
elif [ $init_time_step -ge -1 -a  $init_time_step -le 0 ]
then
    date=`date -u '+%Y%m%d'`
    init_time="00"
elif [ $init_time_step -ge 1 ]
then
    date=`date -u '+%Y%m%d'`
    init_time="12"
fi

# Perpare regridding
grid_dir=/home_local/jkretzs/mss/data/icon/grid
grid_file_icon=${grid_dir}/icon_grid_0026_R03B07_G.nc
target_grid=${grid_dir}/target_grid_eureca_025.txt
weights_remap=${grid_dir}/weights_target_grid_eureca_025.nc
if [ ! -f ${weights_remap} ]
then
    cdo gennn,${target_grid} ${grid_file_icon} ${weights_remap}
fi

# Download ICON data from https://opendata.dwd.de/
dwd_base_url=https://opendata.dwd.de/weather/nwp/icon/grib
init_time=00

cd icon_input
for var in clct clcl clcm clch
do
    for step_int in {0..9..3}
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
	wget -q ${url_var}
	bzip2 -dq ${file_name}
    done
    cat *${var^^}.grib2 > ${var}_tmp.grib2
    cdo -f nc remap,${target_grid},${weights_remap} ${var}_tmp.grib2  ${var}_tmp.nc
    # get rid of pressure dimension for leveled data
    case $var in
	clcl|clcm|clch) cdo vertmean ${var}_tmp.nc ${var}_vertmean_tmp.nc
	clct) mv ${var}_tmp.nc ${var}_vertmean_tmp.nc
    esac
    rm *.grib2
done
cdo merge *_tmp.nc icon.sfc.nc


# for var in  clct
# do
#     file_name=icon_global_icosahedral_single-level_${date}${init_time}_0${step}_${var^^}.grib2.bz2
#     url_var=${dwd_base_url}/${init_time}/${var}/${file_name}
#     echo $url_var
# done
# wget ${url_var}
# bzip2 -d ${file_name}

#echo "https://opendata.dwd.de/weather/nwp/icon/grib/00/pmsl/icon_global_icosahedral_single-level_2020011600_000_PMSL.grib2.bz2"

#retrieve_str='ecmwf_'${date}'_'${init_time}
#echo $retrieve_str


#https://opendata.dwd.de/weather/nwp/icon/grib/00/pmsl/icon_global_icosahedral_single-level_2020011600_000_PMSL.grib2.bz2


# grid_dir=/home_local/jkretzs/mss/data/icon/grid
# grid_file_icon=${grid_dir}/icon_grid_0026_R03B07_G.nc
# target_grid=${grid_dir}/target_grid_eureca_025.txt
# weights_remap=${grid_dir}/weights_target_grid_eureca_025.nc

# if [ ! -f ${weights_remap} ]
# then
#     cdo gennn,${target_grid} ${grid_file_icon} ${weights_remap}
# fi


# icon_input="/home_local/jkretzs/mss/data/icon/icon_input"
# ifile=icon_global_icosahedral_single-level_2020011600_000_PMSL.grib2
# cdo -f nc remap,${target_grid},${weights_remap} ${icon_input}/${ifile} tmp.nc
