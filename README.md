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
* ruby 2.7.1
* bundler 2.1.4

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

### Advanced: Change the config path

It is possible to move the config file by renaming the executable to `flight-asset-with-config`. This makes the first argument to the script the config path. The config path must be provided with every execution of this script.

```
# Create the executable
ln -s bin/flight-asset bin/flight-asset-with-config

# Execute the CLI with a different config
bin/flight-asset-with-config /tmp/other.yaml
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
