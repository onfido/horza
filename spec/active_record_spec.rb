require 'spec_helper'

if !defined?(ActiveRecord::Base)
  puts "** require 'active_record' to run the specs in #{__FILE__}"
else
  ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

  ActiveRecord::Migration.suppress_messages do
    ActiveRecord::Schema.define(:version => 0) do
      create_table(:employers, force: true) {|t| t.string :name }
      create_table(:users, force: true) {|t| t.string :first_name; t.string :last_name; t.references :employer; }
      create_table(:customers, force: true) {|t| t.string :first_name; t.string :last_name; }
      create_table(:sports_cars, force: true) {|t| t.string :make; t.references :employer; }
      create_table(:dummy_models, force: true) {|t| t.string :key }
      create_table(:other_dummy_models, force: true) {|t| t.string :key }
    end
  end

  module HorzaSpec
    class Employer < ActiveRecord::Base
      has_many :users
      has_many :sports_cars
    end

    class User < ActiveRecord::Base
      belongs_to :employer
    end

    class Customer < ActiveRecord::Base
      validates :last_name, presence: true
    end

    class SportsCar < ActiveRecord::Base
      belongs_to :employer
    end

    class DummyModel < ActiveRecord::Base
      belongs_to :employer
    end

    class OtherDummyModel < ActiveRecord::Base
      belongs_to :employer
    end
  end
end

