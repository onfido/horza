require 'spec_helper'

describe Horza do
  context '#adapter' do
    context 'when adapter is not configured' do
      before { Horza.reset }
      after { Horza.reset }
      it 'throws error' do
        expect { Horza.adapter }.to raise_error(Horza::Errors::AdapterNotConfigured)
      end
    end

    context 'when adapter is configured' do
      before { Horza.configure { |config| config.adapter = :active_record } }
      after { Horza.reset }
      it 'returns appropriate class' do
        expect(Horza.adapter).to eq Horza::Adapters::ActiveRecord
      end
    end
  end
end
