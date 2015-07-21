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

  context '#configuration #namespaces' do
    context 'when namespaces are not configured' do
      before { Horza.reset }
      after { Horza.reset }
      it 'returns empty array' do
        expect(Horza.configuration.namespaces.is_a? Array).to be true
        expect(Horza.configuration.namespaces.empty?).to be true
      end
    end

    context 'when namespaces are configured' do
      module HorzaNamespace
      end

      before do
        Horza.reset
        Horza.configure { |config| config.namespaces = [HorzaNamespace] }
      end
      after { Horza.reset }
      it 'returns configured namespaces class' do
        expect(Horza.configuration.namespaces).to eq [HorzaNamespace]
      end
    end
  end
end

describe Horza::Entities::Single do
  subject { Horza::Entities::Single.new(first_name: 'Blake') }

  describe '#generic_getter' do
    it 'returns the value of the requested attributes' do
      expect(subject.generic_getter(:first_name)).to eq 'Blake'
    end
  end

  describe '#read_attribute_for_serialization' do
    it 'returns the value of the requested attributes' do
      expect(subject.read_attribute_for_serialization(:first_name)).to eq 'Blake'
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
        via: [:employer],
        eager_load: true,
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

    context '#eager_load?' do
      context 'when eager_load is true' do
        it 'returns true' do
          expect(subject.eager_load?).to be true
        end
      end

      context 'when eager_load is not set' do
        let(:options) { { conditions: { last_name: 'Turner' } } }
        it 'returns false' do
          expect(subject.eager_load?).to be false
        end
      end
    end

    context '#eager_args' do
      context 'when eager_load is false' do
        let(:options) { { conditions: { last_name: 'Turner' } } }
        it 'raises error' do
          expect { subject.eager_args }.to raise_error Horza::Errors::InvalidOption
        end
      end

      context 'simple relation' do
        let(:options) do
          {
            id: 999,
            target: :users,
            eager_load: true
          }
        end
        it 'returns target' do
          expect(subject.eager_args).to eq :users
        end
      end

      context '1 via' do
        let(:options) do
          {
            id: 999,
            target: :sports_cars,
            via: [:employer],
            eager_load: true
          }
        end
        it 'returns target as value, via as key' do
          expect(subject.eager_args).to eq(employer: :sports_cars)
        end
      end

      context '2 vias' do
        let(:options) do
          {
            id: 999,
            target: :sports_cars,
            via: [:user, :employer],
            eager_load: true
          }
        end
        it 'returns target as value, final as key, nested in first via' do
          expect(subject.eager_args).to eq(user: { employer: :sports_cars })
        end
      end

      context '3 vias' do
        let(:options) do
          {
            id: 999,
            target: :sports_cars,
            via: [:app, :user, :employer],
            eager_load: true
          }
        end
        it 'returns target as value, final as key, nested in first via' do
          expect(subject.eager_args).to eq(app: { user: { employer: :sports_cars } })
        end
      end
    end
  end
end
