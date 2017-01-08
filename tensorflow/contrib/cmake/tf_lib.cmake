# Create a tensorflow library, and set up rule for install the library and necessary headers for C++

########################################################
# RELATIVE_PROTOBUF_GENERATE_CPP function
########################################################
# A variant of PROTOBUF_GENERATE_CPP that keeps the directory hierarchy.
# ROOT_DIR must be absolute, and proto paths must be relative to ROOT_DIR.
function(RELATIVE_PROTOBUF_GENERATE_CPP SRCS HDRS ROOT_DIR)
  if(NOT ARGN)
    message(SEND_ERROR "Error: RELATIVE_PROTOBUF_GENERATE_CPP() called without any proto files")
    return()
  endif()
  
  set(${SRCS})
  set(${HDRS})
  foreach(FIL ${ARGN})
    set(ABS_FIL ${ROOT_DIR}/${FIL})
    get_filename_component(FIL_WE ${FIL} NAME_WE)
    get_filename_component(FIL_DIR ${ABS_FIL} PATH)
    file(RELATIVE_PATH REL_DIR ${ROOT_DIR} ${FIL_DIR})

    list(APPEND ${SRCS} "${CMAKE_CURRENT_BINARY_DIR}/${REL_DIR}/${FIL_WE}.pb.cc")
    list(APPEND ${HDRS} "${CMAKE_CURRENT_BINARY_DIR}/${REL_DIR}/${FIL_WE}.pb.h")

    add_custom_command(
      OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${REL_DIR}/${FIL_WE}.pb.cc"
             "${CMAKE_CURRENT_BINARY_DIR}/${REL_DIR}/${FIL_WE}.pb.h"
      COMMAND  ${PROTOBUF_PROTOC_EXECUTABLE}
      ARGS --cpp_out  ${CMAKE_CURRENT_BINARY_DIR} -I ${ROOT_DIR} ${ABS_FIL} -I ${PROTOBUF_INCLUDE_DIRS}
      DEPENDS ${ABS_FIL} protobuf
      COMMENT "Running C++ protocol buffer compiler on ${FIL}"
      VERBATIM )
  endforeach()

  set_source_files_properties(${${SRCS}} ${${HDRS}} PROPERTIES GENERATED TRUE)
  set(${SRCS} ${${SRCS}} PARENT_SCOPE)
  set(${HDRS} ${${HDRS}} PARENT_SCOPE)
endfunction()

function(RELATIVE_PROTOBUF_TEXT_GENERATE_CPP SRCS HDRS ROOT_DIR)
  if(NOT ARGN)
      message(SEND_ERROR "Error: RELATIVE_PROTOBUF_TEXT_GENERATE_CPP() called without any proto files")
    return()
  endif()

  set(${SRCS})
  set(${HDRS})
  foreach(FIL ${ARGN})
    set(ABS_FIL ${ROOT_DIR}/${FIL})
    get_filename_component(FIL_WE ${FIL} NAME_WE)
    get_filename_component(FIL_DIR ${ABS_FIL} PATH)
    file(RELATIVE_PATH REL_DIR ${ROOT_DIR} ${FIL_DIR})

    list(APPEND ${SRCS} "${CMAKE_CURRENT_BINARY_DIR}/${REL_DIR}/${FIL_WE}.pb_text.cc")
    list(APPEND ${HDRS} "${CMAKE_CURRENT_BINARY_DIR}/${REL_DIR}/${FIL_WE}.pb_text.h")

    add_custom_command(
      OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${REL_DIR}/${FIL_WE}.pb_text.cc"
             "${CMAKE_CURRENT_BINARY_DIR}/${REL_DIR}/${FIL_WE}.pb_text.h"
      COMMAND ${PROTO_TEXT_EXE}
      ARGS "${CMAKE_CURRENT_BINARY_DIR}/${REL_DIR}" ${REL_DIR} ${ABS_FIL} "${ROOT_DIR}/tensorflow/tools/proto_text/placeholder.txt"
      DEPENDS ${ABS_FIL} ${PROTO_TEXT_EXE}
      COMMENT "Running C++ protocol buffer text compiler (${PROTO_TEXT_EXE}) on ${FIL}"
      VERBATIM )
  endforeach()

  set_source_files_properties(${${SRCS}} ${${HDRS}} PROPERTIES GENERATED TRUE)
  set(${SRCS} ${${SRCS}} PARENT_SCOPE)
  set(${HDRS} ${${HDRS}} PARENT_SCOPE)
endfunction()

########################################################
# tf_protos_cc library
########################################################

file(GLOB_RECURSE tf_protos_cc_srcs RELATIVE ${tensorflow_source_dir}
    "${tensorflow_source_dir}/tensorflow/core/*.proto"
)
RELATIVE_PROTOBUF_GENERATE_CPP(PROTO_SRCS PROTO_HDRS
    ${tensorflow_source_dir} ${tf_protos_cc_srcs}
)


if(WIN32)
    # Build static library on windows
    # Unable to create DLL on windows with MSVC
    set(BUILD_SHARED_LIBS OFF)
    # Build with multiple processes on windows
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /MP")
endif()

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
    ${PROTO_HDRS}
    ${PROTO_SRCS}
)

# Install files
# 1) Library
install(
    TARGETS
    tensorflow
    DESTINATION lib
)

# 2) TF headers
install(
    DIRECTORY 
    ${tensorflow_source_dir}/tensorflow/ # Regular headers
    ${tensorflow_source_dir}/tensorflow/contrib/cmake/tensorflow/ # Protobuf generated headers
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

# 4) Eigen Headers
install(
    DIRECTORY 
    ${tensorflow_source_dir}/tensorflow/contrib/cmake/eigen/src/eigen/Eigen/
    DESTINATION include/Eigen
)
install(
    DIRECTORY 
    ${tensorflow_source_dir}/tensorflow/contrib/cmake/eigen/src/eigen/unsupported/
    DESTINATION include/unsupported
)

# 5) External libraries
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

# Write a cmake config file, listing all libraries
set(CONF_INCLUDE_DIRS "${CMAKE_INSTALL_PREFIX}/include/")
file(GLOB CONF_LIBRARY "${CMAKE_INSTALL_PREFIX}/lib/tensorflow.lib")
file(GLOB CONF_LIBRARIES "${CMAKE_INSTALL_PREFIX}/lib/*")
configure_file(TensorflowConfig.cmake.in "${PROJECT_BINARY_DIR}/TensorflowConfig.cmake" @ONLY)
install(
	FILES
	"${PROJECT_BINARY_DIR}/TensorflowConfig.cmake"
	DESTINATION cmake
)
