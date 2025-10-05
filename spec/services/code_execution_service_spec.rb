require 'rails_helper'

RSpec.describe CodeExecutionService do
  describe ".execute" do
    it "delegates to instance method" do
      service = instance_double(CodeExecutionService)
      allow(CodeExecutionService).to receive(:new).and_return(service)
      allow(service).to receive(:execute).and_return({ output: "test" })

      CodeExecutionService.execute(code: "test", language: "ruby", executable_command: "ruby")

      expect(service).to have_received(:execute).with(
        code: "test",
        language: "ruby",
        executable_command: "ruby"
      )
    end
  end

  describe "#execute" do
    let(:service) { described_class.new }

    context "with successful Ruby execution" do
      it "executes Ruby code and returns output" do
        code = "puts 'Hello, World!'"
        result = service.execute(code: code, language: "ruby", executable_command: "ruby")

        expect(result[:output]).to include("Hello, World!")
        expect(result[:success]).to be true
        expect(result[:execution_time]).to be > 0
        expect(result[:exit_code]).to eq(0)
      end

      it "captures stdout correctly" do
        code = "puts 1 + 1"
        result = service.execute(code: code, language: "ruby", executable_command: "ruby")

        expect(result[:output]).to include("2")
        expect(result[:success]).to be true
      end

      it "returns execution time" do
        code = "sleep 0.1; puts 'done'"
        result = service.execute(code: code, language: "ruby", executable_command: "ruby")

        expect(result[:execution_time]).to be >= 0.1
        expect(result[:execution_time]).to be < 1.0
      end
    end

    context "with code that produces errors" do
      it "captures stderr for Ruby errors" do
        code = "raise 'Error message'"
        result = service.execute(code: code, language: "ruby", executable_command: "ruby")

        expect(result[:error]).to include("Error message")
        expect(result[:success]).to be false
        expect(result[:exit_code]).to eq(1)
      end

      it "captures syntax errors" do
        code = "puts 'unclosed string"
        result = service.execute(code: code, language: "ruby", executable_command: "ruby")

        expect(result[:error]).to include("SyntaxError")
        expect(result[:success]).to be false
      end
    end

    context "with Python code" do
      it "executes Python code successfully" do
        code = "print('Python works')"
        result = service.execute(code: code, language: "python", executable_command: "python3")

        expect(result[:output]).to include("Python works")
        expect(result[:success]).to be true
      end

      it "creates temp file with .py extension" do
        code = "print('test')"
        allow(Tempfile).to receive(:new).and_call_original

        service.execute(code: code, language: "python", executable_command: "python3")

        expect(Tempfile).to have_received(:new).with([ "code_execution", ".py" ])
      end
    end

    context "with JavaScript code" do
      it "creates temp file with .js extension" do
        code = "console.log('test')"
        allow(Tempfile).to receive(:new).and_call_original

        service.execute(code: code, language: "javascript", executable_command: "node")

        expect(Tempfile).to have_received(:new).with([ "code_execution", ".js" ])
      end
    end

    context "with TypeScript code" do
      it "creates temp file with .ts extension" do
        code = "console.log('typescript')"
        allow(Tempfile).to receive(:new).and_call_original

        # Use a simple command that won't fail if ts-node is not installed
        service.execute(code: code, language: "typescript", executable_command: "echo")

        expect(Tempfile).to have_received(:new).with([ "code_execution", ".ts" ])
      end
    end

    context "with Go code" do
      it "executes Go code successfully if go is installed" do
        skip "Go not installed" unless system("which go > /dev/null 2>&1")

        code = 'package main\nimport "fmt"\nfunc main() { fmt.Println("Hello from Go") }'
        result = service.execute(code: code, language: "go", executable_command: "go run")

        expect(result[:output]).to include("Hello from Go")
        expect(result[:success]).to be true
      end

      it "creates temp file with .go extension" do
        code = "package main"
        allow(Tempfile).to receive(:new).and_call_original

        # Use echo if go is not installed
        command = system("which go > /dev/null 2>&1") ? "go run" : "echo"
        service.execute(code: code, language: "go", executable_command: command)

        expect(Tempfile).to have_received(:new).with([ "code_execution", ".go" ])
      end
    end

    context "with timeout handling" do
      it "times out long-running code" do
        code = "sleep 31" # Exceeds TIMEOUT (30 seconds)

        result = service.execute(code: code, language: "ruby", executable_command: "ruby")

        expect(result[:output]).to eq("")
        expect(result[:error]).to include("timed out")
        expect(result[:success]).to be false
        expect(result[:exit_code]).to eq(-1)
      end

      it "returns timeout duration in execution_time" do
        stub_const("CodeExecutionService::TIMEOUT", 1.second)
        code = "sleep 10"

        result = service.execute(code: code, language: "ruby", executable_command: "ruby")

        expect(result[:execution_time]).to eq(1.0)
      end
    end

    context "with output truncation" do
      it "truncates large output" do
        stub_const("CodeExecutionService::MAX_OUTPUT_SIZE", 100)
        code = "puts 'x' * 200"

        result = service.execute(code: code, language: "ruby", executable_command: "ruby")

        expect(result[:output].bytesize).to be <= 200 # 100 + truncation message
        expect(result[:output]).to include("output truncated")
      end

      it "does not truncate small output" do
        code = "puts 'small output'"

        result = service.execute(code: code, language: "ruby", executable_command: "ruby")

        expect(result[:output]).to include("small output")
        expect(result[:output]).not_to include("truncated")
      end

      it "handles nil output" do
        allow_any_instance_of(CodeExecutionService).to receive(:run_with_timeout).and_return(
          [ nil, nil, double(success?: true, exitstatus: 0) ]
        )

        result = service.execute(code: "test", language: "ruby", executable_command: "ruby")

        expect(result[:output]).to eq("")
        expect(result[:error]).to eq("")
      end
    end

    context "with compiled languages" do
      it "recognizes gcc_wrapper command" do
        code = "#include <stdio.h>\nint main() { printf(\"Hello\"); return 0; }"

        result = service.execute(code: code, language: "c", executable_command: "gcc_wrapper")

        expect(result[:output]).to include("Hello")
        expect(result[:success]).to be true
      end

      it "handles compilation errors" do
        code = "invalid C code"

        result = service.execute(code: code, language: "c", executable_command: "gcc_wrapper")

        expect(result[:error]).to include("Compilation failed")
        expect(result[:success]).to be false
      end

      it "creates temp file with .c extension for C code" do
        code = "int main() { return 0; }"
        allow(Tempfile).to receive(:new).and_call_original

        service.execute(code: code, language: "c", executable_command: "gcc_wrapper")

        expect(Tempfile).to have_received(:new).with([ "code_execution", ".c" ])
      end

      it "creates temp file with .cpp extension for C++ code" do
        code = "int main() { return 0; }"
        allow(Tempfile).to receive(:new).and_call_original

        service.execute(code: code, language: "c++", executable_command: "g++_wrapper")

        expect(Tempfile).to have_received(:new).with([ "code_execution", ".cpp" ])
      end

      it "cleans up compiled executable after execution" do
        code = "#include <stdio.h>\nint main() { return 0; }"

        allow(File).to receive(:delete)

        service.execute(code: code, language: "c", executable_command: "gcc_wrapper")

        expect(File).to have_received(:delete).at_least(:once)
      end
    end

    context "with different C/C++ standards" do
      it "handles gcc_c98_wrapper" do
        code = "#include <stdio.h>\nint main() { printf(\"C98\"); return 0; }"

        result = service.execute(code: code, language: "c (c98)", executable_command: "gcc_c98_wrapper")

        expect(result[:output]).to include("C98")
      end

      it "handles gcc_gnu11_wrapper" do
        code = "#include <stdio.h>\nint main() { printf(\"GNU11\"); return 0; }"

        result = service.execute(code: code, language: "c (gnu11)", executable_command: "gcc_gnu11_wrapper")

        expect(result[:output]).to include("GNU11")
      end

      it "handles g++_wrapper (default C++)" do
        code = "#include <iostream>\nint main() { std::cout << \"C++\"; return 0; }"

        result = service.execute(code: code, language: "c++", executable_command: "g++_wrapper")

        expect(result[:output]).to include("C++")
      end

      it "handles g++_98_wrapper" do
        code = "#include <iostream>\nint main() { std::cout << \"C++98\"; return 0; }"

        result = service.execute(code: code, language: "c++ (c++98)", executable_command: "g++_98_wrapper")

        expect(result[:output]).to include("C++98")
      end

      it "handles g++_11_wrapper" do
        code = "#include <iostream>\nint main() { std::cout << \"C++11\"; return 0; }"

        result = service.execute(code: code, language: "c++ (c++11)", executable_command: "g++_11_wrapper")

        expect(result[:output]).to include("C++11")
      end

      it "handles g++_17_wrapper" do
        code = "#include <iostream>\nint main() { std::cout << \"C++17\"; return 0; }"

        result = service.execute(code: code, language: "c++ (c++17)", executable_command: "g++_17_wrapper")

        expect(result[:output]).to include("C++17")
      end
    end

    context "with file extension mapping" do
      it "uses .sh for bash" do
        code = "echo 'bash'"
        allow(Tempfile).to receive(:new).and_call_original

        service.execute(code: code, language: "bash", executable_command: "bash")

        expect(Tempfile).to have_received(:new).with([ "code_execution", ".sh" ])
      end

      it "uses .go for Go" do
        code = "package main"
        allow(Tempfile).to receive(:new).and_call_original

        # Skip actual execution if go is not installed
        if system("which go > /dev/null 2>&1")
          service.execute(code: code, language: "go", executable_command: "go")
        else
          service.execute(code: code, language: "go", executable_command: "echo")
        end

        expect(Tempfile).to have_received(:new).with([ "code_execution", ".go" ])
      end

      it "uses .txt for unknown languages" do
        code = "test"
        allow(Tempfile).to receive(:new).and_call_original

        service.execute(code: code, language: "unknown", executable_command: "cat")

        expect(Tempfile).to have_received(:new).with([ "code_execution", ".txt" ])
      end
    end

    context "with temporary file cleanup" do
      it "cleans up temp file after successful execution" do
        code = "puts 'test'"
        temp_file_path = nil

        allow(Tempfile).to receive(:new).and_wrap_original do |m, *args|
          file = m.call(*args)
          temp_file_path = file.path
          file
        end

        service.execute(code: code, language: "ruby", executable_command: "ruby")

        expect(File.exist?(temp_file_path)).to be false
      end

      it "cleans up temp file after timeout" do
        stub_const("CodeExecutionService::TIMEOUT", 1.second)
        code = "sleep 10"
        temp_file_path = nil

        allow(Tempfile).to receive(:new).and_wrap_original do |m, *args|
          file = m.call(*args)
          temp_file_path = file.path
          file
        end

        service.execute(code: code, language: "ruby", executable_command: "ruby")

        expect(File.exist?(temp_file_path)).to be false
      end

      it "cleans up temp file after error" do
        code = "raise 'error'"
        temp_file_path = nil

        allow(Tempfile).to receive(:new).and_wrap_original do |m, *args|
          file = m.call(*args)
          temp_file_path = file.path
          file
        end

        service.execute(code: code, language: "ruby", executable_command: "ruby")

        expect(File.exist?(temp_file_path)).to be false
      end
    end
  end
end
