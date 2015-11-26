# Helper module to allow other libraries to access the global
# Horza configuration instance and dispatch methods accordingly. 
module Horza
  module SharedConfig  
    DelegatedMethods = %w(
      configuration configure reset constant_paths 
      clear_constant_paths adapter adapter=
    )
    
    DelegatedMethods.each do |_meth_|
      module_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{_meth_}(*args, &blk)
          Horza.send(:'#{_meth_}', *args, &blk)
        end
      RUBY
    end
    
  end
end