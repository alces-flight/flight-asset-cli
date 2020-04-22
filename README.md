# Flight Asset

Manage Alces Flight Center Assets

## Overview

This command line utility manages Alces Flight Center assets including the following:
* View and list the assets, groups, and categories,
* Create a new asset,
* Modify the asset's support type, and
* Decommission assets and groups.

## Installation

The application requires a modern(ish) version of `ruby`/`bundler`. It has been designed with the following versions in mind:
* centos7
* ruby 2.6.1
* bundler 1.17.3

After downloading the source code (via git or other means), the gems need to be installed using bundler:

```
cd /path/to/source
bundle install --with default --without development --path vendor
```

## Configuration

By default this application will look for `etc/config.yaml` as its configuration file. This config can be easily created using the `wizard` utility. It is not possible to exit the wizard until all the `REQUIRED` flags have been provided (see `wizard --help` for details). The `--finished` flag will exit the wizard after all the required flags have been provided.

```
# The the list of required configuration flags
bin/flight-asset wizard --help

# Example command setting configs
# NOTE: The --finished flag is required to exit the wizard
bin/flight-asset wizard --jwt foo --component-id bar --finished
```

## Operation

WIP

# Contributing

Fork the project. Make your feature addition or bug fix. Send a pull
request. Bonus points for topic branches.

Read [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

# Copyright and License

Eclipse Public License 2.0, see [LICENSE.txt](LICENSE.txt) for details.

Copyright (C) 2019-present Alces Flight Ltd.

This program and the accompanying materials are made available under
the terms of the Eclipse Public License 2.0 which is available at
[https://www.eclipse.org/legal/epl-2.0](https://www.eclipse.org/legal/epl-2.0),
or alternative license terms made available by Alces Flight Ltd -
please direct inquiries about licensing to
[licensing@alces-flight.com](mailto:licensing@alces-flight.com).

Flight Asset is distributed in the hope that it will be
useful, but WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER
EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR
CONDITIONS OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR
A PARTICULAR PURPOSE. See the [Eclipse Public License 2.0](https://opensource.org/licenses/EPL-2.0) for more
details.
