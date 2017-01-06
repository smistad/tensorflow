# Create a tensorflow library, and set up rule for install the library and necessary headers for C++

add_library(tensorflow SHARED
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
    $<TARGET_OBJECTS:tf_core_kernels>
    $<$<BOOL:${tensorflow_ENABLE_GPU}>:$<TARGET_OBJECTS:tf_stream_executor>>
)
target_link_libraries(tensorflow
    ${tf_core_gpu_kernels_lib}
    ${tensorflow_EXTERNAL_LIBRARIES}
    tf_protos_cc
)

# Install files
# 1) Library
install(
    TARGETS
    tensorflow
    DESTINATION
    lib
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
