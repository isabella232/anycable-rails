# frozen_string_literal: true

require "compatibility_spec_helper"

describe "Compatibility" do
  describe "Channel" do
    class CompatibilityChannel < ActionCable::Channel::Base
      def follow; end
    end

    let(:socket) { instance_double("socket", subscribe: nil) }
    let(:connection) { instance_double("connection", identifiers: [], socket: socket) }

    subject { CompatibilityChannel.new(connection, "channel_id") }

    describe "Channel#stream_from" do
      it "not throws exception when JSON coder is passed" do
        allow_any_instance_of(CompatibilityChannel).to receive(:follow) do |channel|
          channel.stream_from("all", coder: ActiveSupport::JSON)
        end

        expect { subject.follow }.not_to raise_exception
      end

      it "throws exception when not JSON coder is passed" do
        allow_any_instance_of(CompatibilityChannel).to receive(:follow) do |channel|
          channel.stream_from("all", coder: :some_coder)
        end

        expect { subject.follow }.to raise_exception(
          Anycable::CompatibilityError,
          "Custom coders are not supported in AnyCable!"
        )
      end

      it "throws exception when callback is passed" do
        allow_any_instance_of(CompatibilityChannel).to receive(:follow) do |channel|
          channel.stream_from("all", -> {})
        end

        expect { subject.follow }.to raise_exception(
          Anycable::CompatibilityError,
          "Custom stream callbacks are not supported in AnyCable!"
        )
      end

      it "throws exception when block is passed" do
        allow_any_instance_of(CompatibilityChannel).to receive(:follow) do |channel|
          channel.stream_from("all") {}
        end

        expect { subject.follow }.to raise_exception(
          Anycable::CompatibilityError,
          "Custom stream callbacks are not supported in AnyCable!"
        )
      end
    end

    describe "Channel#subscribe" do
      it "throws CompatibilityError when new instance variables were defined" do
        allow_any_instance_of(CompatibilityChannel).to receive(:subscribed) do |channel|
          channel.instance_variable_set(:@test, "test")
        end

        expect { subject.handle_subscribe }.to raise_exception(
          Anycable::CompatibilityError,
          "Channel instance variables are not supported in AnyCable!"
        )
      end
    end

    describe "#periodically" do
      it "throws CompatibilityError when called" do
        expect do
          CompatibilityChannel.periodically(:do_something, every: 2.seconds)
        end.to raise_exception(
          Anycable::CompatibilityError,
          "Periodical Timers are not supported in AnyCable!"
        )
      end
    end
  end

  describe "RemoteConnection#disconnect" do
    let(:user) { User.new(name: "john", secret: "123") }
    let(:url) { "" }

    subject { ActionCable.server.remote_connections.where(current_user: user.to_gid_param, url: url) }

    it "throws CompatibilityError when called" do
      expect { subject.disconnect }.to raise_exception(
        Anycable::CompatibilityError,
        "Disconnecting remote clients is not supported in AnyCable!"
      )
    end
  end
end
