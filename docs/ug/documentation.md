# Documentation

Documentation of the generator and related infrastructure is hosted under `docs`. Static `html` documentation is build from the latest `master` branch by the CI. We use [mkdocs](https://www.mkdocs.org/) together with the [material theme](https://squidfunk.github.io/mkdocs-material/). Before building the documentation, make sure you have the required dependencies installed:

```bash
pip install -r docs/requirements.txt
```

After everything ist installed, you can build and serve a local copy by executing:

```bash
mkdocs serve
```

This opens a local webserver listening on [http://127.0.0.1:8000/](http://127.0.0.1:8000/).

## Organization

The `docs` folder is organized as follows:

* `rm`: Reference manuals, listings and detailed design decisions.
* `ug`: User guides, more tutorial style texts to get contributors and user up-to-speed.

