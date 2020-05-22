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
      include Concerns::BeforeConfiguredCheck

      define_args :name

      before(if: :tty?) do
        error = FileSizeError.new(original.size, Config::CACHE.file_size)
        if error.oversized?
          puts error.warning_msg
          raise error unless prompt.yes? 'Do you wish to continue?'
        end
      end

      before(unless: :tty?) { raise InteractiveOnly }

      def run
        with_temp_file do |file|
          # Writes the original copy to the file
          file.write original
          file.rewind

          # Opens the file in an editor for the user
          TTY::Editor.open(file.path)

          # Computes the digests (and generates the error object for size check)
          old_digest = Digest::SHA256.digest original
          new_digest = Digest::SHA256.file(file.path).digest
          error = FileSizeError.new(file.size, Config::CACHE.file_size!)

          if old_digest == new_digest
            # Logs the content has not changed
            Config::CACHE.logger.warn <<~WARN.chomp
              Skipping the edit as the information has not changed!
            WARN
          elsif error.oversized?
            raise error
          else
            # Updates the record if the digests match
            @assets_record = assets_record.update(info: file.read)
          end
        end
      end

      def assets_record
        @assets_record ||= request_assets_record_by_name(name)
      end

      def original
        assets_record.info || ''
      end

      def with_temp_file
        file = Tempfile.new(
          File.basename(Config::CACHE.tmp_path),
          File.dirname(Config::CACHE.tmp_path)
        )
        yield file
      ensure
        file&.close
        file&.unlink
      end
    end
  end
end
