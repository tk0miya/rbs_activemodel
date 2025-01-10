# frozen_string_literal: true

require "pathname"
require "rake/tasklib"

module RbsActivemodel
  class RakeTask < Rake::TaskLib
    attr_accessor :name #: Symbol
    attr_accessor :signature_root_dir #: Pathname

    # @rbs name: Symbol
    # @rbs &block: ?(self) -> void
    def initialize(name = :'rbs:activemodel', &block) #: void
      super()

      @name = name
      @signature_root_dir = Pathname(Rails.root / "sig/activemodel")

      block&.call(self)

      define_clean_task
      define_generate_task
      define_setup_task
    end

    def define_setup_task #: void
      desc "Run all tasks of rbs_activemodel"

      deps = [:"#{name}:clean", :"#{name}:generate"]
      task("#{name}:setup" => deps)
    end

    def define_generate_task #: void
      desc "Generate RBS files for activemodel gem"
      task("#{name}:generate": :environment) do
        require "rbs_activemodel" # load RbsActivemodel lazily

        Rails.application.eager_load!

        RbsActivemodel::ActiveModel.all.each do |klass|
          rbs = RbsActivemodel::ActiveModel.class_to_rbs(klass)
          next unless rbs

          path = signature_root_dir / "app/models/#{klass.name&.underscore}.rbs"
          path.dirname.mkpath
          path.write(rbs)
        end
      end
    end

    def define_clean_task #: void
      desc "Clean RBS files for config gem"
      task("#{name}:clean": :environment) do
        signature_root_dir.rmtree if signature_root_dir.exist?
      end
    end
  end
end
