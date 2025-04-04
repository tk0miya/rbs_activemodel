# frozen_string_literal: true

require "active_model"
require "active_record"
require "bigdecimal"
require "date"
require "rbs"

module RbsActivemodel
  module ActiveModel
    def self.all #: Array[Class]
      ObjectSpace.each_object.select do |obj|
        obj.is_a?(Class) && obj.ancestors.include?(::ActiveModel::Validations)
      rescue StandardError
        nil
      end
    end

    # @rbs klass: Class
    def self.class_to_rbs(klass) #: String?
      Generator.new(klass).generate
    end

    class Generator
      MIXINS = [::ActiveModel::Model, ::ActiveModel::Attributes,
                ::ActiveModel::SecurePassword, ::ActiveModel::Validations].freeze #: Array[Module]
      TYPES = {
        big_integer: Integer,
        binary: String,
        boolean: :bool,
        date: Date,
        datetime: "DateTime | ActiveSupport::TimeWithZone",
        decimal: BigDecimal,
        float: Float,
        immutable_string: String,
        integer: Integer,
        string: String,
        time: Time
      }.freeze #: Hash[Symbol, Class | String | Symbol]

      # @rbs @secure_password: String
      # @rbs @mixins: String
      # @rbs @attributes: String

      # @rbs klass: Class
      def initialize(klass) #: void
        @klass = klass
        @klass_name = klass.name || ""
      end

      def generate #: String?
        return if mixins.empty? && secure_password.empty? && attributes.empty?

        format <<~RBS
          #{header}
          #{mixins}

          #{secure_password}

          #{attributes}
          #{footer}
        RBS
      end

      private

      attr_reader :klass #: Class
      attr_reader :klass_name #: String

      # @rbs rbs: String
      def format(rbs) #: String
        parsed = RBS::Parser.parse_signature(rbs)
        StringIO.new.tap do |out|
          RBS::Writer.new(out: out).write(parsed[1] + parsed[2])
        end.string
      end

      def header #: String
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

      def secure_password #: String
        return "" if klass.ancestors.none?(::ActiveModel::SecurePassword::InstanceMethodsOnActivation)

        methods = klass.instance_methods.grep(/^authenticate_/)
        @secure_password ||= methods.filter_map do |method_name|
          attribute = method_name.to_s.split("_").last
          next unless klass.instance_methods.include?(:"#{attribute}_confirmation")

          <<~RBS
            attr_reader #{attribute}: String?
            attr_accessor #{attribute}_confirmation: String
            attr_accessor #{attribute}_challenge: String

            def #{attribute}=: (String) -> String
            def #{attribute}_salt: () -> String
            def authenticate_#{attribute}: (String) -> (instance | false)

            #{"alias authenticate authenticate_password" if attribute == "password"}
          RBS
        end.join("\n")
      end

      def mixins #: String
        return "" if klass < ActiveRecord::Base

        @mixins ||= MIXINS.each_with_object([]) do |mod, mixins|
          if klass < mod
            mixins << "include ::#{mod.name}"
            mixins << "extend  ::#{mod.name}::ClassMethods" if mod.const_defined?(:ClassMethods)
          end
        end.join("\n")
      end

      def attributes #: String
        return "" unless klass < ::ActiveModel::Attributes

        # @type var model: untyped
        model = klass
        @attributes ||= model.attribute_types.map do |name, type|
          type = TYPES.fetch(type.type, :untyped)
          type_name = case type
                      when Class
                        type.name
                      when String
                        "(#{type})"
                      else
                        type.to_s
                      end
          suffix = "?" unless having_default?(name) || required_attribute?(name)
          <<~RBS
            %a{pure}
            def #{name}: () -> #{type_name}#{suffix}
            def #{name}=: (#{type_name}#{suffix} value) -> #{type_name}#{suffix}
          RBS
        end.join("\n")
      end

      # @rbs name: String
      def having_default?(name) #: bool
        klass.instance_eval { pending_attribute_modifications }
             .find do |mod|
               mod.is_a?(::ActiveModel::AttributeRegistration::ClassMethods::PendingDefault) && mod.name == name
             end
      end

      # @rbs name: String
      def required_attribute?(name) #: bool
        return false unless klass < ::ActiveModel::Validations

        klass.validators.any? do |v| # steep:ignore NoMethod
          v.is_a?(::ActiveModel::Validations::PresenceValidator) && v.attributes.include?(name.to_sym)
        end
      end

      def footer #: String
        "end\n" * klass.module_parents.size # steep:ignore
      end
    end
  end
end
