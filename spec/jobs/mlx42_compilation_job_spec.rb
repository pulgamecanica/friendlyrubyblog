require 'rails_helper'

RSpec.describe Mlx42CompilationJob, type: :job do
  let(:document) { create(:document) }
  let(:mlx42_block) do
    Mlx42Block.create!(
      document: document,
      position: 1,
      data: {
        "text" => "#include <MLX42/MLX42.h>\nvoid user_main(int argc, char **argv) {}",
        "width" => 800,
        "height" => 600
      }
    )
  end

  describe "#perform" do
    it "sets compilation status to compiling when job starts" do
      allow_any_instance_of(Mlx42CompilerService).to receive(:compile).and_return({ success: true })
      allow_any_instance_of(Mlx42CompilationJob).to receive(:broadcast_compilation_result)

      described_class.new.perform(mlx42_block.id)

      mlx42_block.reload
      expect(mlx42_block.data["compilation_status"]).to eq("success")
      expect(mlx42_block.data["compilation_started_at"]).to be_present
    end

    it "updates status to success when compilation succeeds" do
      allow_any_instance_of(Mlx42CompilerService).to receive(:compile).and_return({ success: true })
      allow_any_instance_of(Mlx42CompilationJob).to receive(:broadcast_compilation_result)

      described_class.new.perform(mlx42_block.id)

      mlx42_block.reload
      expect(mlx42_block.data["compilation_status"]).to eq("success")
      expect(mlx42_block.data["compilation_completed_at"]).to be_present
    end

    it "updates status to failed when compilation fails" do
      allow_any_instance_of(Mlx42CompilerService).to receive(:compile).and_return({
        success: false,
        error: "Compilation error: syntax error"
      })
      allow_any_instance_of(Mlx42CompilationJob).to receive(:broadcast_compilation_result)

      described_class.new.perform(mlx42_block.id)

      mlx42_block.reload
      expect(mlx42_block.data["compilation_status"]).to eq("failed")
      expect(mlx42_block.data["compilation_completed_at"]).to be_present
    end

    it "broadcasts compilation result via ActionCable on success" do
      allow_any_instance_of(Mlx42CompilerService).to receive(:compile).and_return({ success: true })

      expect(ActionCable.server).to receive(:broadcast).with(
        "mlx42_compilation_#{mlx42_block.id}",
        hash_including(
          status: "success",
          block_id: mlx42_block.id,
          compilation_status: "success"
        )
      )

      described_class.new.perform(mlx42_block.id)
    end

    it "broadcasts compilation result via ActionCable on failure" do
      allow_any_instance_of(Mlx42CompilerService).to receive(:compile).and_return({
        success: false,
        error: "Compilation failed"
      })

      expect(ActionCable.server).to receive(:broadcast).with(
        "mlx42_compilation_#{mlx42_block.id}",
        hash_including(
          status: "failed",
          error: "Compilation failed",
          block_id: mlx42_block.id,
          compilation_status: "failed"
        )
      )

      described_class.new.perform(mlx42_block.id)
    end

    it "handles compilation service exceptions and sets error status" do
      allow_any_instance_of(Mlx42CompilerService).to receive(:compile).and_raise(
        StandardError, "Compiler crashed"
      )

      described_class.new.perform(mlx42_block.id)

      mlx42_block.reload
      expect(mlx42_block.data["compilation_status"]).to eq("error")
      expect(mlx42_block.data["compilation_error"]).to eq("Compiler crashed")
    end

    it "calls Mlx42CompilerService with the block" do
      compiler_service = instance_double(Mlx42CompilerService)
      allow(Mlx42CompilerService).to receive(:new).with(mlx42_block).and_return(compiler_service)
      allow(compiler_service).to receive(:compile).and_return({ success: true })
      allow_any_instance_of(Mlx42CompilationJob).to receive(:broadcast_compilation_result)

      described_class.new.perform(mlx42_block.id)

      expect(Mlx42CompilerService).to have_received(:new).with(mlx42_block)
      expect(compiler_service).to have_received(:compile)
    end

    it "can be enqueued" do
      expect {
        Mlx42CompilationJob.perform_later(mlx42_block.id)
      }.to have_enqueued_job(Mlx42CompilationJob).with(mlx42_block.id)
    end

    it "runs on the default queue" do
      expect(Mlx42CompilationJob.new.queue_name).to eq("default")
    end
  end

  describe "#broadcast_compilation_result" do
    it "broadcasts with correct channel name" do
      job = described_class.new
      result = { success: true, error: nil }

      expect(ActionCable.server).to receive(:broadcast).with(
        "mlx42_compilation_#{mlx42_block.id}",
        hash_including(status: "success")
      )

      job.send(:broadcast_compilation_result, mlx42_block, result)
    end

    it "includes all necessary data in broadcast" do
      job = described_class.new
      result = { success: false, error: "Test error" }
      mlx42_block.data = mlx42_block.data.to_h.merge("compilation_status" => "failed")
      mlx42_block.save!

      expect(ActionCable.server).to receive(:broadcast).with(
        "mlx42_compilation_#{mlx42_block.id}",
        {
          status: "failed",
          error: "Test error",
          block_id: mlx42_block.id,
          compilation_status: "failed"
        }
      )

      job.send(:broadcast_compilation_result, mlx42_block, result)
    end
  end
end
