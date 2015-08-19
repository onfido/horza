require 'spec_helper'

if !defined?(ActiveRecord::Base)
  puts "** require 'active_record' to run the specs in #{__FILE__}"
else
  ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

  ActiveRecord::Migration.suppress_messages do
    ActiveRecord::Schema.define(:version => 0) do
      create_table(:employers, force: true) {|t| t.string :name; t.string :boss_email }
      create_table(:users, force: true) {|t| t.string :first_name; t.string :last_name; t.string :email; t.references :employer; }
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

  class SimpleRecord < ActiveRecord::Base
  end

  module Lazy
    class LazyRecord  < ActiveRecord::Base
    end
  end
end

describe Horza do
  let(:last_name) { 'Turner' }
  let(:adapter) { :active_record }
  let(:user_adapter) { Horza.adapt(HorzaSpec::User) }
  let(:customer_adapter) { Horza.adapt(HorzaSpec::Customer) }
  let(:employer_adapter) { Horza.adapt(HorzaSpec::Employer) }
  let(:sports_car_adapter) { Horza.adapt(HorzaSpec::SportsCar) }

  # Reset base config with each iteration
  before { Horza.configure { |config| config.adapter = adapter } }
  after do
    HorzaSpec::User.delete_all
    HorzaSpec::Employer.delete_all
    HorzaSpec::Customer.delete_all
    HorzaSpec::SportsCar.delete_all
  end

  context '#context_for_entity' do
    context 'when model exists' do
      it 'Returns correct class' do
        expect(Horza.adapter.context_for_entity(:simple_record).to_s).to eq 'SimpleRecord'
      end
    end

    context 'when model exists in namespace' do
      it 'Returns correct class' do
        expect(Horza.adapter.context_for_entity(:user)).to eq HorzaSpec::User
      end
    end

    context 'when model does not exist' do
      it 'throws error class' do
        expect { Horza.adapter.context_for_entity(:not_a_thing) }.to raise_error Horza::Errors::NoContextForEntity
      end
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

      context 'when model exists' do
        it 'Returns correct class' do
          expect(Horza.adapter.context_for_entity(:simple_record).to_s).to eq 'SimpleRecord'
        end
      end

      context 'when model does not exist' do
        it 'throws error class' do
          expect { Horza.adapter.context_for_entity(:not_a_thing) }.to raise_error Horza::Errors::NoContextForEntity
        end
      end

      context 'when model exists but has been lazy loaded' do
        context 'without namespace' do
          before do
            Object.send(:remove_const, :SimpleRecord)
          end

          it 'lazy loads' do
            expect(Horza.adapter.context_for_entity(:simple_record).to_s).to eq 'SimpleRecord'
          end
        end

        context 'within namespace' do
          before do
            Lazy.send(:remove_const, :LazyRecord)
            Object.send(:remove_const, :Lazy)
          end

          it 'lazy loads' do
            expect(Horza.adapter.context_for_entity(:lazy_record).to_s).to eq 'Lazy::LazyRecord'
          end
        end
      end
    end
  end

  describe '#adapt' do
    subject { Horza.adapt(HorzaSpec::User) }
    it 'returns the adaptor class' do
      expect(subject.is_a? Horza::Adapters::ActiveRecord).to be true
    end
    it 'sets the model as context' do
      expect(subject.context).to eq HorzaSpec::User
    end
  end

  describe 'Queries' do
    let(:user) { HorzaSpec::User.create }
    let(:single_entity_klass) { Horza::Entities::Single }

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
          expect(user_adapter.find_first(conditions: { last_name: last_name }).is_a? Horza::Entities::Single).to be true
        end

        it 'returns user' do
          expect(user_adapter.find_first!(conditions: { last_name: last_name }).to_h).to eq HorzaSpec::User.where(last_name: last_name).order('id DESC').first.attributes
        end
      end

      context 'when user does not exist' do
        it 'throws error' do
          expect { user_adapter.find_first!(conditions: { last_name: last_name }) }.to raise_error Horza::Errors::RecordNotFound
        end
      end
    end

    describe '#find_first' do
      context 'when user does not exist' do
        it 'returns nil' do
          expect(user_adapter.find_first(conditions: { last_name: last_name })).to be nil
        end
      end
    end

    describe '#find_all' do
      let(:conditions) { { last_name: last_name } }
      let(:options) { { conditions: conditions } }

      context 'when users exist' do
        before do
          3.times { HorzaSpec::User.create(conditions) }
          2.times { HorzaSpec::User.create(last_name: 'OTHER') }
        end
        it 'returns user' do
          expect(user_adapter.find_all(options).length).to eq 3
        end

        context 'with limit' do
          it 'limits response' do
            expect(user_adapter.find_all(options.merge(limit: 2)).length).to eq 2
          end
        end

        context 'with offset' do
          let(:total) { 20 }
          let(:offset) { 7 }
          before do
            total.times { HorzaSpec::User.create(last_name: 'Smith') }
          end
          it 'offsets response' do
            expect(user_adapter.find_all(conditions: { last_name: 'Smith' }, offset: offset).length).to eq total - offset
          end
        end
      end

      context 'when user does not exist' do
        it 'throws error' do
          expect(user_adapter.find_all(options).empty?).to be true
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

    describe '#create_as_child' do
      let(:employer) { HorzaSpec::Employer.create }
      let(:parent) do
        {
          id: employer.id,
          klass: :employer
        }
      end
      let(:action) { user_adapter.create_as_child(parent, last_name: last_name) }

      context 'when parameters are valid' do
        it 'creates the record' do
          expect { action }.to change(HorzaSpec::User, :count).by(1)
        end

        it 'returns the entity' do
          expect(action.last_name).to eq last_name
          expect(action.employer_id).to eq employer.id
        end
      end

      context 'when parameters are invalid' do
        let(:parent) do
          {
            id: 999,
            klass: :employer
          }
        end

        it 'does not create the record' do
          expect { action }.to change(HorzaSpec::User, :count).by(0)
        end

        it 'returns nil' do
          expect(action).to be nil
        end
      end
    end

    describe '#create_as_child!' do
      let(:employer) { HorzaSpec::Employer.create }
      let(:action) { user_adapter.create_as_child!(parent, last_name: last_name) }

      context 'when parameters are invalid' do
        let(:parent) do
          {
            id: 999,
            klass: :employer
          }
        end

        it 'throws error' do
          expect { action }.to raise_error Horza::Errors::RecordNotFound
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

    context '#association' do
      context 'direct relation' do
        let(:employer) { HorzaSpec::Employer.create }
        let!(:user1) { HorzaSpec::User.create(employer: employer) }
        let!(:user2) { HorzaSpec::User.create(employer: employer) }

        context 'parent' do
          it 'returns parent' do
            expect(user_adapter.association(id: user1.id, target: :employer).to_h).to eq employer.attributes
          end
        end

        context 'children' do
          it 'returns children' do
            result = employer_adapter.association(id: employer.id, target: :users)
            expect(result.length).to eq 2
            expect(result.first.is_a? Horza::Entities::Single).to be true
            expect(result.first.to_hash).to eq HorzaSpec::User.order('id DESC').first.attributes
          end
        end

        context 'invalid ancestry' do
          it 'throws error' do
            expect { employer_adapter.association(id: employer.id, target: :user) }.to raise_error Horza::Errors::InvalidAncestry
          end
        end

        context 'valid ancestry with no saved childred' do
          let(:employer2) { HorzaSpec::Employer.create }
          it 'returns empty collection error' do
            expect(employer_adapter.association(id: employer2.id, target: :users).empty?).to be true
          end
        end

        context 'valid ancestry with no saved parent' do
          let(:user2) { HorzaSpec::User.create }
          it 'returns nil' do
            expect(user_adapter.association(id: user2.id, target: :employer)).to be nil
          end
        end

        context 'with options' do
          let(:turner_total) { 25 }
          let(:other_total) { 20 }
          let(:conditions) { { last_name: 'Turner' } }

          before do
            turner_total.times { employer.users << HorzaSpec::User.create(conditions.merge(employer: employer)) }
            other_total.times { employer.users << HorzaSpec::User.create(employer: employer) }
          end

          context 'limit' do
            it 'limits response' do
              expect(employer_adapter.association(id: employer.id, target: :users, limit: 10).length).to eq 10
            end
          end

          context 'conditions' do
            it 'only returns matches' do
              expect(employer_adapter.association(id: employer.id, target: :users, conditions: conditions).length).to eq turner_total
            end
          end

          context 'offset' do
            it 'offsets response' do
              expect(employer_adapter.association(id: employer.id, target: :users, conditions: conditions, offset: 10).length).to eq turner_total - 10
            end
          end

          context 'order' do
            it 'orders response' do
              horza_response =  employer_adapter.association(id: employer.id, target: :users, conditions: conditions, order: { id: :asc })
              ar_response = HorzaSpec::User.where(conditions).order('id asc')
              expect(horza_response.first.id).to eq ar_response.first.id
              expect(horza_response.last.id).to eq ar_response.last.id
            end
          end

          context 'eager_load' do
            context 'simple' do
              it 'works as expected' do
                horza_response =  employer_adapter.association(id: employer.id, target: :users, conditions: conditions, order: { id: :asc }, eager_load: true)
                ar_response = HorzaSpec::User.where(conditions).order('id asc')
                expect(horza_response.first.id).to eq ar_response.first.id
                expect(horza_response.last.id).to eq ar_response.last.id
              end
            end
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
          expect(user_adapter.association(id: user.id, target: :sports_cars, via: [:employer]).first).to eq sportscar.attributes
        end

        context 'with eager loading' do
          it 'works as expected' do
            horza_response =  user_adapter.association(id: user.id, target: :sports_cars, via: [:employer], order: { id: :asc }, eager_load: true)
            expect(horza_response.first.id).to eq sportscar.id
          end
        end
      end
    end

    context '#join' do
      let(:simple) do
        {
          with: :employers,
          on: { employer_id: :id } # field for adapted model => field for join model
        }
      end

      let(:complex_predicate) do
        {
          with: :employers,
          on: [
            { employer_id: :id }, # field for adapted model => field for join model
            { email: :boss_email }, # field for adapted model => field for join model
          ],
          fields: {
            users: [:id, :email],
            employers: [:boss_email]
          }
        }
      end

      let(:fields) do
        {
          fields: {
            users: [:id, :first_name, :last_name],
            employers: [{id: :employer_id}, :name]
          }
        }.merge(simple)
      end

      let(:conditions) do
        {
          conditions: {
            users: { last_name: 'Turner'  },
            employers: { name: 'Corporation ltd.' }
          }
        }.merge(fields)
      end

      context 'without conditions' do
        context 'when one join record exists' do
          let!(:employer) { HorzaSpec::Employer.create(name: 'Corporation ltd.', boss_email: 'boss@boss.com') }
          let!(:user) { HorzaSpec::User.create(employer: employer, first_name: 'John', last_name: 'Turner', email: 'email@email.com') }

          context 'without fields' do
            it 'returns joined record' do
              result = user_adapter.join(simple)
              expect(result.length).to eq 1

              expect(result.first.first_name).to eq user.first_name
              expect(result.first.last_name).to eq user.last_name
              expect(result.first.email).to eq user.email
              expect(result.first.boss_email).to eq employer.boss_email
              expect(result.first.name).to eq employer.name
            end
          end

          context 'with fields' do
            it 'returns joined record and the specified fields' do
              result = user_adapter.join(fields)
              expect(result.length).to eq 1

              record = result.first

              expect(record.id).to eq user.id
              expect(record.first_name).to eq user.first_name
              expect(record.last_name).to eq user.last_name
              expect(record.name).to eq employer.name
              expect(record.employer_id).to eq employer.id

              expect(record.respond_to?(:email)).to be false
            end
          end

          context 'complex predicate' do
            let!(:match_user) { HorzaSpec::User.create(employer: employer, first_name: 'John', last_name: 'Turner', email: 'boss@boss.com') }
            let!(:match_user2) { HorzaSpec::User.create(employer: employer, first_name: 'Helen', last_name: 'Jones', email: 'boss@boss.com') }
            it 'returns joined records and the specified fields' do
              result = user_adapter.join(complex_predicate)
              expect(result.length).to eq 2

              expect(result.first.id).to eq match_user.id
              expect(result.first.email).to eq match_user.email
              expect(result.first.boss_email).to eq employer.boss_email
            end

          end
        end

        context 'when no join record exists' do
          let!(:employer) { HorzaSpec::Employer.create(name: 'Corporation ltd.') }
          let!(:user) { HorzaSpec::User.create(employer_id: 9999, first_name: 'John', last_name: 'Turner', email: 'email@email.com') }

          it 'returns an empty collection' do
            result = user_adapter.join(simple)
            expect(result.length).to eq 0
          end
        end

        context 'when multiple join records exists' do
          let!(:employer) { HorzaSpec::Employer.create(name: 'Corporation ltd.') }
          let!(:user) { HorzaSpec::User.create(employer: employer, first_name: 'John', last_name: 'Turner', email: 'email@turner.com') }
          let!(:user2) { HorzaSpec::User.create(employer: employer, first_name: 'Adam', last_name: 'Boots', email: 'email@boots.com') }
          let!(:user3) { HorzaSpec::User.create(employer: employer, first_name: 'Tim', last_name: 'Socks', email: 'email@socks.com') }

          it 'returns an empty collection' do
            result = user_adapter.join(simple)
            expect(result.length).to eq 3
          end
        end
      end

      context 'with conditions' do
        let!(:employer) { HorzaSpec::Employer.create(name: 'Corporation ltd.') }
        let!(:employer2) { HorzaSpec::Employer.create(name: 'BigBucks ltd.') }
        let!(:user) { HorzaSpec::User.create(employer: employer, first_name: 'John', last_name: 'Turner', email: 'email@turner.com') }
        let!(:user2) { HorzaSpec::User.create(employer: employer, first_name: 'Adam', last_name: 'Boots', email: 'email@boots.com') }
        let!(:user3) { HorzaSpec::User.create(employer: employer2, first_name: 'Tim', last_name: 'Socks', email: 'email@socks.com') }

        it 'returns only the joins that match the conditions' do
          result = user_adapter.join(conditions)
          expect(result.length).to eq 1
          expect(result.first.id).to eq user.id
        end
      end

      context 'limits/offset' do
        let!(:employer) { HorzaSpec::Employer.create(name: 'Corporation ltd.') }
        let!(:employer2) { HorzaSpec::Employer.create(name: 'BigBucks ltd.') }
        let!(:user) { HorzaSpec::User.create(employer: employer, first_name: 'John', last_name: 'Turner', email: 'email@turner.com') }
        let!(:user2) { HorzaSpec::User.create(employer: employer, first_name: 'Adam', last_name: 'Turner', email: 'email@boots.com') }
        let!(:user3) { HorzaSpec::User.create(employer: employer2, first_name: 'Tim', last_name: 'Socks', email: 'email@socks.com') }

        it 'limits the joins that match the conditions' do
          params = conditions.merge(limit: 1)
          result = user_adapter.join(params)
          expect(result.length).to eq 1
          expect(result.first.id).to eq user.id
        end

        it 'offsets the joins that match the conditions' do
          params = conditions.merge(offset: 1)
          result = user_adapter.join(params)
          expect(result.length).to eq 1
          expect(result.first.id).to eq user2.id
        end
      end
    end
  end

  describe 'Entities' do
    describe 'Collection' do
      let(:members) do
        3.times.map { HorzaSpec::User.create }
      end

      let(:single_entity_klass) { Horza::Entities::SingleWithActiveModel }

      subject { Horza::Entities::Collection.new(members) }

      context '#each' do
        context 'when name is of ancestry type' do
          it 'yields a Horza::Entities::Single with each iteration' do
            subject.each do |member|
              expect(member.is_a? single_entity_klass).to be true
            end
          end
        end
      end

      context '#map' do
        context 'when name is of ancestry type' do
          it 'yields a Horza::Entities::Single with each iteration, returns array' do
            map = subject.map(&:id)
            expect(map.is_a? Array).to be true
            expect(map.length).to eq 3
          end
        end
      end

      context '#collect' do
        context 'when name is of ancestry type' do
          it 'yields a Horza::Entities::Single with each iteration, returns array' do
            map = subject.collect(&:id)
            expect(map.is_a? Array).to be true
            expect(map.length).to eq 3
          end
        end
      end

      context '#pop' do
        context 'when name is of ancestry type' do
          it 'returns the last collection item as a Horza::Entities::Single' do
            entity = subject.pop
            expect(entity.is_a? single_entity_klass).to be true
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
            expect(TestNamespace::DummyModels.new([]).send(:singular_entity, dummy_model).is_a? single_entity_klass).to be true
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
            expect(TestNamespace::OtherDummyModels.new([]).send(:singular_entity, other_dummy_model).is_a? TestNamespace::OtherDummyModel).to be true
          end
        end
      end
    end
  end
end
