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
      before do
        Horza.reset
        Horza.configure { |config| config.adapter = :active_record }
      end
      after { Horza.reset }
      it 'returns appropriate class' do
        expect(Horza.adapter).to eq Horza::Adapters::ActiveRecord
      end
    end
  end
end

describe Horza::Adapters::Options do
  subject {  Horza::Adapters::Options.new(options) }

  context 'when all options are defined' do
    let(:options) do
      {
        conditions: { last_name: 'Turner' },
        order: { last_name: :asc },
        limit: 20,
        offset: 10,
        target: :sports_cars,
        via: [:employer]
      }
    end

    Horza::Adapters::Options::META_METHODS.each do |method|
      context "##{method}" do
        it 'returns conditions' do
          expect(subject.send(method)).to eq options[method]
        end
      end
    end

    context '#order_field' do
      context 'when order is passed' do
        it 'returns key of options hash' do
          expect(subject.order_field).to eq(:last_name)
        end
      end

      context 'when order is not passed' do
        let(:options) { { conditions: { last_name: 'Turner' } } }
        it 'defaults to id' do
          expect(subject.order_field).to eq(:id)
        end
      end
    end

    context '#order_direction' do
      context 'when order is passed' do
        it 'returns key of options hash' do
          expect(subject.order_direction).to eq(:asc)
        end
      end

      context 'when order is not passed' do
        let(:options) { { conditions: { last_name: 'Turner' } } }
        it 'defaults to desc' do
          expect(subject.order_direction).to eq(:desc)
        end
      end
    end
  end
end
