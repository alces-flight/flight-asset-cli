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

# Bug Fix to SimpleJSONAPIClient where it does not handle optional has-one
# relationships. The request MAY still return 200 even if the resource doesn't
# exist. This is because *technically* the "relationship resource" exists even
# if it doesn't have a target.
# See: https://jsonapi.org/format/#fetching-relationships-responses-404

module SimpleJSONAPIClientPatch
  def interpret_singular_response(response, connection)
    return nil if response.body.nil?
    super
  end
end

class << SimpleJSONAPIClient::Base
  self.prepend SimpleJSONAPIClientPatch
end
