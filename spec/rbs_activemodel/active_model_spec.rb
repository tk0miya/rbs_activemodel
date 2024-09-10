# frozen_string_literal: true

require "active_record"
require "rbs_activemodel"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.connection.create_table(:foos)

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

                %a{pure}
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
              attribute :created_at, :datetime
            end
          end
          let(:expected) do
            <<~RBS
              class Foo
                include ::ActiveModel::Attributes
                extend ::ActiveModel::Attributes::ClassMethods

                %a{pure}
                def age: () -> Integer?
                def age=: (Integer? value) -> Integer?

                %a{pure}
                def created_at: () -> (DateTime | ActiveSupport::TimeWithZone)?
                def created_at=: ((DateTime | ActiveSupport::TimeWithZone)? value) -> (DateTime | ActiveSupport::TimeWithZone)?
              end
            RBS
          end

          it { is_expected.to eq expected }
        end
      end

      context "When the class includes ActiveModel::SecurePassword" do
        context "When the class calls has_secure_password without any options" do
          let(:klass) do
            Class.new do
              include ActiveModel::SecurePassword

              has_secure_password
            end
          end
          let(:expected) do
            <<~RBS
              class Foo
                include ::ActiveModel::SecurePassword
                extend ::ActiveModel::SecurePassword::ClassMethods
                include ::ActiveModel::Validations
                extend ::ActiveModel::Validations::ClassMethods

                attr_reader password: String?
                attr_accessor password_confirmation: String
                attr_accessor password_challenge: String

                def password=: (String) -> String
                def password_salt: () -> String
                def authenticate_password: (String) -> (instance | false)

                alias authenticate authenticate_password
              end
            RBS
          end

          it { is_expected.to eq expected }
        end

        context "When the class calls has_secure_password with attribute name" do
          let(:klass) do
            Class.new do
              include ActiveModel::SecurePassword

              has_secure_password :passphrase
            end
          end
          let(:expected) do
            <<~RBS
              class Foo
                include ::ActiveModel::SecurePassword
                extend ::ActiveModel::SecurePassword::ClassMethods
                include ::ActiveModel::Validations
                extend ::ActiveModel::Validations::ClassMethods

                attr_reader passphrase: String?
                attr_accessor passphrase_confirmation: String
                attr_accessor passphrase_challenge: String

                def passphrase=: (String) -> String
                def passphrase_salt: () -> String
                def authenticate_passphrase: (String) -> (instance | false)
              end
            RBS
          end

          it { is_expected.to eq expected }
        end
      end

      context "When the class is a subclass of ActiveRecord::Base" do
        context "When the class calls has_secure_password" do
          let(:klass) do
            Class.new(ActiveRecord::Base) do
              has_secure_password
            end
          end
          let(:expected) do
            <<~RBS
              class Foo < ::ActiveRecord::Base
                attr_reader password: String?
                attr_accessor password_confirmation: String
                attr_accessor password_challenge: String

                def password=: (String) -> String
                def password_salt: () -> String
                def authenticate_password: (String) -> (instance | false)

                alias authenticate authenticate_password
              end
            RBS
          end

          it { is_expected.to eq expected }
        end

        context "When the class does not call has_secure_password" do
          let(:klass) do
            Class.new(ActiveRecord::Base) do
              attribute :name, :string
            end
          end

          it { is_expected.to eq nil }
        end
      end
    end
  end
end
