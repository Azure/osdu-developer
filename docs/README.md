# Documentation

Documentation is written in Markdown from the `docs` folder. The
`src` folder contains the sources with the `.md` extension.

We have adopted [MkDocs](https://www.mkdocs.org/) as an open source solution to
build the documentation starting from Markdown format.

Before you submit a pull request for the documentation, you must have gone through the following steps:

1. local test of the documentation
2. run through the spell checker

## How to locally test the documentation

You can locally test the documentation in two ways:

- using Docker
- using `mkdocs` directly

In both cases, you should issue the commands inside the `docs` folder.

With Docker, you just need to execute the following command and point your
browser to `http://127.0.0.1:8000/`:

``` bash
docker run --rm -v "$(pwd):$(pwd)" -w "$(pwd)" -p 8000:8000 \
    minidocks/mkdocs \
    mkdocs serve -a 0.0.0.0:8000
```

If you have installed `mkdocs` directly in your workstation, you can simply run:

``` bash
mkdocs serve
```

Even in this case, point your browser to `http://127.0.0.1:8000/`.

Make sure you review what you have written by putting yourself in the end
user's shoes. Once you are ready, proceed with the spell check and then with
the pull request.

