#!/bin/bash

mkdir -p ecmwf_input/
mkdir -p ecmwf_prepro/
rsync -avhP mistral:/scratch/b/b380425/mss/* ecmwf_input/

ecmwf_inits=(ecmwf_input/*)
ecmwf_inits_list=(${ecmwf_inits[-1]}) # ${ecmwf_inits[-2]} ${ecmwf_inits[-3]})
cdo_anaconda=/home_local/jkretzs/anaconda3/envs/cdo/bin/cdo

for init_dir in ${ecmwf_inits_list[@]}
do
    cd $init_dir
    file_str="${init_dir#*/}"
    
    # Convert grib to netcdf
    $cdo_anaconda -t ecmwf -f nc copy ${file_str}_sfc.grb ${file_str}.sfc.nc
    $cdo_anaconda -t ecmwf -f nc copy ${file_str}_ml.grb tmp_ml.nc
    $cdo_anaconda -t ecmwf -f nc copy ${file_str}_pl.grb tmp_pl.nc

    # Process the model level data using a python script
    /home_local/jkretzs/anaconda3/envs/cdo/bin/python ../../mss_ml_prepro.py tmp_ml.nc ${file_str}.sfc.nc ${file_str}.ml.nc
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
    ncap -O -s "ZH=Z/9.81" tmp_pl.nc tmp1_pl.nc
    ncap -O -s "plev=plev/100" tmp1_pl.nc ${file_str}.pl.nc
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

    mv ${file_str}*.nc ../../ecmwf_prepro/
    cd ..
done

