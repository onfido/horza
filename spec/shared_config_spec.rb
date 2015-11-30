require 'spec_helper'

describe Horza::SharedConfig do
  subject(:target_class) { Class.new.send(:extend, Horza::SharedConfig) }

  it "expose same Horza config instance to target class" do
    expect(subject.configuration).to be Horza.configuration
  end

  it "delegates config methods to Horza" do
    [:reset, :constant_paths,:clear_constant_paths, :adapter, :adapter=].each do |_meth_|
      expect(Horza).to receive(_meth_)
      target_class.send _meth_
    end
  end
end