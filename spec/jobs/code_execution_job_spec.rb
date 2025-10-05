require 'rails_helper'

RSpec.describe CodeExecutionJob, type: :job do
  let(:language) do
    create(:language,
      name: "Ruby",
      extension: "rb",
      interactive: true,
      executable_command: "ruby"
    )
  end

  let(:document) { create(:document) }

  let(:code_block) do
    create(:code_block,
      document: document,
      language: language,
      interactive: true,
      data: { "code" => "puts 'Hello World'" }
    )
  end

  let(:code) { "puts 'Test Code'" }

  describe "#perform" do
    context "with valid executable code block" do
      it "executes the code using CodeExecutionService" do
        execution_result = {
          output: "Test Code\n",
          error: nil,
          execution_time: 0.05
        }

        expect(CodeExecutionService).to receive(:execute).with(
          code: code,
          language: "ruby",
          executable_command: "ruby"
        ).and_return(execution_result)

        allow(ActionCable.server).to receive(:broadcast)

        described_class.new.perform(code_block.id, code)

        code_block.reload
        result = code_block.execution_result
        expect(result["status"]).to eq("completed")
        expect(result["output"]).to eq("Test Code\n")
        expect(result["executed_at"]).to be_present
      end

      it "stores execution result in block data" do
        execution_result = {
          output: "Hello\n",
          error: nil,
          execution_time: 0.1
        }

        allow(CodeExecutionService).to receive(:execute).and_return(execution_result)
        allow(ActionCable.server).to receive(:broadcast)

        described_class.new.perform(code_block.id, code)

        code_block.reload
        expect(code_block.execution_result["status"]).to eq("completed")
        expect(code_block.execution_result["output"]).to eq("Hello\n")
        expect(code_block.execution_result["execution_time"]).to eq(0.1)
      end

      it "broadcasts success result via ActionCable" do
        execution_result = {
          output: "Success\n",
          error: nil,
          execution_time: 0.05
        }

        allow(CodeExecutionService).to receive(:execute).and_return(execution_result)

        expect(ActionCable.server).to receive(:broadcast).with(
          "code_execution_#{code_block.id}",
          hash_including(
            status: "completed",
            output: "Success\n",
            error: nil,
            block_id: code_block.id
          )
        )

        described_class.new.perform(code_block.id, code)
      end

      it "includes execution_time in broadcast" do
        execution_result = {
          output: "Done\n",
          error: nil,
          execution_time: 0.25
        }

        allow(CodeExecutionService).to receive(:execute).and_return(execution_result)

        expect(ActionCable.server).to receive(:broadcast).with(
          "code_execution_#{code_block.id}",
          hash_including(execution_time: 0.25)
        )

        described_class.new.perform(code_block.id, code)
      end
    end

    context "with non-CodeBlock" do
      let(:markdown_block) { create(:markdown_block, document: document) }

      it "logs error and returns early" do
        expect(Rails.logger).to receive(:error).with(/does not support execution/)
        expect(CodeExecutionService).not_to receive(:execute)

        described_class.new.perform(markdown_block.id, code)
      end

      it "does not broadcast anything" do
        allow(Rails.logger).to receive(:error)
        expect(ActionCable.server).not_to receive(:broadcast)

        described_class.new.perform(markdown_block.id, code)
      end
    end

    context "with non-executable code block" do
      let(:non_interactive_block) do
        create(:code_block,
          document: document,
          language: language,
          interactive: false
        )
      end

      it "logs error and returns early" do
        expect(Rails.logger).to receive(:error).with(/does not support execution/)
        expect(CodeExecutionService).not_to receive(:execute)

        described_class.new.perform(non_interactive_block.id, code)
      end
    end

    context "when execution service raises an exception" do
      before do
        allow(CodeExecutionService).to receive(:execute).and_raise(
          StandardError, "Execution timeout"
        )
      end

      it "logs the error" do
        allow(ActionCable.server).to receive(:broadcast)

        expect(Rails.logger).to receive(:error).with(
          /Code execution failed.*Execution timeout/
        )

        described_class.new.perform(code_block.id, code)
      end

      it "stores error result in block" do
        allow(ActionCable.server).to receive(:broadcast)

        described_class.new.perform(code_block.id, code)

        code_block.reload
        result = code_block.execution_result
        expect(result["status"]).to eq("failed")
        expect(result["error"]).to eq("Execution timeout")
        expect(result["executed_at"]).to be_present
      end

      it "broadcasts error via ActionCable" do
        expect(ActionCable.server).to receive(:broadcast).with(
          "code_execution_#{code_block.id}",
          {
            status: "failed",
            error: "Execution timeout",
            block_id: code_block.id
          }
        )

        described_class.new.perform(code_block.id, code)
      end

      it "saves the block with error result" do
        allow(ActionCable.server).to receive(:broadcast)

        described_class.new.perform(code_block.id, code)

        code_block.reload
        expect(code_block.execution_result["status"]).to eq("failed")
      end
    end

    context "when execution returns error output" do
      it "handles stderr in execution result" do
        execution_result = {
          output: "",
          error: "RuntimeError: something went wrong",
          execution_time: 0.02
        }

        allow(CodeExecutionService).to receive(:execute).and_return(execution_result)

        expect(ActionCable.server).to receive(:broadcast).with(
          "code_execution_#{code_block.id}",
          hash_including(
            status: "completed",
            error: "RuntimeError: something went wrong"
          )
        )

        described_class.new.perform(code_block.id, code)
      end
    end

    context "job enqueueing" do
      it "can be enqueued" do
        expect {
          CodeExecutionJob.perform_later(code_block.id, code)
        }.to have_enqueued_job(CodeExecutionJob).with(code_block.id, code)
      end

      it "runs on the default queue" do
        expect(CodeExecutionJob.new.queue_name).to eq("default")
      end
    end

    context "integration with CodeExecutionService" do
      it "passes correct parameters to service" do
        python_lang = create(:language,
          name: "Python",
          extension: "py",
          interactive: true,
          executable_command: "python3"
        )

        python_block = create(:code_block,
          document: document,
          language: python_lang,
          interactive: true
        )

        python_code = "print('Hello')"

        expect(CodeExecutionService).to receive(:execute).with(
          code: python_code,
          language: "python",
          executable_command: "python3"
        ).and_return({ output: "Hello\n", error: nil, execution_time: 0.1 })

        allow(ActionCable.server).to receive(:broadcast)

        described_class.new.perform(python_block.id, python_code)
      end
    end
  end
end
