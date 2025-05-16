# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "Debug")
  file(REMOVE_RECURSE
  "CMakeFiles\\appNeuroDrive_13_5_2025_autogen.dir\\AutogenUsed.txt"
  "CMakeFiles\\appNeuroDrive_13_5_2025_autogen.dir\\ParseCache.txt"
  "appNeuroDrive_13_5_2025_autogen"
  )
endif()
