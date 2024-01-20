#!/bin/sh
target=$(dirname "$0")
cd "$target"

python3 -m venv --system-site-packages .venv
#~ python3 -m venv .venv
. .venv/bin/activate

# sphinx related dependancies
pip install docutils sphinx
pip install sphinx-argparse
pip install myst-parser sphinx-autodoc2
#~ pip install sphinx-autodoc2[cli]

# sphinxcontrib-globalsubs
#~ pip install sphinxcontrib-autoprogram sphinxcontrib-redoc
