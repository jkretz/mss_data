#!/bin/bash

mkdir -p ecmwf_input/
rsync -avhP mistral:/scratch/b/b380425/mss/* ecmwf_input/

ecmwf_inits=(ecmwf_input/*)
ecmwf_inits_list=(${ecmwf_inits[-1]}) # ${ecmwf_inits[-2]} ${ecmwf_inits[-3]})

for init_dir in ${ecmwf_inits_list[@]}
do
    # Convert grib to netcdf
    cdo -t ecmwf -f nc copy $init_dir/test_sfc.grb test_sfc.nc
    cdo -t ecmwf -f nc copy $init_dir/test_ml.grb tmp_ml.nc
    cdo -t ecmwf -f nc copy $init_dir/test_pl.grb tmp_pl.nc

    # Process the model level data using a python script
    /home_local/jkretzs/anaconda3/envs/cdo/bin/python mss_ml_prepro.py tmp_ml.nc test_sfc.nc
    rm tmp_ml.nc

    # Process the surface data
    ncatted -O -a standard_name,MSL,o,c,"air_pressure_at_sea_level" test_sfc.nc
    ncatted -O -a standard_name,TCC,o,c,"total_cloud_cover" test_sfc.nc
    ncatted -O -a units,TCC,c,c,"dimensionless" test_sfc.nc
    ncatted -O -a standard_name,LCC,o,c,"low_cloud_area_fraction" test_sfc.nc
    ncatted -O -a units,LCC,c,c,"dimensionless" test_sfc.nc
    ncatted -O -a standard_name,MCC,o,c,"medium_cloud_area_fraction" test_sfc.nc
    ncatted -O -a units,MCC,c,c,"dimensionless" test_sfc.nc
    ncatted -O -a standard_name,HCC,o,c,"high_cloud_area_fraction" test_sfc.nc
    ncatted -O -a units,HCC,c,c,"dimensionless" test_sfc.nc
    ncatted -O -a standard_name,U10M,o,c,"surface_eastward_wind" test_sfc.nc
    ncatted -O -a standard_name,V10M,o,c,"surface_northward_wind" test_sfc.nc
    ncatted -O -a standard_name,CI,o,c,"sea_ice_area_fraction" test_sfc.nc
    ncatted -O -a units,CI,c,c,"dimensionless" test_sfc.nc

    # Process data at pressure level
    ncap -O -s "ZH=Z/9.81" tmp_pl.nc tmp1_pl.nc
    ncap -O -s "plev=plev/100" tmp1_pl.nc test_pl.nc
    rm tmp*pl.nc
    ncatted -O -a standard_name,ZH,o,c,"geopotential_height" test_pl.nc
    ncatted -O -a units,ZH,c,c,"m" test_pl.nc
    ncatted -O -a standard_name,plev,o,c,"atmosphere_pressure_coordinate" test_pl.nc
    ncatted -O -a positive,plev,o,c,"down" test_pl.nc
    ncatted -O -a units,plev,c,c,"hPa" test_pl.nc   
    ncatted -O -a standard_name,U,o,c,"eastward_wind" test_pl.nc
    ncatted -O -a standard_name,V,o,c,"northward_wind" test_pl.nc
    ncatted -O -a standard_name,Q,o,c,"specific_humidity" test_pl.nc
    ncatted -O -a standard_name,T,o,c,"air_temperature" test_pl.nc
    ncatted -O -a standard_name,D,o,c,"divergence_of_wind" test_pl.nc
    
done