describe Horza do
  let(:last_name) { 'Turner' }
  let(:adapter) { :active_record }
  let(:user_adapter) { Horza.adapter.new(HorzaSpec::User) }
  let(:customer_adapter) { Horza.adapter.new(HorzaSpec::Customer) }
  let(:employer_adapter) { Horza.adapter.new(HorzaSpec::Employer) }
  let(:sports_car_adapter) { Horza.adapter.new(HorzaSpec::SportsCar) }

  # Reset base config with each iteration
  before { Horza.configure { |config| config.adapter = adapter } }
  after do
    HorzaSpec::User.delete_all
    HorzaSpec::Employer.delete_all
  end

  context '#context_for_entity' do
    it 'Returns correct class' do
      expect(Horza.adapter.context_for_entity(:user)).to eq HorzaSpec::User
    end

    context 'in development mode' do
      before do
        Horza.reset
        Horza.configure do |config|
          config.adapter = adapter
          config.development_mode = true
        end
      end
      after do
        Horza.reset
      end
      it 'Returns correct class' do
        expect(Horza.adapter.context_for_entity(:user)).to eq HorzaSpec::User
      end
    end
  end

  describe '#adapter' do
    let(:user) { HorzaSpec::User.create }

    describe '#get!' do
      context 'when user exists' do
        it 'returns Single entity' do
          expect(user_adapter.get!(user.id).is_a? Horza::Entities::Single).to be true
        end
      end

      context 'when user exists' do
        it 'returns user' do
          expect(user_adapter.get!(user.id).to_h).to eq user.attributes
        end
      end

      context 'when user does not exist' do
        it 'throws error' do
          expect { user_adapter.get!(999) }.to raise_error Horza::Errors::RecordNotFound
        end
      end
    end

    describe '#get' do
      context 'when user does not exist' do
        it 'returns nil' do
          expect(user_adapter.get(999)).to be nil
        end
      end
    end

    describe '#find_first!' do
      context 'when users exist' do
        before do
          3.times { HorzaSpec::User.create(last_name: last_name) }
          2.times { HorzaSpec::User.create(last_name: 'OTHER') }
        end
        it 'returns single Entity' do
          expect(user_adapter.find_first(last_name: last_name).is_a? Horza::Entities::Single).to be true
        end

        it 'returns user' do
          expect(user_adapter.find_first!(last_name: last_name).to_h).to eq HorzaSpec::User.where(last_name: last_name).order('id DESC').first.attributes
        end
      end

      context 'when user does not exist' do
        it 'throws error' do
          expect { user_adapter.find_first!(last_name: last_name) }.to raise_error Horza::Errors::RecordNotFound
        end
      end
    end

    describe '#find_first' do
      context 'when user does not exist' do
        it 'returns nil' do
          expect(user_adapter.find_first(last_name: last_name)).to be nil
        end
      end
    end

    describe '#find_all' do
      context 'when users exist' do
        before do
          3.times { HorzaSpec::User.create(last_name: last_name) }
          2.times { HorzaSpec::User.create(last_name: 'OTHER') }
        end
        it 'returns user' do
          expect(user_adapter.find_all(last_name: last_name).length).to eq 3
        end
      end

      context 'when user does not exist' do
        it 'throws error' do
          expect(user_adapter.find_all(last_name: last_name).empty?).to be true
        end
      end
    end

    describe '#create' do
      context 'when parameters are valid' do
        it 'creates the record' do
          expect { customer_adapter.create(last_name: last_name) }.to change(HorzaSpec::Customer, :count).by(1)
        end

        it 'returns the entity' do
          expect(customer_adapter.create(last_name: last_name).last_name).to eq last_name
        end
      end

      context 'when parameters are invalid' do
        it 'does not create the record' do
          expect { customer_adapter.create }.to change(HorzaSpec::Customer, :count).by(0)
        end

        it 'returns nil' do
          expect(customer_adapter.create).to be nil
        end
      end
    end

    describe '#create!' do
      context 'when parameters are invalid' do
        it 'throws error' do
          expect { customer_adapter.create! }.to raise_error Horza::Errors::RecordInvalid
        end
      end
    end

    describe '#update' do
      let(:customer) { HorzaSpec::Customer.create(last_name: last_name) }

      context 'when parameters are valid' do
        let(:updated_last_name) { 'Smith' }

        it 'returns the updated entity' do
          expect(customer_adapter.update(customer.id, last_name: updated_last_name).last_name).to eq updated_last_name
        end
      end

      context 'when parameters are invalid' do
        it 'returns nil' do
          expect(customer_adapter.update(customer.id, last_name: nil)).to be nil
        end
      end

      context 'when record does not exist' do
        it 'returns nil' do
          expect(customer_adapter.update(999)).to be nil
        end
      end
    end

    describe '#update!' do
      let(:customer) { HorzaSpec::Customer.create(last_name: last_name) }

      context 'when parameters are invalid' do
        it 'throws error' do
          expect { customer_adapter.update!(customer.id, last_name: nil) }.to raise_error Horza::Errors::RecordInvalid
        end
      end

      context 'when record does not exist' do
        it 'returns nil' do
          expect { customer_adapter.update!(999) }.to raise_error Horza::Errors::RecordNotFound
        end
      end
    end

    describe '#delete' do
      let!(:customer) { HorzaSpec::Customer.create(last_name: last_name) }

      context 'when record exists' do
        let(:updated_last_name) { 'Smith' }

        it 'destroys the record' do
          expect { customer_adapter.delete(customer.id) }.to change(HorzaSpec::Customer, :count).by(-1)
        end

        it 'returns true' do
          expect(customer_adapter.delete(customer.id)).to be true
        end
      end

      context 'when record does not exist' do
        it 'returns nil' do
          expect(customer_adapter.delete(999)).to be nil
        end
      end
    end

    describe '#delete!' do
      let(:customer) { HorzaSpec::Customer.create(last_name: last_name) }

      context 'when record does not exist' do
        it 'returns nil' do
          expect { customer_adapter.delete!(999) }.to raise_error Horza::Errors::RecordNotFound
        end
      end
    end

    context '#ancestors' do
      context 'direct relation' do
        let(:employer) { HorzaSpec::Employer.create }
        let!(:user1) { HorzaSpec::User.create(employer: employer) }
        let!(:user2) { HorzaSpec::User.create(employer: employer) }

        context 'parent' do
          it 'returns parent' do
            expect(user_adapter.ancestors(id: user1.id, target: :employer).to_h).to eq employer.attributes
          end
        end

        context 'children' do
          it 'returns children' do
            result = employer_adapter.ancestors(id: employer.id, target: :users)
            expect(result.length).to eq 2
            expect(result.first.is_a? Horza::Entities::Single).to be true
            expect(result.first.to_hash).to eq HorzaSpec::User.order('id DESC').last.attributes
          end
        end

        context 'invalid ancestry' do
          it 'throws error' do
            expect { employer_adapter.ancestors(id: employer.id, target: :user) }.to raise_error Horza::Errors::InvalidAncestry
          end
        end

        context 'valid ancestry with no saved childred' do
          let(:employer2) { HorzaSpec::Employer.create }
          it 'returns empty collection error' do
            expect(employer_adapter.ancestors(id: employer2.id, target: :users).empty?).to be true
          end
        end

        context 'valid ancestry with no saved parent' do
          let(:user2) { HorzaSpec::User.create }
          it 'returns nil' do
            expect(user_adapter.ancestors(id: user2.id, target: :employer)).to be nil
          end
        end
      end

      context 'using via' do
        let(:employer) { HorzaSpec::Employer.create }
        let(:user) { HorzaSpec::User.create(employer: employer) }
        let(:sportscar) { HorzaSpec::SportsCar.create(employer: employer) }

        before do
          employer.sports_cars << sportscar
        end

        it 'returns the correct ancestor' do
          expect(user_adapter.ancestors(id: user.id, target: :sports_cars, via: [:employer]).first).to eq sportscar.attributes
        end
      end
    end
  end

  describe 'Entities' do
    describe 'Collection' do
      let(:members) do
        3.times.map { HorzaSpec::User.create }
      end

      subject { Horza::Entities::Collection.new(members) }

      context '#each' do
        context 'when name is of ancestry type' do
          it 'yields a Get::Entities::Single with each iteration' do
            subject.each do |member|
              expect(member.is_a? Horza::Entities::Single).to be true
            end
          end
        end
      end

      context '#map' do
        context 'when name is of ancestry type' do
          it 'yields a Get::Entities::Single with each iteration, returns array' do
            map = subject.map(&:id)
            expect(map.is_a? Array).to be true
            expect(map.length).to eq 3
          end
        end
      end

      context '#collect' do
        context 'when name is of ancestry type' do
          it 'yields a Get::Entities::Single with each iteration, returns array' do
            map = subject.collect(&:id)
            expect(map.is_a? Array).to be true
            expect(map.length).to eq 3
          end
        end
      end

      context '#singular_entity_class' do
        context 'when singular entity class does not exist' do
        let(:dummy_model) { HorzaSpec::DummyModel.create }

          module TestNamespace
            class DummyModels < Horza::Entities::Collection
            end
          end

          it 'returns Horza::Collection::Single' do
            expect(TestNamespace::DummyModels.new([]).send(:singular_entity_class, dummy_model)).to eq Horza::Entities::Single
          end
        end

        context 'when singular entity class exists' do
          let(:other_dummy_model) { HorzaSpec::OtherDummyModel.create }

          module TestNamespace
            class OtherDummyModels < Horza::Entities::Collection
            end

            class OtherDummyModel < Horza::Entities::Single
            end
          end

          it 'returns the existing singular class' do
            expect(TestNamespace::OtherDummyModels.new([]).send(:singular_entity_class, other_dummy_model)).to eq TestNamespace::OtherDummyModel
          end
        end
      end
    end
  end
end
