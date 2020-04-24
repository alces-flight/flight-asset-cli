#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of Flight Asset.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Asset is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Asset. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Asset, please visit:
# https://github.com/alces-flight/alces-flight/flight-asset-cli
#==============================================================================

require 'yaml'
require 'hashie'
require 'simple_jsonapi_client'
require 'faraday'
require 'faraday_middleware'
require 'cgi'
require 'tty-table'

require_relative 'flight_asset/errors'
require_relative 'flight_asset/config'

require_relative 'flight_asset/records'

require_relative 'flight_asset/command'
require_relative 'flight_asset/commands'

Dir.glob(File.join(__dir__, 'flight_asset/commands/concerns', '*.rb')).each do |f|
  require_relative f
end

Dir.glob(File.join(__dir__, 'flight_asset/commands', '*.rb')).each do |f|
  require_relative f
end

# Ensures the CLI file is required last
# NOTE: In most cases it has already been required
require_relative 'flight_asset/cli'

