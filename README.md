# Downloading and processing ECMWF and ICON for MSS

This repository contains a set of scripts that are able to download and preprocess data than can be used for MSS. While the ICON forecast used in this script is freely available (https://opendata.dwd.de/), you need to have acesss to the ECMWF server get data from their operationel forecast.

## Preparations
The scirpts used here are mainly using command line operations from cdo and nco. Additionally, a small python helper script is used for calculating pressure on model levels that additonally does the renaming of the model level data. In the future, the nco commads should be replaced by python.

To be able to use these scripts, set up a dedicated conda environment on your MSS server, with the packages for cdo, nco and netCDF installed (requirments document should be provided in the future)

## Download ECMWF data
The scirpt src/mss_ecmwf_download.ksh has to be run on the ECMWF server. It has to be adapted to your user in some places (paths, server name for rsync,...). It can be run autonomously using a cron job.

## Preprocess ECMWF data
On your MSS server, the script mss_prepro_data.bash will do the preprocessing of the raw ECMWF data to be compatible with MSS. In this script, some paths have to be adapted and to path to your anaconda/miniconda directory and the name of your environment you created has to be set. It can be run autonomously using a cron job. The resulting files are written into mss_prepro.

## Downloading and processing ICON data
mss_icon_download.bash does this job. Similar adaption as for mss_icon_download.bash have to be made. It can be run autonomously using a cron job. In the future, this scirpt should also be called from mss_icon_download.bash
