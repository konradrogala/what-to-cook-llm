# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::ErrorHandler, type: :controller do
  controller(ApplicationController) do
    include Api::V1::ErrorHandler

    def test_action
      raise error
    end

    private

    def error
      raise NotImplementedError
    end
  end

  before do
    routes.draw { get "test_action" => "anonymous#test_action" }
  end

  describe "error handling" do
    context "when OpenAI::Error is raised" do
      context "with rate limit error" do
        let(:error_message) { "rate limit exceeded" }

        before do
          allow(controller).to define_singleton_method(:error) do
            raise OpenAI::Error.new(error_message)
          end
        end

        it "returns too_many_requests status" do
          get :test_action
          expect(response).to have_http_status(:too_many_requests)
        end

        it "returns proper error message" do
          get :test_action
          expect(JSON.parse(response.body)["error"]).to include("API rate limit exceeded")
        end
      end

      context "with other OpenAI error" do
        let(:error_message) { "some other error" }

        before do
          allow(controller).to define_singleton_method(:error) do
            raise OpenAI::Error.new(error_message)
          end
        end

        it "returns service_unavailable status" do
          get :test_action
          expect(response).to have_http_status(:service_unavailable)
        end

        it "returns proper error message" do
          get :test_action
          expect(JSON.parse(response.body)["error"]).to include("OpenAI API error")
        end
      end
    end

    context "when RecipeGenerator::GenerationError is raised" do
      before do
        allow(controller).to define_singleton_method(:error) do
          raise Api::V1::RecipeGenerator::GenerationError.new("Generation failed")
        end
      end

      it "returns unprocessable_entity status" do
        get :test_action
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns proper error message" do
        get :test_action
        expect(JSON.parse(response.body)["error"]).to eq("Generation failed")
      end
    end

    context "when StandardError is raised" do
      before do
        allow(controller).to define_singleton_method(:error) do
          raise StandardError.new("Unexpected error")
        end
      end

      it "returns internal_server_error status" do
        get :test_action
        expect(response).to have_http_status(:internal_server_error)
      end

      it "returns proper error message" do
        get :test_action
        expect(JSON.parse(response.body)["error"]).to eq("An unexpected error occurred")
      end
    end
  end
end
