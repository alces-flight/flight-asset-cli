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
  class Error < RuntimeError
    def self.define_class(code)
      Class.new(self).tap do |klass|
        klass.instance_variable_set(:@exit_code, code)
      end
    end

    def self.exit_code
      @exit_code || begin
        superclass.respond_to?(:exit_code) ? superclass.exit_code : 2
      end
    end

    def exit_code
      self.class.exit_code
    end
  end

  InternalError = Error.define_class(1)
  GeneralError = Error.define_class(2)
  InputError = GeneralError.define_class(3)

  class InteractiveOnly < InputError
    MSG = 'This command requires an interactive terminal'

    def initialize(msg = MSG)
      super
    end
  end

  MissingError = GeneralError.define_class(20)
  AssetMissing = MissingError.define_class(21)
  GroupMissing = MissingError.define_class(21)
  CategoryMissing = MissingError.define_class(22)
end
