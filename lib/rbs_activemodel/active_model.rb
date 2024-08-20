# frozen_string_literal: true

require "active_model"
require "bigdecimal"
require "date"
require "rbs"

module RbsActivemodel
  module ActiveModel
    def self.all
      ObjectSpace.each_object.select do |obj|
        obj.is_a?(Class) && obj.ancestors.include?(::ActiveModel::Validations)
      rescue StandardError
        nil
      end
    end

    def self.class_to_rbs(klass)
      Generator.new(klass).generate
    end

    class Generator
      MIXINS = [::ActiveModel::Model, ::ActiveModel::Attributes, ::ActiveModel::Validations].freeze
      TYPES = {
        big_integer: Integer,
        binary: String,
        boolean: :bool,
        date: Date,
        datetime: DateTime,
        decimal: BigDecimal,
        float: Float,
        immutable_string: String,
        integer: Integer,
        string: String,
        time: Time
      }.freeze

      def initialize(klass)
        @klass = klass
        @klass_name = klass.name || ""
      end

      def generate
        return if mixins.empty?

        format <<~RBS
          #{header}
          #{mixins}

          #{attributes}
          #{footer}
        RBS
      end

      private

      attr_reader :klass, :klass_name

      def format(rbs)
        parsed = RBS::Parser.parse_signature(rbs)
        StringIO.new.tap do |out|
          RBS::Writer.new(out: out).write(parsed[1] + parsed[2])
        end.string
      end

      def header
        namespace = +""
        klass_name.split("::").map do |mod_name|
          namespace += "::#{mod_name}"
          mod_object = Object.const_get(namespace)
          case mod_object
          when Class
            if mod_object.superclass == Object
              "class #{mod_name}"
            else
              superclass_name = mod_object.superclass&.name || "Object"
              "class #{mod_name} < ::#{superclass_name}"
            end
          when Module
            "module #{mod_name}"
          else
            raise "unreachable"
          end
        end.join("\n")
      end

      def mixins
        MIXINS.each_with_object([]) do |mod, mixins|
          if klass < mod
            mixins << "include ::#{mod.name}"
            mixins << "extend  ::#{mod.name}::ClassMethods" if mod.const_defined?(:ClassMethods)
          end
        end.join("\n")
      end

      def attributes
        return "" unless klass < ::ActiveModel::Attributes

        # @type var model: untyped
        model = klass
        model.attribute_types.map do |name, type|
          type = TYPES.fetch(type.type, :untyped)
          type_name = type.is_a?(Class) ? type.name : type.to_s
          suffix = "?" unless required_attribute?(name)
          <<~RBS
            def #{name}: () -> #{type_name}#{suffix}
            def #{name}=: (#{type_name}#{suffix} value) -> #{type_name}#{suffix}
          RBS
        end.join("\n")
      end

      def required_attribute?(name)
        return false unless klass < ::ActiveModel::Validations

        klass.validators.any? do |v| # steep:ignore NoMethod
          v.is_a?(::ActiveModel::Validations::PresenceValidator) && v.attributes.include?(name.to_sym)
        end
      end

      def footer
        "end\n" * klass.module_parents.size # steep:ignore
      end
    end
  end
end