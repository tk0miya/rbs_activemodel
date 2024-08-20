# frozen_string_literal: true

require "rbs_activemodel"

RSpec.describe RbsActivemodel::ActiveModel do
  describe ".class_to_rbs" do
    subject { described_class.class_to_rbs(klass) }

    before do
      stub_const("Foo", klass)
    end

    context "When class is not a activemodel class" do
      let(:klass) { Class.new }

      it { is_expected.to eq nil }
    end

    context "When class is a activemodel class" do
      context "When the class includes ActiveModel::Model" do
        let(:klass) do
          Class.new do
            include ActiveModel::Model
          end
        end
        let(:expected) do
          <<~RBS
            class Foo
              include ::ActiveModel::Model
              include ::ActiveModel::Validations
              extend ::ActiveModel::Validations::ClassMethods
            end
          RBS
        end

        it { is_expected.to eq expected }
      end

      context "When the class includes ActiveModel::Validations" do
        let(:klass) do
          Class.new do
            include ActiveModel::Validations
          end
        end
        let(:expected) do
          <<~RBS
            class Foo
              include ::ActiveModel::Validations
              extend ::ActiveModel::Validations::ClassMethods
            end
          RBS
        end

        it { is_expected.to eq expected }
      end

      context "When the class includes ActiveModel::Attributes" do
        context "When the attribute is defined as required (presence)" do
          let(:klass) do
            Class.new do
              include ActiveModel::Attributes
              include ActiveModel::Validations

              validates :name, presence: true

              attribute :name, :string
            end
          end
          let(:expected) do
            <<~RBS
              class Foo
                include ::ActiveModel::Attributes
                extend ::ActiveModel::Attributes::ClassMethods
                include ::ActiveModel::Validations
                extend ::ActiveModel::Validations::ClassMethods

                def name: () -> String
                def name=: (String value) -> String
              end
            RBS
          end

          it { is_expected.to eq expected }
        end

        context "When the attribute is defined as required (optional)" do
          let(:klass) do
            Class.new do
              include ActiveModel::Attributes

              attribute :age, :integer
            end
          end
          let(:expected) do
            <<~RBS
              class Foo
                include ::ActiveModel::Attributes
                extend ::ActiveModel::Attributes::ClassMethods

                def age: () -> Integer?
                def age=: (Integer? value) -> Integer?
              end
            RBS
          end

          it { is_expected.to eq expected }
        end
      end
    end
  end
end