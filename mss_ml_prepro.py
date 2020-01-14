# coding=utf-8
from netCDF4 import Dataset
import numpy as np
import sys


def create_dimension_entry(file, name, dimsize):
    file.createDimension(name, dimsize)


def create_variable_entry(file, name, dimension, values, **kwargs):
    var_write = file.createVariable(name, 'd', dimension)
    var_write[:] = values
    for key, key_value in kwargs.items():
        if key == 'units':
            var_write.units = key_value
        if key == 'standard_name':
            var_write.standard_name = key_value
        if key == 'positive':
            var_write.positive = key_value


ifile_ml, ifile_sfc = str(sys.argv[1]), str(sys.argv[2])
f_ml, f_sfc = Dataset(ifile_ml, 'r'), Dataset(ifile_sfc, 'r')

p_sfc = f_sfc.variables['SP'][:]
hyam, hybm = f_ml.variables['hyam'][:], f_ml.variables['hybm'][:]
time_ml, lat_ml, lon_ml = f_ml.variables['time'], f_ml.variables['lat'], f_ml.variables['lon']

dim_t, dim_lat, dim_lon = len(time_ml[:]),  len(lat_ml[:]),  len(lon_ml[:])
dim_vert = len(hyam)

p_ml = np.zeros((dim_t, dim_vert, dim_lat, dim_lon))

for ts in np.arange(dim_t):
    for nl in np.arange(dim_vert):
        p_ml[ts, nl, :, :] = hyam[nl] + p_sfc[ts, :, :] * hybm[nl]

ofile = 'test_ml.nc'
f_out = Dataset(ofile, 'w', format='NETCDF4_CLASSIC')

# create dimension
create_dimension_entry(f_out, 'time', dim_t)
create_dimension_entry(f_out, 'lev', dim_vert)
create_dimension_entry(f_out, 'lat', dim_lat)
create_dimension_entry(f_out, 'lon', dim_lon)

# create entries for dimension
create_variable_entry(f_out, 'time', 'time', time_ml[:], units=time_ml.units, standard_name=time_ml.standard_name)
create_variable_entry(f_out, 'lev', 'lev', np.arange(dim_vert)+1, units='sigma',
                      standard_name="atmosphere_hybrid_sigma_pressure_coordinate", positive="down")
create_variable_entry(f_out, 'lat', 'lat', lat_ml[:], units=lat_ml.units, standard_name=lat_ml.standard_name)
create_variable_entry(f_out, 'lon', 'lon', lon_ml[:], units=lon_ml.units, standard_name=lon_ml.standard_name)

# create entries for variables
create_variable_entry(f_out, 'air_pressure', ('time', 'lev', 'lat', 'lon'), p_ml,
                      units='Pa', standard_name='air_pressure')
t = f_ml.variables['t'][:]
create_variable_entry(f_out, 'air_temperature', ('time', 'lev', 'lat', 'lon'), t, units='K', standard_name='air_temperature')
cc = f_ml.variables['cc'][:]
create_variable_entry(f_out, 'cc', ('time', 'lev', 'lat', 'lon'), cc, units='dimensionless', standard_name='cloud_area_fraction_in_atmosphere_layer')

exit()
