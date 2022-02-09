#!/bin/bash
#SBATCH --chdir=/scratch/ms/datex/gdr/mss/mss_data/ecmwf_input

sbatch_command=/usr/local/apps/slurm/18.08.6/bin/sbatch

#set -x

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
retrieve_str='ecmwf_'${date}'_'${init_time}

# Area to be retrieved
latlon_area='90/-90/45/90'
latlon_area_lagranto='90/-180/45/180'
# Grid to which should be interpolated
grid='320'
# Number of days. Last timestep to be retrieved is (nday*24)+23
nday=3
# Frequency of timestep
freq=2

ecmwf_input=/scratch/ms/datex/gdr/mss/mss_data/ecmwf_input

mkdir -p ${ecmwf_input}/${retrieve_str}
rm -r ${ecmwf_input}/tmp
mkdir -p ${ecmwf_input}/tmp

 
cd ${ecmwf_input}/tmp

for day in $(seq 0 ${nday})  
do
    let start=24*${day}
    if [[ $day < 3 ]]; then
	let end=${start}+23
    else
	end=90
    fi

    cat <<EOF > mars_sfc_${day}
retrieve,
        padding  = 0,
        accuracy = 16,
        class    = od, 
        expver   = 1,
        stream   = oper,
        domain   = g,
        type     = fc,
        date     = ${date},
        time     = ${init_time},
        step     = ${start}/to/${end}/by/${freq},
        target   = ${retrieve_str}_${day}_1_sfc.grb,
        param    = msl/lcc/mcc/hcc/10u/10v/ci/tcc/sp/2t/tcwv/162071/162072/sf/tp/skt/3059/260048/3064/172144/260010,
        repres   = sh,
        area     = ${latlon_area},
        resol    = 1279,
        grid     = ${grid},
        gaussian = regular,
        levtype  = sfc
EOF

    cat <<EOF > mars_sfc_${day}.bash
#!/bin/bash

mars mars_sfc_${day}
wait
mv ${retrieve_str}_${day}_1_sfc.grb ${ecmwf_input}/${retrieve_str}
EOF

    chmod 755 mars_sfc_${day}.bash
    ${sbatch_command} --job-name=mars_sfc --time=00:45:00 ./mars_sfc_${day}.bash

    cat <<EOF > mars_pl_${day}
retrieve,
	padding  = 0,
	accuracy = 16,
	class    = od, 
  	expver   = 1, 
  	stream   = oper,
        domain   = g,
        type     = fc,
        date     = ${date},
        time     = ${init_time},
        step     = ${start}/to/${end}/by/${freq},
        target   = ${retrieve_str}_${day}_2_pl.grb,
        param    = u/v/d/t/z/q,
        repres   = sh,                                  # spherical harmonics,
       	area     = ${latlon_area},
  	resol    = 1279,
        grid     = ${grid},
        gaussian = regular,
        levtype  = pl,                                  # model levels,
        levelist = 925/850/700/500/400/300/250/200/150/100
EOF

    cat <<EOF > mars_pl_${day}.bash
#!/bin/bash

mars mars_pl_${day}
wait
mv ${retrieve_str}_${day}_2_pl.grb ${ecmwf_input}/${retrieve_str}
EOF

    chmod 755 mars_pl_${day}.bash
    ${sbatch_command} --job-name=mars_pl --time=01:00:00 ./mars_pl_${day}.bash

    cat <<EOF > mars_ml_${day}
retrieve,
	padding  = 0,
	accuracy = 16,
	class    = od, 
  	expver   = 1, 
  	stream   = oper,
        domain   = g,
        type     = fc,
        date     = ${date},
        time     = ${init_time},
        step     = ${start}/to/${end}/by/${freq},
        target   = ${retrieve_str}_${day}_3_ml.grb,
        param    = t/cc/q,
        repres   = sh,                                  # spherical harmonics,
       	area     = ${latlon_area},
  	resol    = 1279,
        grid     = ${grid},
        gaussian = regular,
        levtype  = ml,                                  # model levels,
        levelist = 60/to/137  
EOF

    cat <<EOF > mars_ml_${day}.bash
#!/bin/bash

mars mars_ml_${day}
wait
mv ${retrieve_str}_${day}_3_ml.grb ${ecmwf_input}/${retrieve_str}
EOF

    chmod 755 mars_ml_${day}.bash
    ${sbatch_command} --job-name=mars_ml --time=01:30:00 ./mars_ml_${day}.bash

done


for day in $(seq 0 ${nday})
do
    let start=24*${day}
    if [[ $day < 3 ]]; then
        let end=${start}+23
    else
        end=90
    fi



cat <<EOF  > mars_lagranto_${day}
retrieve,
        padding  = 0,
        accuracy = 16,
        class    = od,
        expver   = 1,
        stream   = oper,
        domain   = g,
        type     = fc,
        date     = ${date},
        time     = ${init_time},
	step     = ${start}/to/${end}/by/1,	
        target   = ${retrieve_str}_${day}_4_lagaranto.grb,
        param    = u/v/w,
        repres   = sh,                                  # spherical harmonics,
        area     = ${latlon_area_lagranto},
        resol    = 1279,
        grid     = ${grid},
        gaussian = regular,
        levtype  = ml,                                  # model levels,
        levelist = 60/to/137
EOF

cat <<EOF > mars_lagranto_${day}.bash
#!/bin/bash

mars mars_lagranto_${day}
wait
mv ${retrieve_str}_${day}_4_lagaranto.grb ${ecmwf_input}/${retrieve_str}
EOF

chmod 755 mars_lagranto_${day}.bash

${sbatch_command} --job-name=mars_lagranto --time=01:30:00 ./mars_lagranto_${day}.bash


    cat <<EOF > mars_sfclagranto_${day}
retrieve,
        padding  = 0,
        accuracy = 16,
        class    = od, 
        expver   = 1,
        stream   = oper,
        domain   = g,
        type     = fc,
        date     = ${date},
        time     = ${init_time},
        step     = ${start}/to/${end}/by/1,
        target   = ${retrieve_str}_${day}_1_sfclagranto.grb,
        param    = msl/lcc/mcc/hcc/10u/10v/ci/tcc/sp/2t/tcwv/162071/162072/sf/tp/skt,
        repres   = sh,
        area     = ${latlon_area_lagranto},
        resol    = 1279,
        grid     = ${grid},
        gaussian = regular,
        levtype  = sfc
EOF

    cat <<EOF > mars_sfclagranto_${day}.bash
#!/bin/bash

mars mars_sfclagranto_${day}
wait
mv ${retrieve_str}_${day}_1_sfclagranto.grb ${ecmwf_input}/${retrieve_str}
EOF

    chmod 755 mars_sfclagranto_${day}.bash
    ${sbatch_command} --job-name=mars_sfclagranto --time=00:45:00 ./mars_sfclagranto_${day}.bash



done
