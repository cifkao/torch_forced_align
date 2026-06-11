---
title: torch_forced_align
---

[`torch_forced_align`]({{ site.github.url }}) is a standalone distribution of [torchaudio]'s CTC
[**forced alignment**][forced_align] op ([`forced_align`][forced_align]),
with builds for various PyTorch and CUDA versions, so that you can use it without pulling in 
torchaudio and without locking in a specific PyTorch version.

[torchaudio]: https://github.com/pytorch/audio
[forced_align]: https://docs.pytorch.org/audio/main/generated/torchaudio.functional.forced_align.html

## Install

<div id="picker">
  <div class="picker-row">
    <span class="picker-label">Installer</span>
    <span class="picker-opts" id="opt-installer"></span>
  </div>
  <div class="picker-row">
    <span class="picker-label">PyTorch</span>
    <span class="picker-opts" id="opt-torch"></span>
  </div>
  <div class="picker-row">
    <span class="picker-label">Compute</span>
    <span class="picker-opts" id="opt-backend"></span>
  </div>
  <div class="picker-row">
    <span class="picker-label">Command</span>
    <pre class="picker-cmd" id="picker-cmd"></pre>
  </div>
</div>

The selected `torch-forced-align` index must match the PyTorch version and the CUDA version it was built for.

<script>
  const COMBOS = [
  {% for c in site.data.wheels.combos %}{torch: {{ c.torch | jsonify }}, backend: {{ c.backend | jsonify }}, url: {{ c.url | jsonify }}},
  {% endfor %}];
  const PAGES_URL = {{ site.github.url | jsonify }};

  // PyTorch's own index suffix for a given wheel backend (cu12 is generic CUDA 12.x).
  const ptIndex = (b) => b === "cu12" ? "cu128" : b;

  const uniq = (xs) => [...new Set(xs)];
  const installers = ["uv", "pip"];
  const torches = uniq(COMBOS.map(c => c.torch));            // already newest-first
  const backendOrder = (b) => b === "cpu" ? 1 : 0;           // CUDA first, CPU last
  const backends = uniq(COMBOS.map(c => c.backend)).sort((a, z) => backendOrder(a) - backendOrder(z) || a.localeCompare(z));

  let sel = { installer: installers[0], torch: torches[0], backend: null };
  const has = (t, b) => COMBOS.some(c => c.torch === t && c.backend === b);

  function render() {
    if (!has(sel.torch, sel.backend)) sel.backend = backends.find(b => has(sel.torch, b));
    const combo = COMBOS.find(c => c.torch === sel.torch && c.backend === sel.backend);
    const prefix = sel.installer === "uv" ? "uv pip install" : "pip install";

    paint("opt-installer", installers, i => i, i => { sel.installer = i; }, i => sel.installer === i, () => true);
    paint("opt-torch", torches, t => t, t => { sel.torch = t; }, t => sel.torch === t, () => true);
    paint("opt-backend", backends, b => b, b => { sel.backend = b; }, b => sel.backend === b, b => has(sel.torch, b));

    document.getElementById("picker-cmd").textContent =
      prefix + " torch-forced-align \\\n" +
      "  --extra-index-url " + PAGES_URL + "/" + combo.url + " \\\n" +
      "  --extra-index-url https://download.pytorch.org/whl/" + ptIndex(combo.backend);
  }

  function paint(id, items, label, onPick, isActive, isEnabled) {
    const host = document.getElementById(id);
    host.innerHTML = "";
    for (const it of items) {
      const btn = document.createElement("button");
      btn.textContent = label(it);
      if (isActive(it)) btn.classList.add("active");
      if (!isEnabled(it)) btn.disabled = true;
      else btn.onclick = () => { onPick(it); render(); };
      host.appendChild(btn);
    }
  }

  render();
</script>

## Usage

Usage is identical to [`torchaudio.functional.forced_align`][forced_align]:
```python
from torch_forced_align import forced_align
import torch

log_probs = torch.randn(1, 50, 30).log_softmax(-1)
targets = torch.tensor([[1, 3, 5, 2]])

paths, scores = forced_align(log_probs, targets, blank=0)
```

## Available wheels

{% assign last = "" %}
<table>
  <thead>
    <tr><th>PyTorch</th><th>Backend</th><th>Python</th><th>Index</th></tr>
  </thead>
  <tbody>
  {% for c in site.data.wheels.combos %}
    <tr>
      <td><strong>{% if c.torch != last %}{{ c.torch }}{% assign last = c.torch %}{% endif %}</strong></td>
      <td>{{ c.backend }}</td>
      <td>{{ c.pythons | split: "," | join: ", " }}</td>
      <td><a href="{{ c.url }}"><code>{{ c.tag }}/</code></a></td>
    </tr>
  {% endfor %}
  </tbody>
</table>
