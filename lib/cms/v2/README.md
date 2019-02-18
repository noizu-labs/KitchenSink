CMS 2.0
==============

# What is it?
The Content Management System version 2.0 provides a framework for tracking any user defined elixir scaffolding v2 entities
in a general CMS framework. It additionally exposes common json based APIs for editing CMS entries regardless of type although
some custom logic will be needed to provide appropriate client side type editors for various cms types. 

# How does it work
 
The system defines a protocol that entities must implement to enable version tracking, tag lookup etc. and repo behaviour 
hooks that should be invoked to insure that version records, etc. are injected and removed as expected. 

The CMS 2.0 system additionally provides some basic CMS types to help users get started quickly, Files, Posts, Images.
 
As entities are persisted using the elixir scaffolding framework additional book keeping is tracked to allow the cms system to 
look up records of any type. 
 
# Example 

Let's assume we want to track vehicle records as top level CMS entities.

1. First we define our entity, repo and database in the usual manner. 
    
    ```elixir
    
    defmodule MyProject.VehicleEntity do 
    
        @vsn 1.0
        @type t :: %__MODULE__{
                     identifier: integer,                 
                     name: String.t,
                     description: String.t,
                     make: String.t,
                     model: String.t,                 
                     vsn: float
                   }
      
        defstruct [
          identifier: nil,
          name: nil,
          description: nil,
          make: nil,
          model: nil,
          vsn: @vsn
        ]
        
          use Noizu.Scaffolding.V2.EntityBehaviour,
              sref_module: "vehicle"
    end
    
    defmodule MyProject.VehicleRepo do 
         use Noizu.Scaffolding.V2.RepoBehaviour
    end
    
    ``` 
2. Protocol Setup
3. Behavior Call Backs. 

# Behind the scenes. 
As entities are created, updated, and deleted CMS book keeping records are automatically updated. 
These additional book keeping records allow use to access entities using the core CMS repo regardless of type.
And couples with the cms protocol allow us to look up exact versions of tracked entities regardless of type. 
with out requiring full duplicate copies to be persisted (for very large user defined types) 
