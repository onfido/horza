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
user = User.create(user_params)
horza_user = Horza.adapter.new(user)

# Examples
horza_user.get(id) # Find by id - Return nil on fail
horza_user.get!(id) # Find by id - Error on fail
horza_user.find_first(params) # Find 1 user - Orders by id desc by default - Return nil on fail
horza_user.find_first!(params) # Find 1 user - Orders by id desc by default - Error nil on fail
horza_user.find_all(params) # Find all users that match parameters
horza_user.ancestors(target: :employer, via: []) # Traverse relations
```

## Outputs

Horza queries return very dumb vanilla entities instead of ORM response objects.
Singular entities are simply hashes that allow both hash and dot notation, and binary helpers.
Collection entities behave like arrays.

```ruby
# Singular Entity
result = horza_user.find_first(first_name: 'Blake') # => {"id"=>1, "first_name"=>"Blake", "last_name"=>"Turner", "employer_id"=>nil}
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
result.first # => {"id"=>1, "first_name"=>"Blake", "last_name"=>"Turner", "employer_id"=>nil}
result.last # => {"id"=>1, "first_name"=>"Blake", "last_name"=>"Turner", "employer_id"=>nil}
result[0] # => {"id"=>1, "first_name"=>"Blake", "last_name"=>"Turner", "employer_id"=>nil}
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
