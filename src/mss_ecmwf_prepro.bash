#!/bin/bash
set -x
workdir=`pwd`

# Setting up datasets that will be used in the preprocessing. Only the last 3 datasets will be processed and are available to MSS
ini_dir=${work_dir}..
ecmwf_inits=(${ini_dir}/ecmwf_input/*)
ecmwf_inits_list=(${ecmwf_inits[-1]} ${ecmwf_inits[-2]}  ${ecmwf_inits[-3]})

# This is needed for clean-up. The whole clean up section can be done in a more sofisticated way
mkdir -p  ${workdir}/../mss_prepro/tmp

for init_dir in ${ecmwf_inits_list[@]}
do

    cd ${workdir}/${init_dir}

    file_str="$(echo $init_dir | cut -d'/' -f3)"
    # Check if preprocessed files allready exit
    if [ -f ${workdir}/../mss_prepro/${file_str}.sfc.nc -a -f ${workdir}/../mss_prepro/${file_str}.ml.nc -a -f ${workdir}/../mss_prepro/${file_str}.ml.nc ]
     then
     	 mv ${workdir}/../mss_prepro/${file_str}*.nc ${workdir}/../mss_prepro/tmp
	 continue
    else
    
    # Convert grib to netcdf
    cdo -P 4 -t ecmwf -f nc copy ${file_str}_sfc.grb ${file_str}.sfc.nc
    cdo -P 4 -t ecmwf -f nc copy ${file_str}_ml.grb tmp_ml.nc
    cdo -P 4 -t ecmwf -f nc copy ${file_str}_pl.grb tmp_pl.nc

    # Process the model level data using a python script
    python ${workdir}/mss_ml_prepro.py tmp_ml.nc ${file_str}.sfc.nc ${file_str}.ml.nc
    rm tmp_ml.nc

    # Process the surface data
    ncatted -O -a standard_name,MSL,o,c,"air_pressure_at_sea_level" ${file_str}.sfc.nc
    ncatted -O -a standard_name,TCC,o,c,"total_cloud_cover" ${file_str}.sfc.nc
    ncatted -O -a units,TCC,c,c,"dimensionless" ${file_str}.sfc.nc
    ncatted -O -a standard_name,LCC,o,c,"low_cloud_area_fraction" ${file_str}.sfc.nc
    ncatted -O -a units,LCC,c,c,"dimensionless" ${file_str}.sfc.nc
    ncatted -O -a standard_name,MCC,o,c,"medium_cloud_area_fraction" ${file_str}.sfc.nc
    ncatted -O -a units,MCC,c,c,"dimensionless" ${file_str}.sfc.nc
    ncatted -O -a standard_name,HCC,o,c,"high_cloud_area_fraction" ${file_str}.sfc.nc
    ncatted -O -a units,HCC,c,c,"dimensionless" ${file_str}.sfc.nc
    ncatted -O -a standard_name,U10M,o,c,"surface_eastward_wind" ${file_str}.sfc.nc
    ncatted -O -a standard_name,V10M,o,c,"surface_northward_wind" ${file_str}.sfc.nc
    ncatted -O -a standard_name,CI,o,c,"sea_ice_area_fraction" ${file_str}.sfc.nc
    ncatted -O -a units,CI,c,c,"dimensionless" ${file_str}.sfc.nc

    # Process data at pressure level
    ncap2 -O -s "ZH=Z/9.81" tmp_pl.nc tmp1_pl.nc
    ncap2 -O -s "plev=plev/100" tmp1_pl.nc ${file_str}.pl.nc
    rm tmp*pl.nc
    ncatted -O -a standard_name,ZH,o,c,"geopotential_height" ${file_str}.pl.nc
    ncatted -O -a units,ZH,c,c,"m" ${file_str}.pl.nc
    ncatted -O -a standard_name,plev,o,c,"atmosphere_pressure_coordinate" ${file_str}.pl.nc
    ncatted -O -a positive,plev,o,c,"down" ${file_str}.pl.nc
    ncatted -O -a units,plev,c,c,"hPa" ${file_str}.pl.nc   
    ncatted -O -a standard_name,U,o,c,"eastward_wind" ${file_str}.pl.nc
    ncatted -O -a standard_name,V,o,c,"northward_wind" ${file_str}.pl.nc
    ncatted -O -a standard_name,Q,o,c,"specific_humidity" ${file_str}.pl.nc
    ncatted -O -a standard_name,T,o,c,"air_temperature" ${file_str}.pl.nc
    ncatted -O -a standard_name,D,o,c,"divergence_of_wind" ${file_str}.pl.nc

    Move preprocessed files into mss_prepro directory
    mv ${file_str}*.nc ${workdir}/../mss_prepro/tmp

    fi
    
done

# Clean-up contiunes
rm ${workdir}/../mss_prepro/ecmwf*.nc
mv  ${workdir}/../mss_prepro/tmp/ecmwf*.nc ${workdir}/../mss_prepro/
rm -r ${workdir}/../mss_prepro/tmp
