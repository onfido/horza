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
user = Horza.adapt(User)

# Examples
user.get(id) # Find by id - Return nil on fail
user.get!(id) # Find by id - Error on fail
user.find_first(options) # Find 1 user - Orders by id desc by default - Return nil on fail
user.find_first!(options) # Find 1 user - Orders by id desc by default - Error nil on fail
user.find_all(options) # Find all users that match parameters
user.create(options) # Create record - return nil on fail
user.create!(options) # Create record - raise error on fail
user.update(options) # Update record - return nil on fail
user.update!(options) # Update record - raise error on fail
user.delete(options) # Delete record - return nil on fail
user.delete!(options) # Delete record - raise error on fail
user.association(target: :employer, via: []) # Traverse association

conditions = { last_name: 'Turner' }

# Ordering
user.find_all(conditions: conditions, order: { last_name: :desc })

# Limiting
user.find_all(conditions: conditions, limit: 20)

# Offset
user.find_all(conditions: conditions, offset: 50)

# Eager loading associations
employer.association(target: :users, eager_load: true)
```

## Options

**Base Options**

Key | Type | Details
--- | ---- | -------
`conditions` | Hash | Key value pairs for the query
`order` | Hash | { `field` => `:asc`/`:desc` }
`limit` | Integer | Number of records to return
`offset` | Integer | Number of records to offset
`id` | Integer | The id of the root object (associations only)
`target` | Symbol | The target of the association - ie. employer.users would have a target of :users (associations only)
`eager_load` | Boolean | Whether to eager_load the association (associations only)

**Association Options**

Key | Type | Details
--- | ---- | -------
`id` | Integer | The id of the root object
`target` | Symbol | The target of the association - ie. employer.users would have a target of :users
`eager_load` | Boolean | Whether to eager_load the association

## Outputs

Horza queries return very dumb vanilla entities instead of ORM response objects.
Singular entities are simply hashes that allow both hash and dot notation, and binary helpers.
Collection entities behave like arrays.

```ruby
# Singular Entity
result = user.find_first(first_name: 'Blake')

result # => {"id"=>1, "first_name"=>"Blake", "last_name"=>"Turner", "employer_id"=>1}
result.class.name # => "Horza::Entities::Single"
result['id'] # => 1
result.id # => 1
result.id? # => true

# Collection Entity
result = user.find_all(last_name: 'Turner')

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
