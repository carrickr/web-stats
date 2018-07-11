# README

## Dependencies

1. Ruby, developed with `2.4.1`
1. Postgres, ideally installed and launched via homebrew (if not you may need to edit `database.yml`)

## Setup

1. Clone the project from github and `cd` into it
1. `bundle install`
1. `rails db:create`
1. `rails db:migrate`
1. `rails db:seed` if you wish to load one million randomly generated records

## Running the Project

1. You can start just the rails portion via `bundle exec rails s` or `bundle exec rails c`
1. To start Rails and the React components run `foreman start -f Procfile.dev`

## API Routes

There are two routes to get the json required by the exercise.  These are intended for use by any applications that might query this Rails App

1. `/api/v1/sites/top_urls.json` will return Report 1
1. `/api/v1/sites/top_referrers.json` will return Report 2

## React Routes

The requested reports in a more human readable form are at:

1. `/top_urls` for Report 1
1. `/top_referrers` for Report 2

## Testing

1. Create the test database via `rails db:test:prepare`
1. Run the tests via `bundle exec rspec`
