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
  module Commands
    class EditAsset < FlightAsset::Command
      include Concerns::HasAssetsRecord

      define_args :name

      before(unless: :tty?) { raise InteractiveOnly }

      def assets_record
        @assets_record ||= begin
          a = request_assets_record_by_name(name)
          a.update(info: with_editor(a.info))
        end
      end

      def with_editor(data)
        file = Tempfile.new(
          File.basename(Config::CACHE.tmp_path),
          File.dirname(Config::CACHE.tmp_path)
        )
        file.write(data || '')
        file.rewind
        TTY::Editor.open(file.path)
        file.read
      ensure
        file.close
        file.unlink
      end
    end
  end
end