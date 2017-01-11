# Create a tensorflow library, and set up rule for install the library and necessary headers for C++
if(WIN32)
    file(GLOB_RECURSE tf_protos_cc_srcs RELATIVE ${tensorflow_source_dir}
        "${tensorflow_source_dir}/tensorflow/core/*.proto"
    )
    RELATIVE_PROTOBUF_GENERATE_CPP(PROTO_SRCS PROTO_HDRS
        ${tensorflow_source_dir} ${tf_protos_cc_srcs}
    )
    # Build static library on windows
    # Unable to create DLL on windows with MSVC
    set(BUILD_SHARED_LIBS OFF)
    # Build with multiple processes on windows
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /MP")
else(WIN32)
    # Build shared lib on other systems than windows
    set(BUILD_SHARED_LIBS ON)
endif(WIN32)

add_library(tensorflow
    "${tensorflow_source_dir}/tensorflow/c/c_api.cc"
    "${tensorflow_source_dir}/tensorflow/c/c_api.h"
    "${tensorflow_source_dir}/tensorflow/c/checkpoint_reader.cc"
    "${tensorflow_source_dir}/tensorflow/c/checkpoint_reader.h"
    "${tensorflow_source_dir}/tensorflow/c/tf_status_helper.cc"
    "${tensorflow_source_dir}/tensorflow/c/tf_status_helper.h"
    $<TARGET_OBJECTS:tf_core_lib>
    $<TARGET_OBJECTS:tf_core_cpu>
    $<TARGET_OBJECTS:tf_core_framework>
    $<TARGET_OBJECTS:tf_core_ops>
    $<TARGET_OBJECTS:tf_core_direct_session>
    $<$<BOOL:${tensorflow_ENABLE_GRPC_SUPPORT}>:$<TARGET_OBJECTS:tf_core_distributed_runtime>>
    $<TARGET_OBJECTS:tf_core_kernels>
    $<$<BOOL:${tensorflow_ENABLE_GPU}>:$<TARGET_OBJECTS:tf_stream_executor>>
    $<$<BOOL:WIN32>:${PROTO_HDRS}>
    $<$<BOOL:WIN32>:${PROTO_SRCS}>
)

# Install files
# 1) Library
install(
    TARGETS
    tensorflow
    DESTINATION lib
)

if(NOT WIN32)
    # For platforms other than windows, we link any dependencies
    target_link_libraries(tensorflow
        ${tf_core_gpu_kernels_lib}
        ${tensorflow_EXTERNAL_LIBRARIES}
        tf_protos_cc
    )
    add_dependencies(tensorflow
        ${tensorflow_EXTERNAL_DEPENDENCIES}
        tf_protos_cc
    )
endif(NOT WIN32)

# 2) TF headers
install(
    DIRECTORY 
    ${tensorflow_source_dir}/tensorflow/ # Regular headers
    ${CMAKE_CURRENT_BINARY_DIR}/tensorflow/ # Protobuf generated headers
    DESTINATION include/tensorflow
    FILES_MATCHING PATTERN "*.h"
)

# 3) Third party headers
install(
    DIRECTORY 
    ${tensorflow_source_dir}/third_party/
    DESTINATION include/third_party/
    PATTERN "*BUILD" EXCLUDE
)

# 4) External libraries
if(WIN32)
    # For windows, since we are building a static lib,
    # we also need the static dependencies
    install(
        FILES
        ${zlib_STATIC_LIBRARIES}
        ${gif_STATIC_LIBRARIES}
        ${png_STATIC_LIBRARIES}
        ${jpeg_STATIC_LIBRARIES}
        ${jsoncpp_STATIC_LIBRARIES}
        ${farmhash_STATIC_LIBRARIES}
        ${highwayhash_STATIC_LIBRARIES}
        ${protobuf_STATIC_LIBRARIES}
        DESTINATION lib
    )
endif(WIN32)

# 5) Write a cmake config file, listing all libraries and include dirs
install(CODE "
    set(CONF_INCLUDE_DIRS \"${CMAKE_INSTALL_PREFIX}/include/\")
    file(GLOB CONF_LIBRARY \"${CMAKE_INSTALL_PREFIX}/lib/*tensorflow.*\")
    file(GLOB CONF_LIBRARIES \"${CMAKE_INSTALL_PREFIX}/lib/*\")
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/TensorflowConfig.cmake.in \"${PROJECT_BINARY_DIR}/TensorflowConfig.cmake\" @ONLY)
    "
)

install(
    FILES
    "${PROJECT_BINARY_DIR}/TensorflowConfig.cmake"
    DESTINATION cmake
)
