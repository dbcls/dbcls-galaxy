# -*- coding: utf-8 -*-
require File.expand_path('../workflow', File.dirname(__FILE__))

describe WorkflowRunner, "は" do
  include GalaxyTool::Matcher
  
  before do
    @workflow_runner = WorkflowRunner.new
  end

  it "ユーザID指定として '-u' オプションを受けつける" do
    @workflow_runner.should accept_option_with_argument(:user_id, '-u')
  end

  it "ユーザID指定として '--user-id' オプションを受けつける" do
    @workflow_runner.should accept_option_with_argument(:user_id, '--user-id')
  end

  it "ユーザID指定は必須である" do
    @workflow_runner.should require_option(:user_id)
  end

  it "ワークフローID指定として '-w' オプションを受けつける" do
    @workflow_runner.should accept_option_with_argument(:workflow_id, '-w')
  end

  it "ワークフローID指定として '--workflow-id' オプションを受けつける" do
    @workflow_runner.should accept_option_with_argument(:workflow_id, '--workflow-id')
  end

  it "入力データセットファイル指定として '-i' オプションを受けつける" do
    @workflow_runner.should accept_option_with_argument(:input_dataset, '-i')
  end

  it "入力データセットファイル指定として '--input-dataset' オプションを受けつける" do
    @workflow_runner.should accept_option_with_argument(:input_dataset, '--input-dataset')
  end

  it "'--input-dataset' オプションを、入力用のデータセットとして受けつける" do
    @workflow_runner.should evaluate_option('--input-dataset', stub_file("hoge\nfuga\n").path, "hoge\nfuga\n")
  end

  it "ワークフローリスト表示の指定として '-l' オプションを受けつける" do
    @workflow_runner.should accept_option(:list, '-l')
  end

  it "ワークフローリスト表示の指定として '--list' オプションを受けつける" do
    @workflow_runner.should accept_option(:list, '--list')
  end

  describe "ユーザID、ワークフローID、入力データセットファイルパスを指定して実行すると" do
    before do
      no10_dataset = Dataset.new
      no10_dataset.id = 234
      no10_dataset.history_number = 10
      Dataset.should_receive(:upload).with("genome\n").and_return(no10_dataset)

      Galaxy.should_receive(:run_workflow).with("529fd61ab1c6cc36", 234).and_return([11, 12])

      no11_dataset = Dataset.new
      no11_dataset.id = 235
      no11_dataset.history_number = 11
      no12_dataset = Dataset.new
      no12_dataset.id = 236
      no12_dataset.history_number = 12
      Dataset.should_receive(:find_by_history_numbers).with([11, 12]).and_return([no11_dataset, no12_dataset])
      Dataset.should_receive(:wait)

      @output = stub_file
      @workflow_runner.should_receive(:output).and_return(@output.path)

      input_dataset_path = stub_file("genome\n")
      
      @workflow_runner.run ["-u", "eco@example.com", "-w", "529fd61ab1c6cc36", "-i", input_dataset_path.path]
    end

    it "Galaxyのワークローを実行し、結果URL一覧を標準出力に表示すること。" do
      @output.should be_output(<<-EOT)
http://localhost:37280/datasets/235/display/index
http://localhost:37280/datasets/236/display/index
      EOT
    end
  end

  describe "--listオプションを指定して実行すると" do
    before do
      @workflow_runner.should_receive(:workflows).and_return([WorkflowRunner::Workflow.new('d9abeb98649a6a7e', 'Workflow2'), WorkflowRunner::Workflow.new('529fd61ab1c6cc36', 'Workflow1')])
      @output = stub_file
      @workflow_runner.should_receive(:output).and_return(@output.path)
      @workflow_runner.run ["--list", "-u", "eco@example.com", "-w", "529fd61ab1c6cc36"]
    end

    it "ワークフローの一覧を標準出力に表示すること。" do
      @output.should be_output(<<-EOT)
d9abeb98649a6a7e\tWorkflow2
529fd61ab1c6cc36\tWorkflow1
      EOT
    end
  end

  describe "入力データセットファイルが不要な場合に未指定で実行しても" do
    before do
      Galaxy.should_receive(:run_workflow).with("529fd61ab1c6cc36").and_return([11, 12])

      no11_dataset = Dataset.new
      no11_dataset.id = 235
      no11_dataset.history_number = 11
      no12_dataset = Dataset.new
      no12_dataset.id = 236
      no12_dataset.history_number = 12
      Dataset.should_receive(:find_by_history_numbers).with([11, 12]).and_return([no11_dataset, no12_dataset])
      Dataset.should_receive(:wait)

      @output = stub_file
      @workflow_runner.should_receive(:output).and_return(@output.path)

      input_dataset_path = stub_file("genome\n")
      
      @workflow_runner.run ["-u", "eco@example.com", "-w", "529fd61ab1c6cc36"]
    end

    it "問題なく実行できること。" do
      @output.should be_output(<<-EOT)
http://localhost:37280/datasets/235/display/index
http://localhost:37280/datasets/236/display/index
      EOT
    end
  end

  describe "リスト表示などではない通常実行時に、ワークフローID指定なしで実行すると、" do
    before do
      @workflow_runner.should_receive(:option_error_handler).and_return(proc {|optparse, exception|
                                                                          raise exception
                                                                        })

      @output = stub_file
      @workflow_runner.should_receive(:output).and_return(@output.path)
    end

    it "エラーで終了すること。" do
      proc {
        @workflow_runner.run ["-u", "eco@example.com"]
      }.should raise_error(GalaxyTool::RequiredOptionNotFoundError)
    end
  end

end
