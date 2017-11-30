mage-docker
===========

Versions are based on official node versions.

## Development mode

During development, you can directly run this container by simply mounting your source code into `/usr/src/app`.

```shell
# Install all dependencies
docker run --rm -it -v "$(pwd):/usr/src/app" mage/mage npm install

# Run MAGE
docker run --rm -it -v "$(pwd):/usr/src/app" mage/mage
```

Generally, you will want to start a bash shell and run your `npm` commands from it.

```shell
docker run --rm -it -v "$(pwd):/usr/src/app" mage/mage bash
```

## Building a custom image

You will likely want to build your own custom image for production use.

To build locally, the `Makefile` will require that you have
[`jq`](https://stedolan.github.io/jq/download/) installed locally.

```Dockerfile
FROM mage/mage
# Add your custom steps here
```

This image works as an `onbuild` image. Your code will automatically be added to this image,
then `npm install` will be executed to install all dependencies.


License
-------

MIT.
