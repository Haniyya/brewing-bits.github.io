---
layout: post
title:  "Off the Rails! Part 2."
date:   2017-09-15 05:16:01 -0100
categories: blog
tags: ['ruby', 'rails', 'grape', 'programming', 'sequel', 'postgres', 'sqlite']
published: true
comments: true
excerpted: |
  After implementing our basic API in Part 1, we now add a database
  and the rake tasks to manage it.

# Does not change and does not remove 'script' variables
script: [post.js]
---

Hail hydra! This is Part 2 in a multiple part series where we try to emancipate
ourselves from Ruby on Rails by going back to basics! If you missed Part 1 where
we implemented our API, you can just click [here][part_1].

As always (in this series at least) you can come along for the ride by having a
look at the [git repository][brewing_github]. Just clone the repo and checkout
the `part2` tag.

* Do not remove this line (it will not be displayed)
{: toc}

## Intro

So [last time][part_1] we built ourselves a little Grape based API that can save
and return books (as long as you don't restart the server). This time around
we'll get a little more sophisticated by bringing some structure to our
application, adding [Bundler][bundler], [Rake][rake] and, most importantly, a
way to persist our books using [Sequel][sequel] and a postgres database.

## Adding Bundler

Since we are going to have more than two dependencies (`rack` and `grape`), we
can use the chance to use `bundler`. Our ruby-dependency-manager of choice.
So our project is only a two steps away from its own dependency-manager:

1. Install bundler itself `gem install bundler`
2. `cd` into your projects directory and run `bundle init`

You should now see a new file in your directory called `Gemfile`. Here we can
first put the gems used last time around:

{% highlight ruby tabsize=4 %}
# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'grape'
gem 'rack'
{% endhighlight %}

When we now execute `bundle install`, our dependencies will be installed and a
new file `Gemfile.lock` pops up, which tracks the versions of those gems at time
of install.

## Simplest Sequel

To keep it simple, we'll start with an in-memory `Sqlite` database for our
application. This way we won't have real persistence beyond a server restart,
but we can setup `Sequel` and replace the connection with our postgres-db later.
So first, let's add `sequel` and `sqlite3` to our `Gemfile`.

{% highlight ruby tabsize=4 %}
# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'grape'
gem 'rack'
gem 'sequel'
gem 'sqlite3'
{% endhighlight %}

**Note** You might have to [install sqlite3 first][install_sqlite3].

Now that the dependencies are sorted, we can should have a look at our
application again:

{% highlight ruby tabsize=4 %}
# application.rb

class MyApp
  def books
    @books ||= []
  end
end

Application = MyApp.new
{% endhighlight %}

Our simple `@books` array may have been enough so far, but we want to take
advantage of our new database-based-powers. To do that, we'll first have to have
a database. So let's get real fancy and add a new `lib/initializers/` folder with our
`database.rb` in it:
{% highlight ruby tabsize=4 %}
# lib/initializers/database.rb

DB = Sequel.sqlite

DB.create_table?(:books) do
  primary_key :id
  String :title
  String :author
end
{% endhighlight %}
If you're coming from rails, you've just added your first `db/schema.rb`!
Congratulations! The code above is rather simple:
1. `DB = Sequel.sqlite` creates a new in-memory `Sqlite3` database and
   (following sequels best practices) assigns it to the `DB` constant.
2. `DB.create_table?(:books)` creates a table called `books`. The `?` indicates
   that the table will only be created if there is not already a table named
   `books`. This is not really necessary as long as the database does not live
   longer than the server, but in future this will avoid some errors.
3. `primary_key :id`, adds a auto-incrementing `primary_key` called `id` to our
   table.
4. `String :title` and `String :author` add two fields to our table called
   `title` and `author` which are both just strings. Interestingly, sequel
   breaks a common convention in ruby by defining methods with capitalized
   names. This makes it seem like you are just mentioning a constant, but you
   are actually calling a method on whatever sequel passes the `create_table?`
   block to. You can observe a similar behaviour with rubys own `Hash()` and
   `Array()` methods.

Now you have a neat little `DB` all for yourself to fill up with `book`-records.

## Getting an interface to the database

Although we now could just access `DB` from anywhere in our application, we
should apply some encapsulation by adding a class that handles our database
access. This will keep things nicely separated in case we ever need to change
`DB`.
Lets call these interfaces (we might need more in the future) `interfaces` and
put them in our `/lib` folder.
```bash
mkdir lib/repositories
touch lib/repositories/book_repository.rb
```
Now we can add our interface into this file.
{% highlight ruby tabsize=4 %}
# lib/repositories/book_repository.rb

{% remote_file_content https://raw.githubusercontent.com/BrewingBits/off-the-rails/master/lib/repositories/book_repository.rb %}
{% endhighlight %}

Since the repository doesn't really need state right now, we'll just add the
functionalities as class methods. A few things need to be explained here:
1. We added `Forwardable` because we expect to delegate a lot of messages to
1. Our `data_set`. You can think of the `data_set` as our `books`-table in the
   database. You can access all your table using `DB[:"#{table_name}"]` but
   since we only have one, that'll do for now.
1. We return our `BookRepository` to be compatible with our earlier
   implementation where we returned the `@books` variable after adding a new
   book. We also alias `<<` and `insert` for the same reason.
1. Since Grape will call `to_json` on everything we return in a block, we want
   the `to_json` method to return something useful. Like all books.

**Note**: For some reason, I had to add a `(*_)` to the `to_json` definition to
silently swallow all arguments given to it. It seams that grape passes some
argument to `to_json` when rendering `{books: books}` in the api.

## Connecting all the bits

Now we have a database and an interface to use it. But it's not being loaded
anywhere (life without rails autoload is hard I know). So let's change that in
our `app.rb`.

{% highlight ruby tabsize=4 %}
# app.rb

require 'forwardable'

require 'sqlite3'
require 'sequel'

require_relative 'lib/initializers/db'
require_relative 'lib/repositories/book_repository'

class MyApp
  def books
    @books ||= BookRepository
  end
end

Application = MyApp.new
{% endhighlight %}

I decided to `require` all relevant dependencies for the application in `app.rb`
while all the stuff for grape is being required in `api.rb`.

Alright! We switched out our primitive `Array` with our highly advanced and
super sophisticated `BookRepository`. It sounds much more professional.

## Adding Postgres

The app works, has a real `SQL` database, and feels super fancy. But a big thing
we want to learn in this part, is dealing with all the busywork of using
a database, without the help of rails.
Instead of using our in-memory sqlite3-database (or switching to a persisting
sqlite3 database because thats cheating), we'll add the great and mighty
`postgres` to our stack. And to make things easier on our fingertips, we'll add
`dotenv` as well. But more of that later.

**Note**: If you have not [installed postgres][postgres_install], now would be a good time to do so. You'll also need a user who can at least create a new database. So [do that as well][user_setup].

Just switch out `sqlite3` with the nicely terse `pg` and add `dotenv` to your
`Gemfile`.

{% highlight ruby tabsize=4 %}
# Gemfile

# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'dotenv'
gem 'grape'
gem 'pg'
gem 'rack'
gem 'sequel'
{% endhighlight %}

## Managing the database

Now we could just create a database using postgres ourselves, or we anticipate
that we are going to have to create and drop this database a lot, and just write
ourselves some `rake` tasks to handle that. Again if you, like me, have mostly
developed rails applications, you've probably run into the fine young tasks over
at `rake db:` which are always nice enough to `create drop` and `seed` your
database for you. 

Even though we are intentionally avoiding rails paradigms in this series, we
don't have to live like savages. Therefore we will build our own `rake db:create
db:drop db:setup`.
So add `rake` to your `Gemfile` and 'touch your `Rakefile`'. Only your
`Rakefile`. It's not that exciting.
```bash
touch Rakefile
```
Now you can run `bundle exec rake` and it does nothing! Yey!

### The basic tasks

When you installed `postgres`, you probably installed the utilities that come
with it. The one that we're interested in is `createdb` (you can check if you
have it using `which createdb`). Since we're lazy, we'll just use `createdb` to
do all the work for us!

{% highlight ruby tabsize=4 %}
namespace :db do
  desc 'Creates a new database based on the variables in .env'
  task :create do
    puts 'Creating database...'
    # Here we make sure to give feedback if the creation was successful
    puts `createdb && echo 'Created db'`
  end
end
{% endhighlight %}

**Note**: Those are back ticks around the `createdb` command.
While we're at it, we can add a `rake db:drop` as well:

{% highlight ruby tabsize=4 %}
namespace :db do
  desc 'Creates a new database based on the variables in .env'
  task :create do
    puts 'Creating database...'
    # Here we make sure to give feedback if the creation was successful
    puts `createdb && echo 'Created db'`
  end

  desc 'Drops the database specified in the variables in .env'
  task :drop do
    puts 'Dropping database...'
    # Here we make sure to give feedback if the dropping was successful
    puts `dropdb && echo 'Dropped db'`
  end
end
{% endhighlight %}

Now this won't work because `createdb` and `dropdb` need arguments to work.
But how do we get those arguments into our rake-task? If you guessed through
rakes argument system, you guessed wrong. Because that's tedious and hard on our
fingertips.
Instead we'll use environment variables!

### Using dotenv

`createdb` and `dropdb` are great for scripting since both use [environment
variables][create_db_variables] (if you name them correctly). So you could just run your
task like so:
```bash
PGDATABASE=mydb PGPASS=12345 PGUSER=dau ... rake db:create
```
And everything would be fine. But again, we are lazy: We will not type in
environment variables like some no good street urchin on every rake task good
sir!

Instead we'll write it into a file where we can read them from again and again.
If you've not heard of `dotenv`, heres what it does:
It loads all variables you define in a `.env` file into the environment. Simple as
that. It's a good idea not to start with the `.env` itself, but rather add a
`.env.sample` file first that looks like this:
```bash
PGUSER=
PGPASS=
PGDATABASE=
PGHOST=
PGPORT=
```
Just leave the values blank. This file will be added to version control since
there is nothing in it we want to hide.

**Note**: If you are using `git` on your project, be sure to add `.env` to you
`.gitignore` so you don't accidentally add sensitive data to version control.

Now you can
```bash
cp .env.sample .env
```
and fill in the blanks! If you want postgres to use a default value, just don't
write anything (so PGHOST and PGPORT stay default for example). The things you
should fill out (for a smooth development experience) are PGUSER, PGPASS and
PGDATABASE. If you have all of these filled out (with correct info of course),
your rake tasks won't bug you with password or user prompts.

"But wait!" you shout, excitedly. "Rake won't load these variables on its own!
How can it know about them!" And you're right. Our `Rakefile` is still missing something.

{% highlight ruby tabsize=4 %}
desc 'Loads our .env into ENV'
task :environment do
  puts 'Loading environment...'
  require 'dotenv/load'
end

namespace :db do
  desc 'Creates a new database based on the variables in .env'
  task :create => :environment do
    puts 'Creating database...'
    # Here we make sure to give feedback if the creation was successful
    puts `createdb && echo 'Created db'`
  end

  desc 'Drops the database specified in the variables in .env'
  task :drop => :environment do
    puts 'Dropping database...'
    # Here we make sure to give feedback if the dropping was successful
    puts `dropdb && echo 'Dropped db'`
  end

  # Here we just invoke both tasks, one after the other
  desc 'Resets our database by dropping and creating it again.'
  task :reset => :environment do
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
  end
end
{% endhighlight %}

Now the `:environment` task requires `dotenv/load`, which loads the environment
variables. The `:create => :environment` line says that `:environment` has to be
invoked before `:create` can be invoked. This way we make sure the variables are
loaded and `postgres` can access them.

The `:reset` task is supposed to ape `rake db:reset` we know and love from
rails. It just drops the database and creates it again.

### Switching to pg

Now we can just
```bash
rake db:create
```

and we have our database. But the application is still trying to use a sqlite
database. So we'll quickly change the connection details in
`lib/initializers/database.rb`:

{% highlight ruby tabsize=4 %}
DB = Sequel.connect("postgres://#{ENV['PGHOST']}/#{ENV['PGDATABASE']}?user=#{ENV['PGUSER']}&password=#{ENV['PGPASS']}")

DB.create_table?(:books) do
  primary_key :id
  String :title
  String :author
end
{% endhighlight %}

It's ugly I admit, but it works and shows you exactly what is going on.

## Conclusion

There you have it. You have your own little db-setup. And you did it all by
yourself! No rails involved. You can try the whole thing out by starting your
server using `rackup`, posting some books to it using `curl` (you can check
[part 1][part_1] again to see how exactly that works), restarting the server and
visiting `http://localhost:9292/books` to see that your books were persisted.

And we didn't have to change anything about our `api.rb`. Thats the power of
encapsulation, kids!

## Next time

A few things are still missing from our API:
1. Business Logic
1. Authentication
1. Authorization
1. Probably something someone will mention in the comments

So I don't know what we'll tackle next, but stay tuned!

{% endpost #9D9D9D %}

[part_1]: {{site.base_url}}{% post_url /_blog/2017-04-12-off-the-rails %}
[brewing_github]: https://github.com/BrewingBits/off-the-rails
[postgres_install]: https://www.postgresql.org/docs/9.2/static/tutorial-install.html
[user_setup]: https://www.postgresql.org/docs/9.1/static/app-createuser.html
[create_db]: https://www.postgresql.org/docs/9.2/static/tutorial-createdb.html
[grape]: https://github.com/ruby-grape/grape
[bundler]: https://bundler.io
[rake]: https://github.com/ruby/rake
[create_db_variables]: https://www.postgresql.org/docs/9.1/static/app-createdb.html
