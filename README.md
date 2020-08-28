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

WIP

## Operation

See the help text for the main commands list:

```
bin/asset --help
```

The commonly used commands have been aliased:
* `list`          => `list-assets`
* `show`          => `show-asset`
* `create`        => `create-asset`
* `decommission`  => `decommission-asset`
* `update`        => `update-asset`
* `move`          => `move-asset`

### Outputting Modes

This application will report back results in one following modes:
(1)  Simplified
(2a) Verbose
(2b) Machine

*1. Simplified*
This mode runs by default in an interactive session. It is primarily intended for humans to read/digest and will make various simplifications.

There maybe minor changes in the output between minor releases.

*2a. Verbose*
This mode runs in an interactive session with the `--verbose` flag. It is guaranteed to display the full output available for a particular resource(s).

The output field order is guaranteed between minor releases\*. 

(\*) The `Additional Information` returned by `show-asset` (and others) will always be the last field. Because the information is free form text, it can not be easily parsed in the `machine` output below. Therefore the information's field index is not guaranteed between minor releases.

*2b. Machine*
The `machine` output is returned in all non-interactive terminals. It is designed to be parsed by a machine is delimited by tab: `\t`.

The field order is guaranteed to match the `verbose` output above. However the "header fields" are not included.

# Known Issues

There are a numerous deprecations warnings concerning the use of the double splat (`**`) operator. These warnings will occur when ran with `ruby 2.7.*` and are generated by the `ruby` binary directly. They will eventually be resolved with library fixes, however they can be manually disabled with:

```
RUBYOPT='-W:no-deprecated -W:no-experimental' bin/flight-asset ...
```

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
