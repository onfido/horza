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
        it 'returns user' do
          expect(user_adapter.get!(user.id).result).to eq user
        end
      end

      context 'when user does not exist' do
        it 'throws error' do
          expect { user_adapter.get!(999) }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end

    describe '#find_all' do
      context 'when users exist' do
        before { 3.times { HorzaSpec::User.create(last_name: last_name) } }
        it 'returns user' do
          expect(user_adapter.find_all(last_name: last_name).result.length).to eq 3
        end
      end

      context 'when user does not exist' do
        it 'throws error' do
          expect(user_adapter.find_all(last_name: last_name).result.empty?).to be true
        end
      end
    end

    describe '#find_first' do
      context 'when users exist' do
        before { 3.times { HorzaSpec::User.create(last_name: last_name) } }
        it 'returns user' do
          expect(user_adapter.find_first(last_name: last_name).result.is_a? HorzaSpec::User).to be true
        end
      end

      context 'when user does not exist' do
        it 'throws error' do
          expect { user_adapter.find_first(last_name: last_name) }.to raise_error ActiveRecord::RecordNotFound
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
            expect(user_adapter.ancestors(id: user1.id, result_key: :employer).result).to eq employer
          end
        end

        context 'children' do
          it 'returns children' do
            result = employer_adapter.ancestors(id: employer.id, result_key: :users).result
            expect(result.length).to eq 2
            expect(result.first.is_a? HorzaSpec::User).to be true
          end
        end

        context 'invalid ancestry' do
          it 'throws error' do
            expect { employer_adapter.ancestors(id: employer.id, result_key: :user) }.to raise_error Horza::Errors::InvalidAncestry
          end
        end

        context 'valid ancestry with no saved childred' do
          let(:employer2) { HorzaSpec::Employer.create }
          it 'returns empty collection error' do
            expect(employer_adapter.ancestors(id: employer2.id, result_key: :users).result.empty?).to be true
          end
        end

        context 'valid ancestry with no saved parent' do
          let(:user2) { HorzaSpec::User.create }
          it 'returns nil' do
            expect(user_adapter.ancestors(id: user2.id, result_key: :employer).result).to be nil
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
          expect(user_adapter.ancestors(id: user.id, result_key: :sports_cars, via: [:employer]).result.first).to eq sportscar
        end
      end
    end

    describe '#to_hash' do
      context 'when no query has been made' do
        it 'throws error' do
          expect { user_adapter.to_hash }.to raise_error Horza::Errors::QueryNotYetPerformed
        end
      end

      context 'when query has returned a single record' do
        it 'returns user attributes' do
          expect(user_adapter.get!(user.id).to_hash).to eq user.attributes
        end
      end

      context 'when query has returned a collection of records' do
        it 'throws error' do
          expect { user_adapter.find_all(last_name: last_name).to_hash }.to raise_error Horza::Errors::CannotGetHashFromCollection
        end
      end
    end
  end
end
