require 'rails_helper'

RSpec.describe ToastHelper, type: :helper do
  describe "#toast_turbo_stream" do
    it "creates turbo stream append to toast_container" do
      result = helper.toast_turbo_stream("Test message", "info")
      html = result.to_s

      expect(html).to include('action="append"')
      expect(html).to include('target="toast_container"')
    end

    it "includes message in data attribute" do
      result = helper.toast_turbo_stream("Hello World", "success")
      html = result.to_s

      expect(html).to include('data-toast-message-value="Hello World"')
    end

    it "includes type in data attribute" do
      result = helper.toast_turbo_stream("Warning!", "warning")
      html = result.to_s

      expect(html).to include('data-toast-type-value="warning"')
    end

    it "uses default duration of 3000ms" do
      result = helper.toast_turbo_stream("Test", "info")
      html = result.to_s

      expect(html).to include('data-toast-duration-value="3000"')
    end

    it "accepts custom duration option" do
      result = helper.toast_turbo_stream("Long message", "info", duration: 5000)
      html = result.to_s

      expect(html).to include('data-toast-duration-value="5000"')
    end

    it "includes toast controller" do
      result = helper.toast_turbo_stream("Test", "info")
      html = result.to_s

      expect(html).to include('data-controller="toast"')
    end
  end

  describe "#success_toast" do
    it "creates toast with success type" do
      result = helper.success_toast("Success!")
      html = result.to_s

      expect(html).to include('data-toast-type-value="success"')
      expect(html).to include('data-toast-message-value="Success!"')
    end

    it "accepts duration option" do
      result = helper.success_toast("Done", duration: 2000)
      html = result.to_s

      expect(html).to include('data-toast-duration-value="2000"')
    end
  end

  describe "#error_toast" do
    it "creates toast with error type" do
      result = helper.error_toast("Error occurred!")
      html = result.to_s

      expect(html).to include('data-toast-type-value="error"')
      expect(html).to include('data-toast-message-value="Error occurred!"')
    end

    it "accepts duration option" do
      result = helper.error_toast("Failed", duration: 4000)
      html = result.to_s

      expect(html).to include('data-toast-duration-value="4000"')
    end
  end

  describe "#warning_toast" do
    it "creates toast with warning type" do
      result = helper.warning_toast("Warning!")
      html = result.to_s

      expect(html).to include('data-toast-type-value="warning"')
      expect(html).to include('data-toast-message-value="Warning!"')
    end

    it "accepts duration option" do
      result = helper.warning_toast("Be careful", duration: 3500)
      html = result.to_s

      expect(html).to include('data-toast-duration-value="3500"')
    end
  end

  describe "#info_toast" do
    it "creates toast with info type" do
      result = helper.info_toast("Information")
      html = result.to_s

      expect(html).to include('data-toast-type-value="info"')
      expect(html).to include('data-toast-message-value="Information"')
    end

    it "accepts duration option" do
      result = helper.info_toast("Note this", duration: 1500)
      html = result.to_s

      expect(html).to include('data-toast-duration-value="1500"')
    end
  end
end
