# resources_controller

[![CI](https://github.com/ianwhite/resources_controller/actions/workflows/ci.yml/badge.svg)](https://github.com/ianwhite/resources_controller/actions/workflows/ci.yml)

is a plugin to facilitate inheritance and DRYness in your resources controllers.  It introduces some abstraction to help
you override the default RESTful functionality in a clean and simple manner.

The gem name is *rc_rails*

Add this to your Gemfile

```ruby
gem 'rc_rails'
```

## Requirements

Version 5.0.0 and later require Rails >= 8.0 and Ruby >= 3.3.

## Rails 5 version

Version 3.x of this gem is compatible with Rails 5.x

## Resources

**Documentation and How-to**: http://www.rubydoc.info/github/ianwhite/resources_controller/master/ResourcesController

**Github** for code: http://github.com/ianwhite/resources_controller

**Google group** for questions: http://groups.google.com/group/resources_controller

**RailsConfEurope** presentation files: http://en.oreilly.com/railseurope2008/public/schedule/detail/3536

## for rails 2.x

use the rails2 branch: http://github.com/ianwhite/resources_controller/tree/rails2

## How to contribute

If you have found a bug, or have a new feature, then spec'd code is great.

To get set up for development, do the following:

```sh
git clone https://github.com/ianwhite/resources_controller.git
cd resources_controller
bundle install
bundle exec rspec
```

The specs are run against Rails 8.0 and 8.1 on GitHub Actions.  To run them against a
particular Rails version locally, set RAILS_VERSION:

```sh
RAILS_VERSION='~> 8.0.0' bundle install && bundle exec rspec
```

## Contributors

The following people have made contributions to resources_controller.  Please let me know if I've missed you out.

* Lewis Marshall
* Josh Goebel
* Andrew Bloomgarden
* Chris Hapgood
* Jason Lee
* Richard Hooker
* Matt Mower
* Inviz
* Dan Kubb
* Rein Henrichs
* Tom Stuart
* Joel Chippindale
* Tim Pope
* Tom ten Thij
* Sergei Serdyuk
* Robert Thau

## License

Copyright (c) 2007-2009 Ian White, MIT License
