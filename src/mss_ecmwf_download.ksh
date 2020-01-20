#!/bin/ksh
#SBATCH --chdir=/scratch/ms/datex/gdr/mss

eval `ssh-agent -s`
ssh-add /home/ms/datex/gdr/.ssh/id_rsa_mss

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


latlon_area='40/-80/-10/-20'
grid='160'
step='0/3/6/9/12/15/18/21/24/27/30/33/36/39/42/45/48/51/54/57/60/63/66/69/72'

cd /scratch/ms/datex/gdr/mss

mkdir -p ${retrieve_str}
cd ${retrieve_str}

if [ -f mars_sfc ]; then
    rm mars_sfc
fi
cat <<EOF > mars_sfc
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
        step     = ${step},
        target   = ${retrieve_str}_sfc.grb,
        param    = msl/lcc/mcc/hcc/10u/10v/ci/tcc/sp,
        repres   = sh,
     	area     = ${latlon_area},
	resol    = 1279,
        grid     = ${grid},
        gaussian = regular,
        levtype  = sfc
EOF
mars mars_sfc &

if [ -f mars_pl ]; then
    rm mars_pl
fi
cat <<EOF > mars_pl
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
        step     = ${step},
        target   = ${retrieve_str}_pl.grb,
        param    = u/v/d/t/z/q,
        repres   = sh,                                  # spherical harmonics,
       	area     = ${latlon_area},
  	resol    = 1279,
        grid     = ${grid},
        gaussian = regular,
        levtype  = pl,                                  # model levels,
        levelist = 925/850/700/500/400/300/250/200/150/100
EOF
mars mars_pl &

if [ -f mars_ml ]; then
    rm mars_ml
fi

# for var in t cc
# do
# cat <<EOF  > mars_ml_${var}
# retrieve,
# 	padding  = 0,
# 	accuracy = 16,
# 	class    = od, 
#   	expver   = 1, 
#   	stream   = oper,
#         domain   = g,
#         type     = fc,
#         date     = ${date},
#         time     = ${init_time},
#         step     = ${step},
#         target   = tmp_${retrieve_str}_${var}_ml.grb,
#         param    = ${var},
#         repres   = sh,                                  # spherical harmonics,
#        	area     = ${latlon_area},
#   	resol    = 1279,
#         grid     = ${grid},
#         gaussian = regular,
#         levtype  = ml,                                  # model levels,
#         levelist = 60/to/137  
# EOF
# mars mars_ml_${var} &
# done

cat <<EOF  > mars_ml
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
        step     = ${step},
        target   = ${retrieve_str}_ml.grb,
        param    = t/cc,
        repres   = sh,                                  # spherical harmonics,
       	area     = ${latlon_area},
  	resol    = 1279,
        grid     = ${grid},
        gaussian = regular,
        levtype  = ml,                                  # model levels,
        levelist = 60/to/137  
EOF
mars mars_ml

wait


# Clean up
rm mars_sfc mars_pl mars_ml
cd ..				
rsync -avhP ${retrieve_str} mss@139.18.173.186:/home/mss/mssdata/ecmwf_input

