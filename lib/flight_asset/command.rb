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
  class Command
    attr_reader :args, :opts

    def self.define_args(*names)
      names.each_with_index do |name, index|
        define_method(name) { args[index] }
      end
    end

    def initialize(*args, **opts)
      @args = args.dup
      @opts = Hashie::Mash.new(**opts.dup)
    end

    ##
    # The main runner method that preforms the action
    # This method must not print to StandardOut as this gets in the way of output
    # toggling
    def run
      raise NotImplementedError
    end

    ##
    # Outputs the prettified output intended for humans
    # This output MAY change but should be avoided
    def print_pretty
      print_machine
    end

    ##
    # Machine readable output of the command
    # This output MUST only be changed in machine compatible way
    # This means the following
    #   * Headers MUST not be printed to STDOUT
    #   * The column (/row) orders must be consistent
    #   * New columns/rows must be appended to the end
    #   * Tables MUST be TAB separated
    #   * The above can only be broken on major version bumps
    #
    # NOTE: The column order MAY differ from the print_pretty
    # method due to the above restrictions, if and when this happens
    # a --headers global flag should be added to print the headers
    def print_machine
      raise InternalError, 'No output available!'
    end
  end
end

