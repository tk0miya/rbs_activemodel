# frozen_string_literal: true

require "rails"

module RbsActivemodel
  class InstallGenerator < Rails::Generators::Base
    def create_raketask #: void
      create_file "lib/tasks/rbs_activemodel.rake", <<~RUBY
        # frozen_string_literal: true

        begin
          require 'rbs_activemodel/rake_task'

          RbsActivemodel::RakeTask.new do |task|
          end
        rescue LoadError
          # failed to load rbs_activemodel. Skip to load rbs_activemodel tasks.
        end
      RUBY
    end
  end
end
