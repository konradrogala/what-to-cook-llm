# frozen_string_literal: true

require "rails_helper"
require "openai"

RSpec.describe Api::V1::ErrorHandler, type: :controller do
  class TestController < ActionController::API
    include Api::V1::ErrorHandler

    def test_action
      raise error
    end

    private

    def error
      raise NotImplementedError
    end
  end

  controller TestController do
  end

  let(:counter) { instance_double(Api::V1::RequestCounter) }

  before do
    routes.draw { get "test_action" => "test#test_action" }
    allow(Api::V1::RequestCounter).to receive(:new).and_return(counter)
    allow(counter).to receive(:remaining_requests).and_return(4)
  end

  describe "error handling" do
    context "when OpenAI::Error is raised" do
      context "with rate limit error" do
        let(:error_message) { "rate limit exceeded" }

        before do
          allow_any_instance_of(TestController).to receive(:error).and_raise(OpenAI::Error.new(error_message))
        end

        it "returns too_many_requests status" do
          get :test_action
          expect(response).to have_http_status(:too_many_requests)
        end

        it "returns proper error message with remaining requests" do
          get :test_action
          json_response = JSON.parse(response.body)
          expect(json_response["error"]).to include("API rate limit exceeded")
          expect(json_response["remaining_requests"]).to eq(4)
        end
      end

      context "with other OpenAI error" do
        let(:error_message) { "some other error" }

        before do
          allow_any_instance_of(TestController).to receive(:error).and_raise(OpenAI::Error.new(error_message))
        end

        it "returns service_unavailable status" do
          get :test_action
          expect(response).to have_http_status(:service_unavailable)
        end

        it "returns proper error message with remaining requests" do
          get :test_action
          json_response = JSON.parse(response.body)
          expect(json_response["error"]).to include("OpenAI API error")
          expect(json_response["remaining_requests"]).to eq(4)
        end
      end
    end

    context "when RecipeGenerator::GenerationError is raised" do
      before do
        allow_any_instance_of(TestController).to receive(:error)
          .and_raise(Api::V1::RecipeGenerator::GenerationError.new("Generation failed"))
      end

      it "returns unprocessable_entity status" do
        get :test_action
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns proper error message with remaining requests" do
        get :test_action
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Failed to generate recipe: Generation failed")
        expect(json_response["remaining_requests"]).to eq(4)
      end
    end

    context "when StandardError is raised" do
      before do
        allow_any_instance_of(TestController).to receive(:error)
          .and_raise(StandardError.new("Unexpected error"))
      end

      it "returns internal_server_error status" do
        get :test_action
        expect(response).to have_http_status(:internal_server_error)
      end

      it "returns proper error message with remaining requests" do
        get :test_action
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("An unexpected error occurred")
        expect(json_response["remaining_requests"]).to eq(4)
      end
    end
  end
end
