import pytest
import torch

from torch_forced_align.forced_align import forced_align


@pytest.fixture
def simple_emission():
    """Create a simple emission where alignment is deterministic.

    3 classes: blank=0, 'a'=1, 'b'=2
    Time steps: 5, target: [1, 2] ('a', 'b')
    Emission strongly favors: blank, 'a', blank, 'b', blank
    """
    T, C = 5, 3
    log_probs = torch.full((1, T, C), fill_value=-10.0)
    # t=0: blank
    log_probs[0, 0, 0] = -0.1
    # t=1: 'a'
    log_probs[0, 1, 1] = -0.1
    # t=2: blank
    log_probs[0, 2, 0] = -0.1
    # t=3: 'b'
    log_probs[0, 3, 2] = -0.1
    # t=4: blank
    log_probs[0, 4, 0] = -0.1

    targets = torch.tensor([[1, 2]])
    return log_probs, targets


def test_forced_align(simple_emission):
    log_probs, targets = simple_emission
    paths, scores = forced_align(log_probs, targets)

    assert paths.shape == (1, 5)
    assert scores.shape == (1, 5)

    assert torch.all(torch.isfinite(scores))
    assert torch.all(scores <= 0)  # log-probabilities are non-positive

    expected_path = torch.tensor([[0, 1, 0, 2, 0]])
    assert torch.equal(paths, expected_path)


def test_forced_align_with_explicit_lengths(simple_emission):
    log_probs, targets = simple_emission
    input_lengths = torch.tensor([5])
    target_lengths = torch.tensor([2])
    paths, scores = forced_align(log_probs, targets, input_lengths, target_lengths)

    assert paths.shape == (1, 5)


def test_forced_align_blank_in_targets_raises():
    log_probs = torch.zeros(1, 5, 3)
    targets = torch.tensor([[0, 1]])  # 0 is blank
    with pytest.raises(ValueError, match="blank index"):
        forced_align(log_probs, targets)


def test_forced_align_target_out_of_range_raises():
    log_probs = torch.zeros(1, 5, 3)
    targets = torch.tensor([[3]])  # only 3 classes (0,1,2)
    with pytest.raises(ValueError, match="less than the CTC dimension"):
        forced_align(log_probs, targets)
