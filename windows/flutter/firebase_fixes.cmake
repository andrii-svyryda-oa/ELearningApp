# This file contains fixes for Firebase C++ SDK compilation issues on Windows

# Fix for encodable_value.h variant constructor error
if(MSVC)
  # Add compiler flags to fix C++ variant issues
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /Zc:__cplusplus")
  
  # Set C++ standard to C++17 which is required for std::variant
  set(CMAKE_CXX_STANDARD 17)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
  
  # Disable some warnings that occur in Firebase code
  add_compile_options(/wd4100 /wd4267 /wd4244 /wd4127)
endif()

# Force Firebase plugins to use C++17
foreach(plugin ${FLUTTER_PLUGIN_LIST})
  if(${plugin} STREQUAL "firebase_core" OR 
     ${plugin} STREQUAL "firebase_auth" OR 
     ${plugin} STREQUAL "cloud_firestore" OR 
     ${plugin} STREQUAL "firebase_storage")
    set_target_properties(${plugin}_plugin PROPERTIES
      CXX_STANDARD 17
      CXX_STANDARD_REQUIRED ON
    )
  endif()
endforeach(plugin)
