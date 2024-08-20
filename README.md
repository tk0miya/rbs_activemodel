# rbs_activemodel

rbs_activemodel is a RBS generator for activemodel gem.

## Installation

Add a new entry to your Gemfile and run `bundle install`:

   group :deveopment do
     gem 'rbs_activemodel', require: false
   end

After the installation, please run run rake task generator:

    bundle exec rails g rbs_activemodel:install

## Usage

Run `rbs:activemodel:setup` task:

    bundle exec rake rbs:activemodel:setup

Then rbs_activemodel will scan your source code and generate RBS files into
`sig/activemodel` directory.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also
run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

To release a new version, update the version number in `version.rb`, and then put
a git tag (ex. `git tag v1.0.0`) and push it to the GitHub. Then GitHub Actions
will release a new package to [rubygems.org](https://rubygems.org) automatically.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tk0miya/rbs_activemodel.
This project is intended to be a safe, welcoming space for collaboration, and contributors are
expected to adhere to the [code of conduct](https://github.com/tk0miya/rbs_activemodel/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RbsActivemodel project's codebases, issue trackers is expected to
follow the [code of conduct](https://github.com/tk0miya/rbs_activemodel/blob/main/CODE_OF_CONDUCT.md).
