class CodeExecutionService
  TIMEOUT = 30.seconds
  MAX_OUTPUT_SIZE = 10.kilobytes

  def self.execute(code:, language:, executable_command:)
    new.execute(code: code, language: language, executable_command: executable_command)
  end

  def execute(code:, language:, executable_command:)
    start_time = Time.current

    # Create a temporary file for the code
    temp_file = create_temp_file(code, language)

    begin
      # Execute the code with timeout and output limits
      output, error, status = run_with_timeout(executable_command, temp_file.path)

      execution_time = (Time.current - start_time).round(3)

      {
        output: truncate_output(output),
        error: truncate_output(error),
        success: status.success?,
        execution_time: execution_time,
        exit_code: status.exitstatus
      }

    rescue Timeout::Error
      {
        output: "",
        error: "Execution timed out after #{TIMEOUT} seconds",
        success: false,
        execution_time: TIMEOUT.to_f,
        exit_code: -1
      }
    ensure
      # Clean up temporary file
      temp_file.close
      temp_file.unlink if File.exist?(temp_file.path)
    end
  end

  private

  def create_temp_file(code, language)
    # Get file extension for the language
    extension = get_file_extension(language)

    # Create temporary file
    temp_file = Tempfile.new([ "code_execution", extension ])
    temp_file.write(code)
    temp_file.close
    temp_file
  end

  def get_file_extension(language)
    case language.downcase
    when "ruby"
      ".rb"
    when "python"
      ".py"
    when "javascript"
      ".js"
    when "typescript"
      ".ts"
    when "c", "c (c98)", "c (gnu11)"
      ".c"
    when "c++", "c++ (c++98)", "c++ (c++11)", "c++ (c++17)"
      ".cpp"
    when "bash"
      ".sh"
    when "go"
      ".go"
    else
      ".txt"
    end
  end

  def run_with_timeout(command, file_path)
    # Handle compiled languages specially
    if command.include?("_wrapper")
      execute_compiled_language(command, file_path)
    else
      execute_interpreted_language(command, file_path)
    end
  end

  def execute_interpreted_language(command, file_path)
    # Use Open3 to capture both stdout and stderr with timeout
    require "timeout"
    require "open3"

    output = ""
    error = ""
    status = nil

    Timeout.timeout(TIMEOUT) do
      # Pass command and file_path as separate arguments to avoid injection
      output, error, status = Open3.capture3(command, file_path)
    end

    [ output, error, status ]
  end

  def execute_compiled_language(command, file_path)
    require "timeout"
    require "open3"

    # Create output executable path
    output_executable = "#{file_path}_out"

    begin
      # Compile first using safe argument passing
      compile_args = case command
      when "gcc_wrapper"
        ["gcc", "-o", output_executable, file_path]
      when "gcc_c98_wrapper"
        ["gcc", "-o", output_executable, file_path]
      when "gcc_gnu11_wrapper"
        ["gcc", "-std=gnu11", "-o", output_executable, file_path]
      when "g++_wrapper"
        ["g++", "-o", output_executable, file_path]
      when "g++_98_wrapper"
        ["g++", "-std=c++98", "-o", output_executable, file_path]
      when "g++_11_wrapper"
        ["g++", "-std=c++11", "-o", output_executable, file_path]
      when "g++_17_wrapper"
        ["g++", "-std=c++17", "-o", output_executable, file_path]
      end

      # Compile with timeout
      compile_output = ""
      compile_error = ""
      compile_status = nil

      Timeout.timeout(TIMEOUT) do
        compile_output, compile_error, compile_status = Open3.capture3(*compile_args)
      end

      # If compilation failed, return the compile error
      unless compile_status.success?
        return [ compile_output, "Compilation failed:\n#{compile_error}", compile_status ]
      end

      # If compilation succeeded, run the executable
      Timeout.timeout(TIMEOUT) do
        Open3.capture3(output_executable)
      end

    ensure
      # Clean up the executable
      File.delete(output_executable) if File.exist?(output_executable)
    end
  end

  def truncate_output(text)
    return "" if text.nil?

    if text.bytesize > MAX_OUTPUT_SIZE
      truncated = text.byteslice(0, MAX_OUTPUT_SIZE)
      truncated + "\n\n... (output truncated, max #{MAX_OUTPUT_SIZE} bytes)"
    else
      text
    end
  end
end
