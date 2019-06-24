# Proteus

Proteus is a wrapper application around Terraform that facilitates management of resources.

The incentive for a Terraform wrapper is that Terraform in its current state cannot iteratively
declare module includes in a loop. Writing all the module includes manually would inevitably lead to
large manifest files.
These files would be difficult if not impossible to maintain without human error.

Furthermore, the abstraction from Terraform that the configuration format of the wrapper provides, enables
people who are not familiar with Terraform's configuration format to configure resources easily.

## Setup

### Requirements
* Ruby >= 2.5.5
* Terraform >= 0.11.14
* AWS IAM profile credentials

### Prerequisites

#### Install Terraform
```
brew install terraform
```

If you would still like to use Terraform `< 0.12`:
```
# Install Terraform 0.11.14 (for Homebrew users)
mkdir -p /usr/local/Cellar/terraform/0.11.14/bin \
  && curl -o /tmp/terraform.zip "https://releases.hashicorp.com/terraform/0.11.14/terraform_0.11.14_darwin_amd64.zip" \
  && unzip -o /tmp/terraform.zip -d "/usr/local/Cellar/terraform/0.11.14/bin" \
  && rm -f /tmp/terraform.zip \
  && brew switch terraform 0.11.14
  && brew pin terraform
```

#### Install proteus
```
gem install dh-proteus
```

#### Set up proteus root path
```
cd /path/to/your/repository

# initialize a project scaffolding
proteus init
```

The above directory will be a valid `proteus` root. Should you want to be able to call `proteus` from anywhere on your system,
set it as an environment variable like so:
```
export PROTEUS_ROOT=/path/to/your/repository
```

#### AWS profile configuration
Create profiles and credentials for your environments:

`$HOME/.aws/config`:

```
[profile staging]
region = eu-west-1
[profile production]
region = eu-west-1
```

`$HOME/.aws/credentials`:
```
[staging]
aws_access_key_id = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_ACCESS_KEY

[production]
aws_access_key_id = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
```

#### State
Terraform state is managed remotely in an S3 bucket. Make sure to create that bucket and enable versioning.

### Customize configuration
Having set up all of the above, it is time to modify the configuration to your needs.

```
  vim $PROTEUS_ROOT/config/config.yaml
```

Should the term "environments" be unclear, please keep on reading. Otherwise:

## TL;DR usage
```
# Run "plan"
./proteus [environment] plan

# Validate output

# Run "apply"
./proteus [environment] apply
```

Check the `example` context and its demo module in `contexts/example`.

## Contexts and Environments
Environments and contexts define a scope for Terraform configuration. While contexts are defined by creating a directory in the contexts directory,
environments are defined using a Terraform variables file in the `environments` directory of a context.

### State
Any tuple of the form (context, environment) has its own state. No state will be shared between tuples.
That means: (default, production) will not have any shared resources with (default, staging). Neither will (foo, production) share any state with
(bar, production.)

