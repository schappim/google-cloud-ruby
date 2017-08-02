# Copyright 2017 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require "helper"
require "google/cloud/debugger/tracer/tracer_test_helper"

##
# Method call defined in different file to distract tracer
def tracer_distraction_method1
  tracer_test_func5
end

describe Google::Cloud::Debugger::Tracer, :mock_debugger do
  let(:breakpoint_path) { File.expand_path("../tracer_test_helper.rb", __FILE__) }
  let(:breakpoint1) {
    Google::Cloud::Debugger::Breakpoint.new "1", breakpoint_path, 21 }
  let(:breakpoint2) {
    Google::Cloud::Debugger::Breakpoint.new "2", breakpoint_path, 34 }
  let(:breakpoint3) {
    Google::Cloud::Debugger::Breakpoint.new "3", breakpoint_path, 47 }
  let(:breakpoint4) {
    Google::Cloud::Debugger::Breakpoint.new "4", breakpoint_path, 54 }
  let(:breakpoint5) {
    Google::Cloud::Debugger::Breakpoint.new "5", breakpoint_path, 62 }
  let(:breakpoint6) {
    Google::Cloud::Debugger::Breakpoint.new "6", breakpoint_path, 70 }
  let(:breakpoint7) {
    Google::Cloud::Debugger::Breakpoint.new "7", breakpoint_path, 72 }

  it "catches breakpoint from function call" do
    hit = false
    stubbed_breakpoints_hit = ->(breakpoints, call_stack_bindings) do
      breakpoints.first.must_equal breakpoint1
      hit = true
    end

    breakpoint_manager.update_breakpoints [breakpoint1]
    tracer = debugger.agent.tracer

    tracer.stub :breakpoints_hit, stubbed_breakpoints_hit do
      tracer.start
      tracer_test_func
      tracer.stop
    end

    hit.must_equal true
  end

  it "catches breakpoint called from a child thread" do
    hit = false
    stubbed_breakpoints_hit = ->(breakpoints, call_stack_bindings) do
      assert_equal breakpoints.first, breakpoint1
      hit = true
    end

    breakpoint_manager.update_breakpoints [breakpoint1]
    tracer = debugger.agent.tracer

    tracer.stub :breakpoints_hit, stubbed_breakpoints_hit do
      tracer.start
      thr = Thread.new do
        tracer_test_func
      end
      thr.join
      tracer.stop
    end

    hit.must_equal true
  end

  it "catches breakpoint from block yield" do
    hit = false
    stubbed_breakpoints_hit = ->(breakpoints, call_stack_bindings) do
      breakpoints.first.must_equal breakpoint2
      hit = true
    end

    breakpoint_manager.update_breakpoints [breakpoint2]
    tracer = debugger.agent.tracer

    tracer.stub :breakpoints_hit, stubbed_breakpoints_hit do
      tracer.start
      tracer_test_func3
      tracer.stop
    end

    hit.must_equal true
  end

  it "catches breakpoint when function interleave files" do
    hit = false
    stubbed_breakpoints_hit = ->(breakpoints, call_stack_bindings) do
      breakpoints.first.must_equal breakpoint3
      hit = true
    end

    breakpoint_manager.update_breakpoints [breakpoint3]
    tracer = debugger.agent.tracer

    tracer.stub :breakpoints_hit, stubbed_breakpoints_hit do
      tracer.start
      tracer_test_func4
      tracer.stop
    end

    hit.must_equal true
  end

  it "catches breakpoint from lambda function" do
    hit = false
    stubbed_breakpoints_hit = ->(breakpoints, call_stack_bindings) do
      breakpoints.first.must_equal breakpoint4
      hit = true
    end

    breakpoint_manager.update_breakpoints [breakpoint4]
    tracer = debugger.agent.tracer

    tracer.stub :breakpoints_hit, stubbed_breakpoints_hit do
      tracer.start
      tracer_test_lambda.call
      tracer.stop
    end

    hit.must_equal true
  end

  it "catches breakpoint from proc" do
    hit = false
    stubbed_breakpoints_hit = ->(breakpoints, call_stack_bindings) do
      breakpoints.first.must_equal breakpoint5
      hit = true
    end

    breakpoint_manager.update_breakpoints [breakpoint5]
    tracer = debugger.agent.tracer

    tracer.stub :breakpoints_hit, stubbed_breakpoints_hit do
      tracer.start
      tracer_test_proc.call
      tracer.stop
    end

    hit.must_equal true
  end

  it "catches breakpoint from fiber" do
    hit = false
    stubbed_breakpoints_hit = ->(breakpoints, call_stack_bindings) do
      assert_equal breakpoints.first, breakpoint6
      hit = true
    end

    breakpoint_manager.update_breakpoints [breakpoint6]
    tracer = debugger.agent.tracer

    tracer.stub :breakpoints_hit, stubbed_breakpoints_hit do
      tracer.start
      tracer_test_fiber.resume
      tracer.stop
    end

    hit.must_equal true
  end

  it "catches breakpoint from fiber after fiber yields" do
    hit = false
    stubbed_breakpoints_hit = ->(breakpoints, call_stack_bindings) do
      assert_equal breakpoints.first, breakpoint7
      hit = true
    end

    breakpoint_manager.update_breakpoints [breakpoint7]
    tracer = debugger.agent.tracer

    tracer.stub :breakpoints_hit, stubbed_breakpoints_hit do
      tracer.start
      test_filber = tracer_test_fiber
      test_filber.resume
      test_filber.resume
      tracer.stop
    end

    hit.must_equal true
  end
end
