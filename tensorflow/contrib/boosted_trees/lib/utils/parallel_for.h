// Copyright 2017 The TensorFlow Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// =============================================================================
#ifndef TENSORFLOW_CONTRIB_BOOSTED_TREES_LIB_UTILS_PARALLEL_FOR_H_
#define TENSORFLOW_CONTRIB_BOOSTED_TREES_LIB_UTILS_PARALLEL_FOR_H_

#include "tensorflow/core/lib/core/threadpool.h"

namespace tensorflow {
namespace boosted_trees {
namespace utils {

// Executes a parallel for over the batch for the desired parallelism level.
void ParallelFor(int64 batch_size, int64 desired_parallelism,
                 thread::ThreadPool* thread_pool,
                 std::function<void(int64, int64)> do_work);

}  // namespace utils
}  // namespace boosted_trees
}  // namespace tensorflow

#endif  // TENSORFLOW_CONTRIB_BOOSTED_TREES_LIB_UTILS_PARALLEL_FOR_H_
