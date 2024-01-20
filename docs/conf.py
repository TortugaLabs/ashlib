# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information
# ~ import os,sys
# ~ sys.path.insert(0, os.path.abspath('../src'))
import glob
import os

project = 'ashlib'
copyright = '2023, Alejandro Liu'
author = 'Alejandro Liu'
if os.path.isfile('../VERSION'):
  with open('../VERSION','r') as fp:
    release = fp.read().strip()
else:
  release = 'DEV'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
  'autodoc2',
  'myst_parser',
  'sphinxarg.ext',
]
autodoc2_render_plugin = 'myst'
# ~ autodoc2_packages = [ '../src/myotc', *glob.glob('../src/*.py') ]
autodoc2_packages = list(glob.glob('../*.py'))

myst_enable_extensions = [
  'tasklist',
  'fieldlist',
]
templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']

# ~ autodoc_mock_imports = ['openstack']

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'alabaster'
html_static_path = ['_static']
