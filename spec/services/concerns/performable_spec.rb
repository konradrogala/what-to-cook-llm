# frozen_string_literal: true

require "rails_helper"

RSpec.describe Performable do
  let(:test_class) do
    Class.new do
      include Performable

      def perform
        "test result"
      end
    end
  end

  describe ".perform" do
    it "creates a new instance and calls perform" do
      expect(test_class.perform).to eq("test result")
    end

    context "with arguments" do
      let(:test_class_with_args) do
        Class.new do
          include Performable

          def initialize(arg1, arg2)
            @arg1 = arg1
            @arg2 = arg2
          end

          def perform
            [@arg1, @arg2]
          end
        end
      end

      it "passes arguments to initialize" do
        expect(test_class_with_args.perform("value1", "value2")).to eq(["value1", "value2"])
      end
    end
  end
end
