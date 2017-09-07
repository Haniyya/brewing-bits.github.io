---
layout: post
title:  "Off the Rails! Part 1."
date:   2017-09-06 05:16:01 -0100
categories: blog
tags: ['ruby', 'rails', 'grape', 'programming']
published: true
comments: true
excerpted: |
  Although I still like rails, I always enjoyed to be free from the opinions of
  this opinionated framework...

# Does not change and does not remove 'script' variables
script: [post.js]
---

* Do not remove this line (it will not be displayed)
{: toc}

## Intro

After about 4-5 years of working with [Ruby on
Rails][ruby_on_rails]{:target="_blank"}, I actually still like it. I think the
ecosystem is great, the overall design is well suited to its requirements and I
think the team has a good idea of where the project should be headed
(ActionCable and Api-Mode of Rails 5 are showing that the project is not trying
to compete with the myriads of javascript frameworks out there).

But every once in a while I regret that I have become so stuck in my ways that I
could not write a simple ruby web app, without rails giving me
guidance. So I thought, why not try something new and write a JSON-Api,
completely without rails.

## Requirements

For now we don't have a lot of requirements. We'll be building everyones
favorite: A digital library of books. So what we need for now is:

1. Routing
1. Params handling
1. JSON rendering

Some things I'll save for later posts:

1. Database Persistence
1. Independent business logic
1. Authentication
1. Authorization
1. Some kind of gui
1. tests

## What will be used

It could be interesting to restrict yourself to nothing but the `STDlib`, but I
don't think this would be practical. So instead I will shamelessly exploit this
chance to try out a few gems that have caught my eye for a while now:

1. [Grape][grape] is a JSON-API framework for ruby. It is similar to rails in
   that it is pretty opinionated, but it does not dictate a rigid structure and
   (in this example), will only be responsible for routing and handling params.
1. [Rack][rack-interface] for getting a basic server running.

This list might very well be expanded in the future, but for now it should
fulfill our humble requirements.

## Come along for the ride!

If you want to follow along, I'll push all the code to [Brewing Bits
github][brewing_github], where you can follow [commit by commit][commits].

## Starting real simple

To see what we could do if we didn't even use Grape, and to get into a habit of
developing iteratively, we will first implement the most basic JSON-API we can.

