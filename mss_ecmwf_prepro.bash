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
    cdo -t ecmwf -f nc copy $init_dir/test_pl.grb test_pl.nc

    # Process the model level data using a python script
    /home_local/jkretzs/anaconda3/envs/cdo/bin/python mss_ml_prepro.py 'tmp_ml.nc' 'test_sfc.nc'

    # Process the surface data
    
    
done

