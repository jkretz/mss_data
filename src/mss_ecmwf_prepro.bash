#!/bin/bash

prepro_sfc () {

    # "_ml_" has to be replaced with "_sfc_" as we call this function from ml
    ifile=$1
    ofile=$2
    
    if [[ -e ../$ofile ]]; then
	mv ../$ofile .
    else
	# Set grib edition number
	grib_set -s editionNumber=1 ${ifile} tmp.grb

	# Grib to netcdf
	cdo -P 4 -t ecmwf -f nc copy tmp.grb $ofile

	# Set standard_names and units
	ncatted -O -a standard_name,MSL,o,c,"air_pressure_at_sea_level" ${ofile}
	ncatted -O -a standard_name,TCC,o,c,"total_cloud_cover" ${ofile}
	ncatted -O -a units,TCC,c,c,"dimensionless" ${ofile}
	ncatted -O -a standard_name,LCC,o,c,"low_cloud_area_fraction" ${ofile}
	ncatted -O -a units,LCC,c,c,"dimensionless" ${ofile}
	ncatted -O -a standard_name,MCC,o,c,"medium_cloud_area_fraction" ${ofile}
	ncatted -O -a units,MCC,c,c,"dimensionless" ${ofile}
	ncatted -O -a standard_name,HCC,o,c,"high_cloud_area_fraction" ${ofile}
	ncatted -O -a units,HCC,c,c,"dimensionless" ${ofile}
	ncatted -O -a standard_name,U10M,o,c,"surface_eastward_wind" ${ofile}
	ncatted -O -a standard_name,V10M,o,c,"surface_northward_wind" ${ofile}
	ncatted -O -a standard_name,CI,o,c,"sea_ice_area_fraction" ${ofile}
	ncatted -O -a standard_name,TCWV,o,c,"ecmwf_iwv" ${ofile}
	ncatted -O -a standard_name,var71,o,c,"ecmwf_viwve" ${ofile}
	ncatted -O -a standard_name,var72,o,c,"ecmwf_viwvn" ${ofile}
	ncatted -O -a units,var71,c,c,"kg m**-1 s**-1" ${ofile}
	ncatted -O -a units,var72,c,c,"kg m**-1 s**-1" ${ofile}
	ncatted -O -a units,CI,c,c,"dimensionless" ${ofile}

	# Clean up
	rm tmp.grb

    fi  
}

prepro_pl () {
    ifile=$1
    ofile=$2

    if [[ -e ../$ofile ]]; then
	mv ../$ofile .
    else
	
	# Grib to netcdf
	cdo -P 4 -t ecmwf -f nc copy ${ifile} tmp_pl.nc

	# Process data at pressure level
	ncap2 -O -s "ZH=Z/9.81" tmp_pl.nc tmp1_pl.nc
	ncap2 -O -s "plev=plev/100" tmp1_pl.nc ${ofile}

	# Set standard_names and units
	ncatted -O -a standard_name,ZH,o,c,"geopotential_height" ${ofile}
	ncatted -O -a units,ZH,c,c,"m" ${ofile}
	ncatted -O -a standard_name,plev,o,c,"atmosphere_pressure_coordinate" ${ofile}
	ncatted -O -a positive,plev,o,c,"down" ${ofile}
	ncatted -O -a units,plev,c,c,"hPa" ${ofile}   
	ncatted -O -a standard_name,U,o,c,"eastward_wind" ${ofile}
	ncatted -O -a standard_name,V,o,c,"northward_wind" ${ofile}
	ncatted -O -a standard_name,Q,o,c,"specific_humidity" ${ofile}
	ncatted -O -a standard_name,T,o,c,"air_temperature" ${ofile}
	ncatted -O -a standard_name,D,o,c,"divergence_of_wind" ${ofile}

	# Clean up
	rm tmp*pl.nc

    fi
}

prepro_ml () {
    ifile=$1
    ifile_sfc=$(echo "${2/3_ml/1_sfc}")
    ofile=$2

    if [[ -e ../$ofile ]]; then
	mv ../$ofile .
    else
	#Grib to netcdf
	cdo -P 4 -t ecmwf -f nc copy ${ifile} tmp_ml.nc
	
	# Process the model level data using a python script
	python ${workdir}/src/mss_ml_prepro.py tmp_ml.nc ${ifile_sfc} ${ofile}
	rm tmp_ml.nc

    fi
}


#set -x

workdir=/home/mss/mss_data

# Setting up datasets that will be used in the preprocessing. Only the last 3 datasets will be processed and are available to MSS
ecmwf_inits=(${workdir}/ecmwf_input/*)
ecmwf_inits_list=(${ecmwf_inits[-1]} ${ecmwf_inits[-2]}  ${ecmwf_inits[-3]})

# Directory for output
outdir=${workdir}/mss_prepro


# Directory for tmp data
mkdir -p ${outdir}/tmp
cd ${outdir}/tmp

for init_dir in ${ecmwf_inits_list[@]}
do
    for level_type in "_sfc." "_ml." "_pl."
    do

	for file in ${init_dir}/*$level_type*
	do
	    if [[ -e $file ]] ; then
		
		ofile_nc="$(echo ${file##*/} | cut -d'.' -f1).nc"
		
		# Pressure level
		if [[ ${level_type} == "_pl." ]]; then
		    prepro_pl ${file} ${ofile_nc}
		# Model level and surface
		elif [[ ${level_type} == "_ml." ]]; then
		    prepro_ml ${file} ${ofile_nc}
		# Model level and surface
		elif [[ ${level_type} == "_sfc." ]]; then
		    prepro_sfc ${file} ${ofile_nc}
		fi

	    fi
	done
    done
done

# Remove old files
for oldfile in ${outdir}/ecmwf*.nc
do
    if [[ -e $oldfile ]]; then
	rm ${oldfile}
    fi
done

# Move last 3 timesteps back into main directory
mv ${outdir}/tmp/ecmwf*.nc ${workdir}/mss_prepro

# Clean-up
rm -r ${outdir}/tmp