{% highlight ruby tabsize=4 %}
{% remote_file_content https://raw.githubusercontent.com/BrewingBits/off-the-rails/40d7cf9a5fee9ea0d54e2dadf045cf6ebcf9a52a/config.ru %}
{% endhighlight %}

Now we can start our server using `rackup`:
```bash
$ cd the-folder-where-the-config-file-is/
$ rackup
Puma starting in single mode...
* Version 3.10.0 (ruby 2.3.3-p222), codename: Russell's Teapot
* Min threads: 0, max threads: 16
* Environment: development
* Listening on tcp://localhost:9292
Use Ctrl-C to stop
```
And we can see whether it works or not using `curl`:
```bash
$ curl http://localhost:9292
{"message"=>"Hello, world!"}

```
So what did we just do here? We implemented the
["Rack-interface"][rack-interface] by creating an
object that responds to `#call(env)` and returns an array of `[status, headers,
body]`. "But wait!" you say. Where do we actually pass `env`? We don't have to
when using a `proc`. This is a neat little aspect of `Procs`:

> For procs created using lambda or ->() an error is generated if the wrong number of parameters are passed to the proc. For procs created using Proc.new or Kernel.proc, extra parameters are silently discarded and missing parameters are set to nil.

As per the [docs][ruby-docs].

## Starting with grape

So now we have a working API! But it is a pretty boring one. And since I wanted
to show off Grape, we'll quickly replace our `Proc` with something a little more
sophisticated.
Since we don't have any real dependency management yet, make sure to
```bash
$ gem install grape
```
And then replace your proc with the most basic grape-API:

{% highlight ruby tabsize=4 %}
# config.ru
{% remote_file_content https://raw.githubusercontent.com/BrewingBits/off-the-rails/b4186e7eec2325ab2c9e06c090ed782f3e024a64/config.ru %}
{% endhighlight %}

This primitive little thing already emulates the Proc we used above. A fact we
can test by just repeating the same `curl` line from above.
To see how easy it is to add params using grape, well add the ability to greet
someone personally.

{% highlight ruby tabsize=4 %}
# config.ru
{% remote_file_content https://raw.githubusercontent.com/BrewingBits/off-the-rails/dd79ed6b3d08e75946c546e52c96374605bb875f/config.ru %}
{% endhighlight %}

We added a route param called `name`, that we then interpolate into the message.
We can access all params through the `params` object, whether they are part of
the route or not.
So now we restart our server and get out `curl`:
```bash
$ curl http://localhost:9292/paul
{"message" => "Hello, paul!"}
```
Alright. So we can define routes and parse params. Whats next? Maybe we should
see if we can't POST something to the server. How about a book. And while we are
at it, we should start extracting our logic from `config.ru`.

{% highlight ruby tabsize=4 %}
# api.rb
{% remote_file_content https://raw.githubusercontent.com/BrewingBits/off-the-rails/8de40cd8b5ff2f44df3b9b5bbae0bb68d3901919/api.rb %}
{% endhighlight %}

Here we will use `config.ru` just to load dependencies and then start our
application.

{% highlight ruby tabsize=4 %}
# config.ru
{% remote_file_content https://raw.githubusercontent.com/BrewingBits/off-the-rails/8de40cd8b5ff2f44df3b9b5bbae0bb68d3901919/config.ru %}
{% endhighlight %}

We moved the API to another file and made a few adjustments.
1. We defined a `books` helper to keep track of all the books.
1. We used the `resource` method to define our routes in the `/books` namespace.
1. We added a `POST` route to post a book into our books.
1. We added an index route to see if our POST did anything.
1. We added `format :json` so that grape automatically converts our return
   values to JSON.

So you know the drill: Restart the server and get your `curl` out:
```bash
$  curl --data "title=Lord of the Rings&author=J. R. R. Tolkien" http://localhost:9292/books
[{"author":"J. R. R. Tolkien","title":"Lord of the Rings"}]
$ curl http://localhost:9292/books
{"books":[]}
```

## Global State

So this didn't work. The reason for that is that similar to rails controllers,
instances of `Grape::API` don't persist through multiple requests. So `@books`
is being reset at every request. Which makes a lot of sense if there are
multiple people requesting multiple things. You wouldn't want them all to share
a request environment. One way to get around this, is having an object that
exists independently from the API to handle the data.

{% highlight ruby tabsize=4 %}
# app.rb
{% remote_file_content https://raw.githubusercontent.com/BrewingBits/off-the-rails/27c7d385b14e89b9afdb62ae586ec3a60ddae334/app.rb %}
{% endhighlight %}

Here we have to assign the instance of `MyApp` to a constant so that
1. We can reference it globally
1. It will not get garbage collected after every request.

{% highlight ruby tabsize=4 %}
# config.ru
{% remote_file_content https://raw.githubusercontent.com/BrewingBits/off-the-rails/27c7d385b14e89b9afdb62ae586ec3a60ddae334/config.ru %}
{% endhighlight %}

{% highlight ruby tabsize=4 %}
# api.rb
{% remote_file_content https://raw.githubusercontent.com/BrewingBits/off-the-rails/27c7d385b14e89b9afdb62ae586ec3a60ddae334/api.rb %}
{% endhighlight %}

And with those few lines, we at least have persistence for as long as the server
runs! Neat!
```bash
$  curl --data "title=Lord of the Rings&author=J. R. R. Tolkien" http://localhost:9292/books
[{"author":"J. R. R. Tolkien","title":"Lord of the Rings"}]
$ curl http://localhost:9292/books
{"books":[{"author":"J. R. R. Tolkien","title":"Lord of the Rings"}]}
```

This should be enough for now. Watch out for part 2 where we will add real
database persistence using [`sequel`][sequel].

{% endpost #9D9D9D %}

[ruby_on_rails]: http://rubyonrails.org/
[grape]: https://github.com/ruby-grape/grape
[rake]: https://github.com/ruby/rake
[brewing_github]: https://github.com/BrewingBits
[ruby-docs]: http://ruby-doc.org/core-2.4.1/Proc.html#method-i-call
[rack-interface]: https://rack.github.io/
[commits]: https://github.com/BrewingBits/off-the-rails/commits/master
[sequel]: http://sequel.jeremyevans.net/
