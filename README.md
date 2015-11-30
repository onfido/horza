# Horza

Horza is a library for decoupling your application from the ORM you have implemented.

**ActiveRecord Example**
```ruby
# Get Adapter for your ORM Object
horza_user = Horza.adapt(User)

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

# Special case: create a child record when mass-assignment is disabled for parent instance_methods
# klass is a symbol version of your model name, ie Employer is :employer, SportsCar is :sports_car
parent = { id: parent_id, klass: :employer }

user.create_as_child(parent, options) # Create record - return nil on fail
user.create_as_child!(parent, options) # Create record - raise error on fail

# With args
conditions = { last_name: 'Turner' }

# Ordering
user.find_all(conditions: conditions, order: { last_name: :desc })

# Limiting
user.find_all(conditions: conditions, limit: 20)

# Offset
user.find_all(conditions: conditions, offset: 50)

# Eager loading associations
employer.association(target: :users, eager_load: true)

# Joins are slightly more complex
join_params = {
  with: :employers,
  on: { employer_id: :id }, # field for adapted model => field for join model
  fields: {
    users: [:first_name, :last_name, :email],
    employers: [:company_name, :address, :phone],
  },
  conditions: {
    users: { last_name: 'Turner'  },
    employers: { company_name: 'Corporation ltd.' }
  },
  limit: 20,
  offset: 5,
}
horza_user.join(join_params)

# You can join on multiple fields by passing an array
join_params = {
  with: :employers,
  on: [
    { employer_id: :id }, # field for adapted model => field for join model
    { email: :email }, # field for adapted model => field for join model
  ]
}
horza_user.join(join_params)

# You can also alias field names
join_params = {
  with: :employers,
  on: [
    { employer_id: :id }, # field for adapted model => field for join model
    { email: :email }, # field for adapted model => field for join model
  ],
  fields: {
    users: [:id, :last_name, :email],
    employers: [{id: :employer_id}], # Fieldname in db => alias for output
  },
}
horza_user.join(join_params)
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

## Active Model Semantics

The returned entity for ActiveRecord adapter now include ActiveModel semantics. This type of
entity SingleWithActiveModel can work with rails form helper and the submitted params will be
grouped under params[:horza_entities_single_with_active_model].


## Config

Horza uses ORM-specific adapters to decouple Ruby apps from their ORMS.
Currently only the ActiveRecord  adapter is supported.

**Configure Adapter**
```ruby
Horza.configure do |config|
  config.adapter = :active_record
end
```

**Constant paths**
Some of the operations in Horza involve resolving constants from the given options. 
Consider the following snippet from above: 
```ruby
user.create_as_child(id: parent_id, klass: :employer, options)
```
Horza by default will return the <tt>Employer</tt> class if it has already been loaded.    
In environments where constants are lazy-loaded - such as in Rails -  you would need to explicitly configure paths that Horza should look up when trying to resolve constants.

For instance in a Rails app your models are typically found in the ```app/models``` directory,
so you would need to add it to the constant_paths.

```ruby
# config/initializers/horza.rb
Horza.configure do |config|
 # config.adapter = :active_record
  config.constant_paths += [Rails.root.join("app/models").to_s]
end
```
**Note** The file paths added to _constant_paths_ would also need to be added to your app's _autoload_paths_ for the constants to be loaded dynamically. 

**Model Namespaces**

Horza will attempt to resolve namespaced constants where possibble provided the following caveats are met:

- The file names added to the constant_paths and the constants defined in them follow the Rails naming conventions.
- There aren't multiple files with the same base name in a given directory in the constant paths.

To illustrate the second point consider the following directory structure:
```ruby
# app/models/employer.rb
class Employer < ActiveRecord::Base
  has_many :users
end

# app/models/my_namespace/employer.rb
module MyNamespace
  class Employer < ActiveRecord::Base
    has_many :users
  end
end

# In this case Horza will load the top level <tt>Employer</tt> model.
```

**Resetting config** _(At runtime or on app boot)_
```ruby
Horza.reset
```
