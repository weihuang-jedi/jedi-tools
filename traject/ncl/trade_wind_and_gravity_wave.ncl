;-------------------------------------------------------------------------------
 pi = 4.0*atan(1.0)
 deg2rad = pi/180.0

;declin_winter = -23.5
;declin_spring = 0.0
;declin_summer = 23.5

;The Earth's radiius is 6371 km (3,959 mi)

 earth_radiius = 6371.0*1000.0
 sun_travel_dist_per_day = 2.0*pi*earth_radiius
 seconds_per_day = 24.0*3600.0

 gravity_wave_speed = sun_travel_dist_per_day / seconds_per_day

 print(gravity_wave_speed)

;Gas Constant of Dry Air	Rd	287 J K-1 kg-2
 r_gas = 287.0

 diurnal_temperature_in_degree = 10.0

 trade_wind_speed = r_gas * diurnal_temperature_in_degree / gravity_wave_speed

 print(trade_wind_speed)

;In dry air at 20 °C, the speed of sound is 343.2 metres per second.

; gravity_wave_speed
;     463.3122

; trade_wind_speed
;     6.194527

