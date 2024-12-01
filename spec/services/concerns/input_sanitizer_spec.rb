require "rails_helper"

RSpec.describe InputSanitizer do
  let(:dummy_class) { Class.new { include InputSanitizer } }
  let(:instance) { dummy_class.new }

  describe "#sanitize_input" do
    context "with string input" do
      it "handles valid input" do
        expect(instance.sanitize_input("tomatoes, pasta")).to eq("tomatoes, pasta")
      end

      it "trims whitespace" do
        expect(instance.sanitize_input(" tomatoes ")).to eq("tomatoes")
      end

      it "escapes HTML characters" do
        expect(instance.sanitize_input("tomatoes & pasta")).to eq("tomatoes &amp; pasta")
      end

      it "raises error for input exceeding max length" do
        long_input = "a" * (InputSanitizer::MAX_INPUT_LENGTH + 1)
        expect { instance.sanitize_input(long_input) }
          .to raise_error(InputSanitizer::InputError, /exceeds maximum length/)
      end

      it "raises error for invalid characters" do
        expect { instance.sanitize_input("tomatoes; DROP TABLE recipes;") }
          .to raise_error(InputSanitizer::InputError, /contains invalid characters/)
      end
    end

    context "with array input" do
      it "handles valid array input" do
        expect(instance.sanitize_input([ "tomatoes", "pasta" ]))
          .to eq([ "tomatoes", "pasta" ])
      end

      it "sanitizes each array element" do
        expect(instance.sanitize_input([ " tomatoes ", "pasta & sauce" ]))
          .to eq([ "tomatoes", "pasta &amp; sauce" ])
      end

      it "raises error if any element is invalid" do
        expect { instance.sanitize_input([ "tomatoes", "pasta;DROP TABLE" ]) }
          .to raise_error(InputSanitizer::InputError, /contains invalid characters/)
      end
    end

    context "with invalid input type" do
      it "raises error for nil" do
        expect { instance.sanitize_input(nil) }
          .to raise_error(InputSanitizer::InputError, /Invalid input type/)
      end

      it "raises error for hash" do
        expect { instance.sanitize_input({ ingredient: "tomatoes" }) }
          .to raise_error(InputSanitizer::InputError, /Invalid input type/)
      end
    end
  end
end