### Conventions
* Valid environment names are are [snake case](https://en.wikipedia.org/wiki/Snake_case) and lowercase.
* files in `environments` need to comply with the following format: `terraform.environment_name.tfvars`

Once an environment gets defined using the above conventions, `proteus` will pick it up as a scope for its subcommands.

**Note:** You do not need to touch any code for the environment to be available in the command line interface.

## Modules
There are two types of modules: Standard Terraform modules and modules that are managed by `proteus`.
Each module without `proteus` configuration behaves as a standard module.

### Conventions
* Module names are [snake case](https://en.wikipedia.org/wiki/Snake_case) and lowercase. `foo_bar` is a correct module name while `FooBar` and `Foo_Bar` are both invalid names.
* Input and output variables go inside of a file called `io.tf` within the root of the module
* Group resources in separate files in the root of the module: Route53 related resources should be described in a file called `route53.tf`; IAM
specific resources go in a file called `iam.tf`. This way resource declarations are easy to find.
* Be verbose: We're not using MS-DOS FAT here. There is no need to shorten resource names.

**Note:** Use the generators provided by `proteus` for creating a scaffolding for contexts, modules and environments.

### Standard modules
Standard modules can be implemented exactly as described in the [Terraform documentation](https://www.terraform.io/docs/modules/index.html).
They need to be included in a Terraform manifest in the root of a context. `proteus` will not use these modules for generating any code.

#### Structure
```
modules/route53
├── io.tf       #  Definition of input and output variables
└── route53.tf  #  route53 resources
```

### Managed modules
Managed modules extend the functionality of standard modules with a YAML configuration format, validators and templates.

#### Conventions
* Standard module conventions apply
* Singular (that means non-repeated resources) go into Terraform manifests in `config/global_resources`. Manifests in this directory
can be either standard Terraform manifests or ERB templates
* YAML Configuration files have to named exactly as an existing environment (with `.yaml` suffix)
* Template names are snake case (lowercase)
* The validator is located in the module's config root and named `validator.rb`

**Note: If your module does not contain a configuration file for your environment, it will be ignored.**

#### Structure
```
modules/rds
├── config                            # proteus confguration directory
│   ├── README.md
│   ├── global_resources              # resources which only get applied once
│   │   ├── parameter_groups.tf
│   │   ├── rds.tf
│   │   └── vpc.tf
│   ├── production_ap.yaml            # data for environment production_ap
│   ├── production_eu.yaml            # data for environment production_eu
│   ├── production_us.yaml            # ...
│   ├── qa.yaml                       # ...
│   ├── staging.yaml                  # ...
│   ├── templates
│   │   ├── _parameter_group.tf.erb   # partial template for parameter groups
│   │   ├── _route53.tf.erb           # partial template for route53 configuration
│   │   ├── defaults
│   │   │   └── parameter_group.yaml  # default data for paramater group partial
│   │   └── rds.tf.erb                # main template of the module
│   └── validator.rb                  # Class ensuring correct format of data
├── io.tf                             # Definition of input and output variables
└── rds.tf                            # rds resources of the module
```

#### Configuration format and templates
Configuration is implemented in YAML files in the root of the `config` directory modules.
The configuration format has only one required key: `template_data`.

*Example:*
```
global_resources:
  # refers to module_name/config/global_resources/your_global_resource_template.tf.erb
  your_global_resource_template:
    key0: value0
    key1: value1
template_data:
  # refers to module_name/config/templates/your_template.tf.erb
  your_template:
    foo: bar
    hue:
      - hue
      - hue
      - hue
```
Each key in `template_data` refers to a template name. Each key in a template section of the `template_data`
Hash is available as an instance variable in the corresponding ERB template.

For the above example:
The template file is `your_template.tf.erb`. In the template `@foo` is available as a String value and
`@hue` is available as an Array.
The same gets applied to the global resource template `your_global_resource_template.tf.erb`: `@key0` and `@key1` are available
as instance variables within the corresponding template.

#### Partial templates
In addition to standard templates which are used to render collections as a whole, modules support templates which can be used
on single records within collections. This comes in handy if data related to a single record has to be rendered as it keeps
templates short and YAML configuration logically structured.

An example use case for this is RDS hosts and Route 53 records where a single database can have multiple Route 53 records.

Consider the following configuration data for an RDS host within the RDS module:
```
template_data:
  rds:
    instances:
      - instance_identifier: "dashboard"
        instance_class: "db.m4.xlarge"
        engine_version: "9.6.5"
        engine: "postgres"
        allocated_storage: 500

        partials:
          route53:
            - app: "dashboard"
              countries:
                - "au"
                - "bd"
                - "bn"
                - "hk"
                - "kr"
                - "my"
                - "ph"
                - "pk"
                - "th"
                - "tw"
```
For this configuration, a template called `rds.tf.erb` will be loaded. Within the template all data within the scope of the key `rds` will
be available as instance variables. That means, data within in `instances` will be present in the template as `@instances`.

When iterating over the instances in the main template, one can trigger rendering of a partial in the context of the current instance
if data for an existing partial template is present.
In the above example, the configuration for the instance with the identifier "dashboard" refers to a partial template called `route53` and defines some
data within the scope of the key `route53`.

The partial template can be rendered in the main template as follows:
```
<% @instances.each do |instance| %>
  module "rds-<%= instance['instance_identifier'] %>" {
    source = "./modules/rds"
    ...
    instance_identifier = "<%= instance['instance_identifier'] %>"
  }

  # Render partial "_route53.tf.erb" if data is present
  # within partials => route53
  <%= render_partial(name: :route53, data: instance, force_rendering: false) %>
<% end %>
```
**Note:** The parameter `force_rendering` defines whether or not the partial will be rendered regardless of data being present or absent. The parameter
defaults to `true`.

**Partial default values**

If the data for a partial template is a Hash, defaults can be loaded from a YAML file in the `templates/defaults` directory.
All of the default values will be injected into the partial template, respecting the values set in the main YAML configuration.
Thus, the values in the main configuration act as overrides to the defaults.

For further information about how partial defaults work, please refer to the `example` module. You can render the module and check its
output by running the following command:

`./proteus context example demo_env render && cat contexts/example/demo_module.tf`


### Default values
Each of the modules in this repository contains a file called `io.tf` which defines the input and output variables of the module.
For input variables, default values can be defined. These defaults can be overridden using the YAML configuration.
The following example is based on the `elasticache` module:

The module defines a variable named `node_type` in its `io.tf` manifest:
```
variable "node_type" {
  default = "cache.t2.micro"
}

```
The configuration for the `staging` environment sets an override as follows:
```
...
  elasticache:
    instances:
      - replication_group_id: sidekiq
        node_type: cache.m3.medium # override for node_type
        engine: "redis"
        engine_version: "3.2.4"
        availability_zones:
          - eu-west-1a
        number_cache_clusters: 1
...
```

Inside of the template `elasticache.tf.erb`, the method `render_defaults` gets called:
```
  ...
  engine = "<%= instance['engine'] %>"
  engine_version = "<%= instance['engine_version'] %>"

  <%= render_defaults(instance) %>
  environment = "${var.environment}"

  vpc_id      = "${module.vpc.id}"
  ...

```
`render_defaults` internally checks if the given context (in this case the data for an ElastiCache instance) defines
overrides for defaults defined in `io.tf` and, if overrides are present, renders them into the template.


#### Validators
The `proteus` library provides a simple DSL for validating module configuration. The DSL is available for validator classes.

#### Validator classes
The following conventions apply for validator classes:
* contained in `validator.rb` in config root of the respective module
* Class name: module name in [upper camel case](https://en.wikipedia.org/wiki/Camel_case)
* Validators inherit from `Proteus::Validators::BaseValidator`
* Validators override (and implement) exactly one method: `validate`

#### Validation DSL
The DSL provides the following keywords:

| Keyword                                     | Description |
| -------------                               |-------------|
| `within(key) { block }`                     | Ensures presence of `key` and data below `key`                  |
| `ensure_unique_values`                      | Ensures unique values in collections                            |
| `ensure_data_type(type)`                    | Checks if the current context is of type `type`                 |
| `ensure_uniqueness_across(key)`             | Ensures uniqueness across a hierarchy                           |
| `each_key { block }`                        | Iterates over keys in the current context                       |
| `ensure_keys(*keys)`                        | Checks for presence of all provided keys in the current context |
| `each { block }`                            | Iterates over elements of a collection                          |
| `ensure_presence(key)`                      | Checks if `key` is present in the current context               |
| `ensure_value(key, options)`                | Ensures a value is in a set of predefined values or range or matches a regular expression |
| `in_case(key, has_value: [...]) { block }`  | Optionally executes `block` if the value of `key` is in `has_value` |

Here's an example for data and the corresponding validator:

**Data:**
```yaml
  template_data:
    my_template:
      countries:
        country_a:
          apps:
            - foo
            - bar
            - baz
        country_b:
          apps:
            - foo
            - bar
            - baz
```

**Validator method:**
```ruby

def validate
  within :template_data do          # fails if template_data is absent

    ensure_data_type Hash           # fails is template_data is not a Hash

    within :my_template do          # fails if my_template is absent

      ensure_data_type Hash         # fails if my_template is not a Hash

      within: countries do          # fails if countries is absent
        each_key do                 # iterates over countries
          within :apps do           # fails if any country is missing the apps key
            ensure_data_type Array  # fails if apps is not an Array
            ensure_unique_values    # fails if apps has duplicate values
          end
        end
      end
    end
  end
end

```

## Generators
TBD

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## To be done
* Tests
* Code documentation (YARD)
* Enforcing validators?
* Rubocop

## License
Copyright (c) 2019 [Delivery Hero SE](https://www.deliveryhero.com/). Proteus is free software, and may be redistributed under the terms specificed in the [license](LICENSE).
