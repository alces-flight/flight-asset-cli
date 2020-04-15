# frozen_string_literal: true
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

module FlightAsset
  class Config < Hashie::Dash
    property :base_url, default: 'https://example.com/api/v1'
    property :jwt, default: ''

    # Define Constants Last
    Config::PATH = File.join(File.join(__dir__, '../../etc/config.yaml'))
    Config::CACHE = if File.file? Config::PATH
                      begin
                        new YAML.load(File.read(Config::PATH), symbolize_names: true)
                      rescue
                        raise InternalError, "Failed to load config: #{Config::PATH}"
                      end
                    else
                      new
                    end
  end
end

