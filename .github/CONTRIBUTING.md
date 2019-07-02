Thank you for considering contributing to Badonde!

Any size contributions (from a `README` correction to an entire new feature) are hugely appreciated.

## Issue types

### Feature Pitch

If you have an idea for a new feature and have a general knowledge of how to go about implementing it, you're welcome to open a `Feature Pitch` issue!

Provided the right information, Feature Pitches will tend to be reviewed and interacted with more easily.

Acceptance and implementation of the feature is up to the consensus of the project maintainers.

If your feature is accepted, implementation is then up to the issue author and maintainers to coordinate.

### Feature Request

If you have an idea for a new feature but aren't familiar with Badonde's codebase, please open a `Feature Request` issue after making sure that there isn't an existing one.

Acceptance and implementation of the requested feature is up to the consensus of the project maintainers.

### Bug Report

If you there's something not quite right with Badonde, please open a `Bug Report` issue.

## Get started

After checkout, you can run the following command from the cloned directory, and then open the workspace in Xcode:

```sh
$ swift package generate-xcodeproj
$ open Badonde.xcodeproj
```

Then, to install your development copy of Badonde (and any local changes you've made) on your system, and test with your own repos:

```bash
$ make install
```

If you want to go back to the mainline Brew build, just uninstall the dev copy first:

```bash
$ make uninstall
$ brew install badonde
```
