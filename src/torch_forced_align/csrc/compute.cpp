#include <torch/script.h>

TORCH_LIBRARY_FRAGMENT(torch_forced_align, m) {
  m.def(
      "forced_align(Tensor log_probs, Tensor targets, Tensor input_lengths, Tensor target_lengths, int blank) -> (Tensor, Tensor)");
}
