#!/bin/sh
target=$(dirname "$0")
cd "$target"

python3 -m venv --system-site-packages .venv
#~ python3 -m venv .venv
. .venv/bin/activate

# sphinx related dependancies
pip install docutils sphinx
pip install myst-parser sphinx-autodoc2
#~ pip install sphinx-autodoc2[cli]
#~ pip install sphinx-argparse

# sphinxcontrib-globalsubs
#~
#~ pip install myst-parser
#~ pip install sphinxcontrib-autoprogram sphinxcontrib-redoc
