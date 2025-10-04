module ToastHelper
  def toast_turbo_stream(message, type = "info", **options)
    turbo_stream.append "toast_container" do
      content_tag "div", "",
        data: {
          controller: "toast",
          toast_message_value: message,
          toast_type_value: type,
          toast_duration_value: options[:duration] || 3000
        }
    end
  end

  def success_toast(message, **options)
    toast_turbo_stream(message, "success", **options)
  end

  def error_toast(message, **options)
    toast_turbo_stream(message, "error", **options)
  end

  def warning_toast(message, **options)
    toast_turbo_stream(message, "warning", **options)
  end

  def info_toast(message, **options)
    toast_turbo_stream(message, "info", **options)
  end
end
