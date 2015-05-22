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

  context '#result' do
    before { Horza.configure { |config| config.adapter = :active_record } }
    after { Horza.reset }
    it 'returns dynamically generated class that inherits from adapter class' do
      expect(Horza.result.superclass).to eq Horza::Adapters::ActiveRecord
    end
  end

  describe 'Entities' do
    context '#const_missing' do
      it 'dynamically defines classes' do
        expect { Horza::Entities.const_get('NewClass') }.to_not raise_error
      end
    end

    describe 'Collection' do
      context '#singular_entity_class' do
        context 'when singular entity class does not exist' do
          module TestNamespace
            class GetUsers < Horza::Entities::Collection
            end
          end

          it 'returns Horza::Collection::Single' do
            expect(TestNamespace::GetUsers.new([]).send(:singular_entity_class)).to eq Horza::Entities::Single
          end
        end

        context 'when singular entity class exists' do
          module TestNamespace
            class GetEmployers < Horza::Entities::Collection
            end

            class GetEmployer < Horza::Entities::Single
            end
          end

          it 'returns the existing singular class' do
            expect(TestNamespace::GetEmployers.new([]).send(:singular_entity_class)).to eq TestNamespace::GetEmployer
          end
        end
      end
    end
  end
end
