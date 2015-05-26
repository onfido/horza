require 'spec_helper'

if !defined?(ActiveRecord::Base)
  puts "** require 'active_record' to run the specs in #{__FILE__}"
else
  ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

  ActiveRecord::Migration.suppress_messages do
    ActiveRecord::Schema.define(:version => 0) do
      create_table(:employers, force: true) {|t| t.string :name }
      create_table(:users, force: true) {|t| t.string :first_name; t.string :last_name; t.references :employer; }
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
  let(:employer_adapter) { Horza.adapter.new(HorzaSpec::Employer) }
  let(:sports_car_adapter) { Horza.adapter.new(HorzaSpec::SportsCar) }

  # Reset base config with each iteration
  before { Horza.configure { |config| config.adapter = adapter } }
  after do
    HorzaSpec::User.delete_all
    HorzaSpec::Employer.delete_all
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
          expect { user_adapter.get!(999) }.to raise_error ActiveRecord::RecordNotFound
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
          expect { user_adapter.find_first!(last_name: last_name) }.to raise_error ActiveRecord::RecordNotFound
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
