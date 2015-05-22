# Horza

Horza is a shapeshifter that provides common inputs and outputs for your ORM.

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
user.get! # Find by id - Error on fail
user.find_first # Find 1 user - Orders by id desc by default
user.find_all # Find all users that match parameters
user.ancestors # Traverse relations
user.to_hash # Return attributes hash
```

## Outputs

Horza provides vanilla entities than can be used to replace ORM response objects.

```ruby
# Entity for a single object
# ActiveRecord Example
user = User.create(user_params)
horza_user = Horza.adapter.new(user)

# Execute Query
horza_user.find_first(first_name: 'Blake')

Horza.single(horza_user.to_hash)
```
