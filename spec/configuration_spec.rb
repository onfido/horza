require 'spec_helper'

describe Horza::Config do
  describe "#adapter" do

    it "not set" do
      expect { subject.adapter }.to raise_error(Horza::Errors::AdapterError, /No adapter configured/)
    end

    context "setting adapter" do
      it "finds adapter class if given" do
        subject.adapter = :active_record

        expect(subject.adapter).to eq Horza::Adapters::ActiveRecord
      end

      it "raises if adapter class doesn't exist" do
        expect { subject.adapter = :missing }.to raise_error(Horza::Errors::AdapterError, /No adapter found/)
      end

      it "doesn't raise if no name is given" do
        expect { subject.adapter = nil }.to_not raise_error(Horza::Errors::AdapterError)
      end
    end
  end
end