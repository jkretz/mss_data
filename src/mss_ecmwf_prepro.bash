#!/bin/bash

workdir=`pwd`

# Input for ECMWF raw data
mkdir -p ecmwf_input

# Input for preproccses ECMWF data that is used by mss
mkdir -p ecmwf_prepro

# Download data from mistral (painful but necessary)
# ssh-add
# rsync -avhP b380425@mistral.dkrz.de:/scratch/b/b380425/mss/* ecmwf_input/

# Path to anaconda bin (this can be done nicer)
conda_bin=/home/mss/miniconda3/envs/mss_prepro/bin/

# Setting up datasets that will be used in the preprocessing
ecmwf_inits=(ecmwf_input/*)
ecmwf_inits_list=(${ecmwf_inits[-1]} ${ecmwf_inits[-2]}  ${ecmwf_inits[-3]})

for init_dir in ${ecmwf_inits_list[@]}
do
    cd ${workdir}
    cd $init_dir
    file_str="$(echo $init_dir | cut -d'/' -f2)"
    if [ -f ${workdir}/ecmwf_prepro/${file_str}.sfc.nc -a -f ${workdir}/ecmwf_prepro/${file_str}.ml.nc -a -f ${workdir}/ecmwf_prepro/${file_str}.ml.nc ]
    then
  	continue
    fi

    # Convert grib to netcdf
    ${conda_bin}cdo  -t ecmwf -f nc copy ${file_str}_sfc.grb ${file_str}.sfc.nc
    ${conda_bin}cdo -t ecmwf -f nc copy ${file_str}_ml.grb tmp_ml.nc
    ${conda_bin}cdo -t ecmwf -f nc copy ${file_str}_pl.grb tmp_pl.nc


    # Process the model level data using a python script
    ${conda_bin}python ../../mss_ml_prepro.py tmp_ml.nc ${file_str}.sfc.nc ${file_str}.ml.nc
    rm tmp_ml.nc

    # Process the surface data
    ${conda_bin}ncatted -O -a standard_name,MSL,o,c,"air_pressure_at_sea_level" ${file_str}.sfc.nc
    ${conda_bin}ncatted -O -a standard_name,TCC,o,c,"total_cloud_cover" ${file_str}.sfc.nc
    ${conda_bin}ncatted -O -a units,TCC,c,c,"dimensionless" ${file_str}.sfc.nc
    ${conda_bin}ncatted -O -a standard_name,LCC,o,c,"low_cloud_area_fraction" ${file_str}.sfc.nc
    ${conda_bin}ncatted -O -a units,LCC,c,c,"dimensionless" ${file_str}.sfc.nc
    ${conda_bin}ncatted -O -a standard_name,MCC,o,c,"medium_cloud_area_fraction" ${file_str}.sfc.nc
    ${conda_bin}ncatted -O -a units,MCC,c,c,"dimensionless" ${file_str}.sfc.nc
    ${conda_bin}ncatted -O -a standard_name,HCC,o,c,"high_cloud_area_fraction" ${file_str}.sfc.nc
    ${conda_bin}ncatted -O -a units,HCC,c,c,"dimensionless" ${file_str}.sfc.nc
    ${conda_bin}ncatted -O -a standard_name,U10M,o,c,"surface_eastward_wind" ${file_str}.sfc.nc
    ${conda_bin}ncatted -O -a standard_name,V10M,o,c,"surface_northward_wind" ${file_str}.sfc.nc
    ${conda_bin}ncatted -O -a standard_name,CI,o,c,"sea_ice_area_fraction" ${file_str}.sfc.nc
    ${conda_bin}ncatted -O -a units,CI,c,c,"dimensionless" ${file_str}.sfc.nc

    # Process data at pressure level
    ${conda_bin}ncap2 -O -s "ZH=Z/9.81" tmp_pl.nc tmp1_pl.nc
    ${conda_bin}ncap2 -O -s "plev=plev/100" tmp1_pl.nc ${file_str}.pl.nc
    rm tmp*pl.nc
    ${conda_bin}ncatted -O -a standard_name,ZH,o,c,"geopotential_height" ${file_str}.pl.nc
    ${conda_bin}ncatted -O -a units,ZH,c,c,"m" ${file_str}.pl.nc
    ${conda_bin}ncatted -O -a standard_name,plev,o,c,"atmosphere_pressure_coordinate" ${file_str}.pl.nc
    ${conda_bin}ncatted -O -a positive,plev,o,c,"down" ${file_str}.pl.nc
    ${conda_bin}ncatted -O -a units,plev,c,c,"hPa" ${file_str}.pl.nc   
    ${conda_bin}ncatted -O -a standard_name,U,o,c,"eastward_wind" ${file_str}.pl.nc
    ${conda_bin}ncatted -O -a standard_name,V,o,c,"northward_wind" ${file_str}.pl.nc
    ${conda_bin}ncatted -O -a standard_name,Q,o,c,"specific_humidity" ${file_str}.pl.nc
    ${conda_bin}ncatted -O -a standard_name,T,o,c,"air_temperature" ${file_str}.pl.nc
    ${conda_bin}ncatted -O -a standard_name,D,o,c,"divergence_of_wind" ${file_str}.pl.nc

    mv ${file_str}*.nc ${workdir}/ecmwf_prepro/

done

