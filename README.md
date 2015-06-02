# Horza

Horza is a library for decoupling your application from the ORM you have implemented.

## Inputs

Horza uses ORM-specific adapters to decouple Ruby apps from their ORMS.

**Configure Adapter**
```ruby
Horza.configure do |config|
  config.adapter = :active_record
end
```

**Get Adapter for your ORM Object**
```ruby
# ActiveRecord Example
# Don't worry, We don't actually call things horza_users in our codebase, this is just for emphasis
horza_user = Horza.adapt(User)

# Examples
horza_user.get(id) # Find by id - Return nil on fail
horza_user.get!(id) # Find by id - Error on fail
horza_user.find_first(params) # Find 1 user - Orders by id desc by default - Return nil on fail
horza_user.find_first!(params) # Find 1 user - Orders by id desc by default - Error nil on fail
horza_user.find_all(params) # Find all users that match parameters
horza_user.create(params) # Create record - return nil on fail
horza_user.create!(params) # Create record - raise error on fail
horza_user.update(params) # Update record - return nil on fail
horza_user.update!(params) # Update record - raise error on fail
horza_user.delete(params) # Delete record - return nil on fail
horza_user.delete!(params) # Delete record - raise error on fail
horza_user.ancestors(target: :employer, via: []) # Traverse relations
```

## Outputs

Horza queries return very dumb vanilla entities instead of ORM response objects.
Singular entities are simply hashes that allow both hash and dot notation, and binary helpers.
Collection entities behave like arrays.

```ruby
# Singular Entity
result = horza_user.find_first(first_name: 'Blake')

result # => {"id"=>1, "first_name"=>"Blake", "last_name"=>"Turner", "employer_id"=>1}
result.class.name # => "Horza::Entities::Single"
result['id'] # => 1
result.id # => 1
result.id? # => true

# Collection Entity
result = horza_user.find_all(last_name: 'Turner')

result.class.name # => "Horza::Entities::Collection"
result.length # => 1
result.size # => 1
result.empty? # => false
result.present? # => true
result.first # => {"id"=>1, "first_name"=>"Blake", "last_name"=>"Turner", "employer_id"=>1}
result.last # => {"id"=>2, "first_name"=>"Morgan", "last_name"=>"Bruce", "employer_id"=>2}
result[0] # => {"id"=>1, "first_name"=>"Blake", "last_name"=>"Turner", "employer_id"=>1}
```

## Custom Entities

You can define your own entities by making them subclasses of [Horza entities](https://github.com/onfido/horza/tree/master/lib/horza/entities). Just make sure they have the same class name as your ORM classes. Horza will automatically detect custom entities and use them for output.

```ruby
module CustomEntities
  # Collection Entity
  class Users < Horza::Entities::Collection
  end

  # Singular Entity
  class User < Horza::Entities::Single
  end
end
```
